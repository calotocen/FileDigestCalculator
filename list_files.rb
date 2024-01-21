require 'csv'
require 'digest'
require 'logger'
require 'pathname'
require 'optparse'

option = {
    log_file: STDERR,
    log_level: Logger::WARN,
}
option_parser = OptionParser.new do |op|
    op.banner = "Usage: #{$0} [options] [path...]"
    op.on('--log-file PATH', 'output file path for logging') do |v|
        option[:log_file] = v
        option[:log_level] = Logger::DEBUG if option[:log_level].kind_of?(Integer)
    end
    op.on('--log-level LEVEL', /unknown|fatal|error|warn|info|debug/i, 'log level') do |v|
        option[:log_level] = v
    end
    op.on('-o PATH', '--output', 'output file path for a file list') do |v|
        option[:output] = v
    end
    op.on('-r', '--recursive', 'list all files in directories') do |v|
        option[:recursive] = v
    end
end
option_parser.parse!(ARGV)

logger = Logger.new(option[:log_file])
logger.level = option[:log_level]

logger.info(%(The script started: script="#{$0}, options=#{option}, args=#{ARGV}"))
io = option[:output].nil? ? IO.open($stdout.fileno, 'wb') : File.open(option[:output], 'wb')
CSV.instance(io, write_headers: true, headers: %w(path file_name sha256 created_time modified_time access_time change_time)) do |csv_writer|
    ARGV.each do |arg|
        begin
            if File.file?(arg)
                root_path = File.dirname(arg)
                pattern = File.basename(arg)
                logger.debug(%(The specified path is a normal file: path="#{arg}", root_path="#{root_path}", pattern="#{pattern}"))
            elsif File.directory?(arg)
                root_path = arg
                pattern = '**/*'
                logger.debug(%(The specified path is a directory: path="#{arg}", root_path="#{root_path}", pattern="#{pattern}"))
            else
                logger.warn(%(The specified path is skipped because it is not files or directories: path="#{arg}"))
                next
            end
        rescue => exception
            logger.warn(%(An unexpected warning occurred during checking the specified path: path="#{arg}", reason="#{$!}", backtrace=#{exception.backtrace}))
            next
        end
        Pathname(root_path).glob(pattern) do |path|
            file_stat = File.lstat(path)
            begin
                birth_time_as_string = file_stat.birthtime.strftime('%Y-%m-%dT%H:%M:%S%:z')
            rescue NotImplementedError
                birth_time_as_string = 'N/A'
            end
            record = [File.expand_path(path),
                      File.basename(path),
                      Digest::SHA256.file(path).hexdigest,
                      birth_time_as_string,
                      file_stat.mtime.strftime('%Y-%m-%dT%H:%M:%S%:z'),
                      file_stat.atime.strftime('%Y-%m-%dT%H:%M:%S%:z'),
                      file_stat.ctime.strftime('%Y-%m-%dT%H:%M:%S%:z')]
            csv_writer << record
            logger.debug(%(The file was found: record=#{record}))
        end
    end
end
io.close()
logger.info(%(The script finished))
