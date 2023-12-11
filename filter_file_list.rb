require 'csv'
require 'json'
require 'optparse'

option = {
    key: [],
}
option_parser = OptionParser.new do |op|
    op.banner = "Usage: #{$0} [options] [csv file...]"
    op.on('-k KEY', '--key', 'search key') do |v|
        option[:key] << v.intern
    end
    op.on('-o PATH', '--output', 'output file path for digests') do |v|
        option[:output] = v
    end
end
option_parser.parse!(ARGV)
option[:key] << :sha256 if option[:key].empty?

exit(0) if ARGV.empty?

table = CSV.table(ARGV.shift)
ARGV.each do |csv_path|
    CSV.table(csv_path).each do |row|
        table << row
    end
end

duplicate_files = table
    .group_by{|row| option[:key].size == 1 ? row[option[:key][0]] : option[:key].map{|key| row[key]}}
    .select{|sha256, rows| rows.size >= 2}

writer = option[:output].nil? ? $stdout : File.open(option[:output], 'w')
writer << CSV::Table.new(duplicate_files.values.flatten(1)).to_csv
writer.close unless option[:output].nil?
