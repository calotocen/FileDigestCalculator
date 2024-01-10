require 'csv'
require 'digest'
require 'pathname'
require 'optparse'

option = {}
option_parser = OptionParser.new do |op|
    op.banner = "Usage: #{$0} [options] [path...]"
    op.on('-o PATH', '--output', 'output file path for digests') do |v|
        option[:output] = v
    end
    op.on('-r', '--recursive', 'list all files in directories') do |v|
        option[:recursive] = v
    end
end
option_parser.parse!(ARGV)

csv_options = {
    write_headers: true,
    headers: ['path', 'file_name', 'sha256', 'created_time', 'modified_time', 'access_time', 'change_time'],
}
csv_writer = CSV.new(option[:output].nil? ? $stdout.clone : File.open(option[:output], 'wb'), **csv_options)
write_row = ->(path) do
    file_stat = File.lstat(path)
    begin
        birth_time = file_stat.birthtime
    rescue NotImplementedError
        birth_time = 'N/A'
    end
    csv_writer << [File.expand_path(path),
                   File.basename(path),
                   Digest::SHA256.file(path).hexdigest,
                   birth_time.strftime('%Y-%m-%dT%H:%M:%S%:z'),
                   file_stat.mtime.strftime('%Y-%m-%dT%H:%M:%S%:z'),
                   file_stat.atime.strftime('%Y-%m-%dT%H:%M:%S%:z'),
                   file_stat.ctime.strftime('%Y-%m-%dT%H:%M:%S%:z')]
end
ARGV.each do |root_path|
    if FileTest.file?(root_path)
        write_row.call(root_path)
    elsif FileTest.directory?(root_path) && option[:recursive]
        Pathname(root_path).glob('**/*') do |path|
            write_row.call(path) if FileTest.file?(path)
        end
    end
end
csv_writer.close
