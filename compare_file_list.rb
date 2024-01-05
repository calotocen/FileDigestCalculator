require 'csv'
require 'json'
require 'optparse'

option_parser = OptionParser.new do |op|
    op.banner = "Usage: #{$0} [options] [csv file...]"
    op.on('-o PATH', '--output', 'output file path for digests') do |v|
        option[:output] = v
    end
end
option_parser.parse!(ARGV)

class ComparableRow
    attr_accessor :row
    attr_accessor :index

    def initialize(row, index)
        @row = row
        @index = index
    end

    def eql?(other)
        @row['sha256'] == other.row['sha256']
    end

    def hash()
        @row['sha256'].hash
    end
end

rows_list = ARGV.map {|csv_path| CSV.open(csv_path, converters: :all, headers: true).to_a}
comparable_rows_list = rows_list.map {|rows| rows.map.with_index {|row, index| ComparableRow.new(row, index)}}
left_only_rows = comparable_rows_list[0] - comparable_rows_list[1]
left_only_rows.each {|comparable_row| rows_list[0][comparable_row.index]['comparison_result'] = 'Left only'}
right_only_rows = comparable_rows_list[1] - comparable_rows_list[0]
right_only_rows.each {|comparable_row| rows_list[1][comparable_row.index]['comparison_result'] = 'Right only'}

csv_options = {
    write_headers: true,
    headers: ['path', 'file_name', 'sha256', 'created_time', 'modified_time', 'access_time', 'change_time', 'comparison_result'],
}
csv_writer = option[:output].nil? ? CSV.new($stdout, **csv_options) : CSV.open(option[:output], 'wb', **csv_options)

csv_writer.close unless option[:output].nil?