require 'csv'
require 'logger'
require 'optparse'

logger = Logger.new(STDOUT)
logger.level = Logger::WARN
logger.formatter = ->(severity, datetime, program_name, msg) {
    ['WARN', 'ERROR', 'FATAL'].include?(severity) ? "#{severity}: #{msg}\n" : "#{msg}\n"
}

option = {}
option_parser = OptionParser.new do |op|
    op.banner = "Usage: #{$0} [options] [csv file...]"
    op.on('-v', '--verbose', 'print progress') do |v|
        option[:verbose] = v
    end
end
option_parser.parse!(ARGV)

logger.level = Logger::DEBUG if option[:verbose]

ARGV.each do |csv_path|
    CSV.foreach(csv_path, headers: true) do |row|
        path = row['path']
        begin
            File.delete(path)
            logger.info("deleted a file: path=\"#{path}\"")
        rescue Errno::ENOENT
            logger.warn("file not found: path=\"#{path}\"")
        rescue
            logger.fatal("a fatal error occurred: path=\"#{path}\", message=\"#{$!}\"")
            raise
        end
    end
end
