require 'csv'
require 'optparse'

option = {}
option_parser = OptionParser.new do |op|
    op.banner = "Usage: #{$0} [options] [csv file...]"
    op.on('-v', '--verbose', 'print progress') do |v|
        option[:verbose] = v
    end
end
option_parser.parse!(ARGV)

ARGV.each do |csv_path|
    CSV.foreach(csv_path, headers: true) do |row|
        path = row['path']
        begin
            File.delete(path)
            puts("delete #{path} ... done") if option[:verbose]
        rescue Errno::ENOENT
            STDERR.puts("delete #{path} ... warning: #{$!}")
        end
    end
end
