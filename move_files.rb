require 'csv'
require 'fileutils'
require 'logger'
require 'optparse'

option = {
    log_file: STDERR,
    log_level: Logger::WARN,
}
option_parser = OptionParser.new do |op|
    op.banner = "Usage: #{$0} [options] [csv file...]"
    op.on('-d DESTINATION', '--destination', 'destination path') do |v|
        option[:destination] = v
    end
    op.on('--log-file PATH', 'output file path for logging') do |v|
        option[:log_file] = v
        option[:log_level] = Logger::DEBUG if option[:log_level].kind_of?(Integer)
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
exit 0 if option[:destination].nil?

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
headers = [*headers, 'move_to'].uniq
logger.debug(%(headers for output file: headers=#{headers}))

io = option[:output].nil? ? IO.open($stdout.fileno, 'wb') : File.open(option[:output], 'wb')
ARGV.each do |csv_path|
    CSV.foreach(csv_path, converters: :all, headers: true) do |row|
        src_path = row['path']
        dst_path = option[:destination].gsub(/{([^:}]+)(?::([^}]+))?}/) do |matched_string|
            key = $1
            parameter = $2
            if row.headers.include?(key)
                item = row[key]
                if item.kind_of?(DateTime)
                    item.strftime(parameter.nil? ? '%F' : parameter)
                else
                    item = item.to_s
                    if parameter == 'basename'
                        File.basename(item)
                    end
                end
            end
        end
        if !File.exist?(dst_path)
            dst_dirpath = File.dirname(dst_path)
            begin
                unless Dir.exist?(dst_dirpath)
                    FileUtils.mkdir_p(dst_dirpath)
                    logger.info(%(create the directory: path="#{dst_dirpath}"))
                end

                FileUtils.move(src_path, dst_path)
                row['move_to'] = dst_path
                logger.info(%(moved the file: src="#{src_path}", dst="#{dst_path}"))
            rescue
                logger.fatal(%(a fatal error occurred: src_path="#{src_path}", dst_path="#{dst_path}", dst_dirpath="#{dst_dirpath}", message="#{$!}"))
                row['move_to'] = f'failed: message="$!"'
            end
        else
            logger.warn(%(The file already exists: path="#{dst_path}"))
            row['move_to'] = f'failed to move the file: dst_path="#{dst_path}", cause="the file already exists"'
        end
        csv_writer << row
    end
end
io.close()
logger.info(%(The script finished))
