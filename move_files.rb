require 'csv'
require 'optparse'
require 'pathname'

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

ARGV.each do |csv_path|
    CSV.foreach(csv_path, headers: true) do |row|
        src_path = row['path']
        dst_dirpath = option[:destination]
        unless Dir.exist?(dst_dirpath)
            print("create a directory #{path} ... ") if option[:verbose]
            Dir.mkdir(dst_dirpath) 
            puts('done') if option[:verbose]
        end
        dst_path = Pathname.join(dst_dirpath, Pathname(src_path).basename).to_s
        if File.exist?(dst_path)
            print('')
        end
        continue if File.exist?(dst_path)

        path = row['path']
        FileUtils.move(path, option[:destination])
    end
end
