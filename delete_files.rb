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
    op.on('-o PATH', '--output', 'output file path for digests') do |v|
        option[:output] = v
    end
    op.on('-v', '--verbose', 'print progress') do |v|
        option[:verbose] = v
    end
end
option_parser.parse!(ARGV)

logger = Logger.new(option[:log_file])
logger.level = option[:log_level]

logger.info(%(The script started: script="#{$0}, options=#{option}, args=#{ARGV}"))
headers = []
ARGV.each do |csv_path|
    CSV.foreach(csv_path, headers: true) do |row|
        headers += row.headers
        break
    end
end
headers = (headers + ['deleted']).uniq
logger.debug(%(headers for output file: headers=#{headers}))

io = option[:output].nil? ? IO.open($stdout.fileno, 'wb') : File.open(option[:output], 'wb')
CSV.instance(io, write_headers: true, headers: headers) do |csv_writer|
    ARGV.each do |csv_path|
        CSV.foreach(csv_path, headers: true) do |row|
            path = row['path']
            begin
                File.delete(path)
                logger.info(%(deleted a file: path="#{path}"))
                row['deleted'] = 'Deleted'
            rescue Errno::ENOENT
                logger.warn(%(file not found: path="#{path}"))
                row['deleted'] = 'Not found'
            rescue
                logger.warn(%(an error occurred: path="#{path}", message="#{$!}"))
                raise
            end
            csv_writer << row
        end
    end
end
io.close()
logger.info(%(The script finished))
