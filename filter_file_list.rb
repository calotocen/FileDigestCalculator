require 'csv'
require 'json'
require 'optparse'
require_relative 'filter.rb'

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

filters = option[:filter].map {|filter| Filter::generate(filter)}
input_rows = ARGV
    .map {|csv_path| CSV.open(csv_path, converters: :all, headers: true).to_a}
    .flatten(1)
filtered_rows = CSV::Table.new(input_rows)
    .group_by {|row| option[:group_by].map {|column_name| row[column_name]}}
    .values
    .map {|rows| filters.inject(rows) {|filtered_rows, filter| filter.call(filtered_rows)}}
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
