require 'json'
require 'optparse'

option = {}
option_parser = OptionParser.new do |op|
    op.banner = "Usage: #{$0} [options] [json file...]"
    op.on('-v', '--verbose', 'print progress') do |v|
        option[:verbose] = v
    end
end
option_parser.parse!(ARGV)

ARGV.each do |json_path|
    File.open(json_path) do |file_handle|
        input_data = JSON.load(file_handle)
        input_data['duplicate_files'].each do |key, paths|
            paths[1..-1].each do |path|
                begin
                    File.delete(path)
                    puts('delete #{path} ... done') if option[:verbose]
                rescue Errno::ENOENT
                    STDERR.puts("delete #{path} ... warning: #{$!}")
                end
            end
        end
    end
end
