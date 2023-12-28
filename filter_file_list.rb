require 'csv'
require 'json'
require 'optparse'

option = {
    group_by: [],
    filter: [],
    sort_by: [],
    column: [],
}
option_parser = OptionParser.new do |op|
    op.banner = "Usage: #{$0} [options] [csv file...]"
    op.on('-g COLUMN_NAME', '--group-by') do |v|
        option[:group_by] << v
    end
    op.on('-f FILTER', '--filter') do |v|
        option[:filter] << v
    end
    op.on('-s COLUMN_NAME', '--sort_by') do |v|
        option[:sort_by] << v
    end
    op.on('-c COLUMN_NAME', '--column') do |v|
        option[:column] << v
    end
    op.on('-o PATH', '--output', 'output file path for digests') do |v|
        option[:output] = v
    end
end
option_parser.parse!(ARGV)

mappers = []
option[:filter].map do |filter|
    mapper_factories = {
        'count' => ->(name, operator, value) {
            # the operator must be reversed to swap the left and right operands.
            method = value.to_i.method(operator.tr('<>', '><').intern)
            ->(rows) {method[rows.length] ? rows : []}
        },
        'index' => ->(name, operator, value) {
            # the operator must be reversed to swap the left and right operands.
            method = value.to_i.method(operator.tr('<>', '><').intern)
            ->(rows) {
                index = -1
                rows.filter {method[index += 1]}
            }
        },
        'path' => ->(name, operator, value) {
            # the operator must be reversed to swap the left and right operands.
            method = eval(value).method(operator.tr('<>', '><').intern)
            ->(rows) {rows.filter {|row| method[row[name]]}}
        },
        'created_time' => ->(name, operator, value) {
            if /^(?<method_name>min|max)\((?<parameters>[[:print:]]+)\)$/ =~ value
                ->(rows) {
                    return [] if rows.empty?
                    # the operator must be reversed to swap the left and right operands.
                    method = rows.map{|row| row[parameters]}.method(method_name)[].method(operator.tr('<>', '><').intern)
                    rows.filter {|row| method[row[name]]}
                }
            else
                ->(rows) {
                    # the operator must be reversed to swap the left and right operands.
                    method = DateTime.parse(value).method(operator.tr('<>', '><').intern)
                    rows.filter {|row| method[row[name]]}
                }
            end
        },
        'modified_time' => ->(name, operator, value) {
            return mapper_factories['created_time'][name, operator, value]
        },
        'access_time' => ->(name, operator, value) {
            return mapper_factories['created_time'][name, operator, value]
        },
        'change_time' => ->(name, operator, value) {
            return mapper_factories['created_time'][name, operator, value]
        },
    }
    # Ruby cannot assign matched strings to local variables by (?<>) when patterns contain expression expansion by #{}.
    unless m = /^(#{mapper_factories.keys.join('|')})\s*(?:(==|!=|<=?|>=?|=~|!~)\s*(.*))?$/.match(filter)
        raise ArgumentError.new("wrong filter: filter='#{filter}'")
    end
    mappers << mapper_factories[m[1]][m[1], m[2], m[3]]
end

input_rows = ARGV
    .map {|csv_path| CSV.open(csv_path, converters: :all, headers: true).to_a}
    .flatten(1)
filtered_rows = CSV::Table.new(input_rows)
    .group_by {|row| option[:group_by].map {|column_name| row[column_name]}}
    .values
    .map {|rows| mappers.inject(rows) {|mapped_rows, mapper| mapper[mapped_rows]}}
    .flatten(1)
unless option[:sort_by].empty?
    sequential_number_for_stable_sort = 0
    filtered_rows.sort_by! do |row|
        option[:sort_by]
            .map {|column_name| row[column_name]}
            .append(sequential_number_for_stable_sort += 1)
    end
end
unless option[:column].empty?
    filtered_rows.map! do |row|
        row.delete_if {|header, field| !option[:column].include?(header)}
    end
end

writer = option[:output].nil? ? $stdout : File.open(option[:output], 'w')
writer << CSV::Table.new(filtered_rows).to_csv
writer.close unless option[:output].nil?
