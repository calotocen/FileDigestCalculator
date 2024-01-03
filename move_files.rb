require 'csv'
require 'fileutils'
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
    op.on('-d DESTINATION', '--destination', 'destination path') do |v|
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
        if File.exist?(dst_path)
            logger.warn("The file already exists: path=\"#{dst_path}\"")
            next
        end

        dst_dirpath = File.dirname(dst_path)
        begin
            unless Dir.exist?(dst_dirpath)
                Dir.mkdir(dst_dirpath)
                logger.info("create the directory: path=\"#{dst_dirpath}\"")
            end

            FileUtils.move(src_path, dst_path)
            logger.info("moved the file: src=\"#{src_path}\", dst=\"#{dst_path}")
        rescue
            logger.fatal("a fatal error occurred: src_path=\"#{src_path}\", dst_path=\"#{dst_path}\", dst_dirpath=\"#{dst_dirpath}\", message=\"#{$!}\"")
            raise
        end
    end
end
