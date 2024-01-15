require 'csv'
require 'logger'
require 'optparse'

option = {
    log_file: STDERR,
    log_level: Logger::WARN,
}
option_parser = OptionParser.new do |op|
    op.banner = "Usage: #{$0} [options] [csv file...]"
    op.on('--log-file PATH', 'output file path for logging') do |v|
        option[:log_file] = v
        option[:log_level] = Logger::DEBUG unless option[:log_level].kind_of?(Integer)
    end
    op.on('--log-level LEVEL', /unknown|fatal|error|warn|info|debug/i, 'log level') do |v|
        option[:log_level] = v
    end
    op.on('-v', '--verbose', 'print progress') do |v|
        option[:verbose] = v
    end
end
option_parser.parse!(ARGV)

logger = Logger.new(option[:log_file])
logger.level = option[:log_level]

logger.info(%(The script started: script="#{$0}, options=#{option}, args=#{ARGV}"))
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
logger.info(%(The script finished))
