require 'csv'
require 'json'
require 'optparse'

option = {
    group_by: [],
    include: [],
    exclude: [],
    sort_by: [],
}
option_parser = OptionParser.new do |op|
    op.banner = "Usage: #{$0} [options] [csv file...]"
    op.on('-g COLUMN_NAME', '--group-by') do |v|
        option[:group_by] << v
    end
    op.on('-i CONDITION', '--include') do |v|
        option[:include] << v
    end
    op.on('-e CONDITION', '--exclude') do |v|
        option[:exclude] << v
    end
    op.on('-s COLUMN_NAME', '--sort_by') do |v|
        option[:sort_by] << v
    end
    op.on('-o PATH', '--output', 'output file path for digests') do |v|
        option[:output] = v
    end
end
option_parser.parse!(ARGV)

input_rows = ARGV.map{|csv_path| CSV.open(csv_path, headers: true).to_a}.flatten(1)
input_file_list = CVA::Table.new(input_file_list)

output_file_list = input_file_list.group_by{|row| option[:group_by].map{|column_name| row[column_name]}}.values
mappers = {
    'count' => ->(rows, expression) {eval("#{rows.length}#{expression}") ? rows : []},
    'path' => ->(rows, regex_pattern) {rows.filter {|row| /#{regex_pattern}/ =~ row[:path]}},
}
[:include, :exclude].each do |option_name|
    option[option_name].each do |condition|
        raise ArgumentError.new("unkonwn filter: condition='#{condition}'") unless /^(?<filter_name>[[:alnum:]]+)(:(?<parameters>.*))?$/ =~ condition
        raise ArgumentError.new("unkonwn filter: filter_name='#{filter_name}', condition='#{condition}'") unless mappers.has_key?(filter_name)
        output_file_list.map! do |rows|
            mapped_rows = mappers[filter_name].call(rows, parameters)
            option_name == :include ? mapped_rows : rows - mapped_rows
        end
    end
end

output_file_list.flatten!(1)
unless option[:sort_by].empty?
    sequential_number_for_stable_sort = 0
    output_file_list.sort_by! {|row| option[:sort_by].map{|column_name| row[column_name]} << (sequential_number_for_stable_sort += 1)}
end
writer = option[:output].nil? ? $stdout : File.open(option[:output], 'w')
writer << CSV::Table.new(output_file_list).to_csv
writer.close unless option[:output].nil?
