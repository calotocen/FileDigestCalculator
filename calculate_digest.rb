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
    op.on('-r', '--recursive', 'calculate all files in directories') do |v|
        option[:recursive] = v
    end
end
option_parser.parse!(ARGV)

csv_options = {
    write_headers: true,
    headers: ['path', 'file name', 'sha256'],
}
csv_writer = option[:output].nil? ? CSV.new($stdout, **csv_options) : CSV.open(option[:output], 'wb', **csv_options)
write_row = ->(path) { csv_writer << [File.expand_path(path), File.basename(path), Digest::SHA256.file(path).hexdigest] }
ARGV.each do |root_path|
    if FileTest.file?(root_path)
        write_row.call(root_path)
    elsif FileTest.directory?(root_path) && option[:recursive]
        Dir.glob(Pathname(root_path).join("**/*").to_s) do |path|
            write_row.call(path) if FileTest.file?(path)
        end
    end
end
csv_writer.close unless option[:output].nil?
