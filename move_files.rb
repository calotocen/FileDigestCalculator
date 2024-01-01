require 'csv'
require 'logger'
require 'optparse'
require 'pathname'

logger = Logger.new(STDOUT)
logger.level = Logger::WARN
logger.formatter = ->(severity, datetime, program_name, msg) {
    ['WARN', 'ERROR', 'FATAL'].include?(severity) ? "#{severity}: #{msg}\n" : "#{msg}\n"
}

option = {}
option_parser = OptionParser.new do |op|
    op.banner = "Usage: #{$0} [options] [csv file...]"
    op.on('-d DESTINATION', '--destination', 'destination directory') do |v|
        option[:destination] = v
    end
    op.on('-v', '--verbose', 'print progress') do |v|
        option[:verbose] = v
    end
end
option_parser.parse!(ARGV)
exit 0 if option[:destination].nil?

logger.level = Logger::DEBUG if option[:verbose]

ARGV.each do |csv_path|
    CSV.foreach(csv_path, headers: true) do |row|
        src_path = row['path']
        dst_dirpath = option[:destination]
        begin
            unless Dir.exist?(dst_dirpath)
                Dir.mkdir(dst_dirpath) 
                logger.info("create the directory: path=\"#{dst_dirpath}\"")
            end
            dst_path = Pathname.join(dst_dirpath, Pathname(src_path).basename).to_s
            if File.exist?(dst_path)
                logger.warn("The file already exists: path=\"#{dst_path}\"")
                continue
            end

            FileUtils.move(src_path, dst_path)
            logger.info("moved the file: src=\"#{src_path}\", dst=\"#{dst_path}")
        raise
            logger.fatal("a fatal error occurred: path=\"#{path}\", message=\"#{$!}\"")
            raise
        end
    end
end
