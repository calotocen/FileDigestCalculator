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

io = option[:output].nil? ? IO.open($stdout.fileno, 'wb') : File.open(option[:output], 'wb')
CSV.instance(io, write_headers: true, headers: %w(path file_name sha256 created_time modified_time access_time change_time)) do |csv_writer|
    ARGV.each do |arg|
        if File.file?(arg)
            root_path = File.dirname(arg)
            pattern = File.basename(arg)
        elsif File.directory?(arg)
            root_path = arg
            pattern = '**/*'
        end
        Pathname(root_path).glob(pattern) do |path|
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
    end
end
io.close()
