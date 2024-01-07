require 'csv'
require 'json'
require 'optparse'

    option = {}
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
rows_list.flatten(1).each {|row|
row['comparison_result'] = 'Both'
}
comparable_rows_list = rows_list.map {|rows| rows.map.with_index {|row, index| ComparableRow.new(row, index)}}
left_only_rows = comparable_rows_list[0] - comparable_rows_list[1]
left_only_rows.each {|comparable_row| rows_list[0][comparable_row.index]['comparison_result'] = 'Only left'}
right_only_rows = comparable_rows_list[1] - comparable_rows_list[0]
right_only_rows.each {|comparable_row| rows_list[1][comparable_row.index]['comparison_result'] = 'Only right'}

headers = []
headers << rows_list[0][0].headers unless rows_list[0].empty?
headers << rows_list[1][0].headers unless rows_list[0].empty?
headers = headers.uniq

csv_options = {
    write_headers: true,
    headers: headers,
}
csv_writer = option[:output].nil? ? CSV.new($stdout, **csv_options) : CSV.open(option[:output], 'wb', **csv_options)
rows_list.flatten(1).each do |row|
    csv_writer << row.fields
end
csv_writer.close unless option[:output].nil?