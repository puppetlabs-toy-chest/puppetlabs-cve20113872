require 'date'
require 'pathname'

unless ARGV.length > 0
  puts "usage: ruby check_progress.rb <fact_yaml_dir>"
  exit 1
end

dir = Pathname.new(ARGV.first)

files = dir.entries.select { |f| f.extname == '.yaml' }

if files.empty?
  puts "#{dir} does not contain any YAML files"
  exit 1
end

Dir.chdir(dir.to_s)

groups = Hash.new { |h,k| h[k] = [] }

files.each do |file|
  yaml = file.read

  yaml =~ /^\s*agent_cert_on_disk_issuer: "?(.+?)"?\s*$/
  issuer = $1 || 'unknown'

  yaml =~ /^\s*!ruby\/sym _timestamp: "?(.+)"?/
  timestamp = $1 || 'unknown'

  # Remove the millisecond, etc bits. We just sub the string because parsing
  # and formatting the time is *phenomenally* slow (adds ~800% to the runtime).
  timestamp.sub!(/\..*/,'')

  name = file.basename('.yaml').to_s

  groups[issuer] << [name, timestamp]
end

name_len = files.map {|f| f.basename('.yaml').to_s.length}.sort.last
iss_len = groups.keys.map {|i| i.length}.sort.last

puts ['Issuer:'.ljust(iss_len), 'Node CN:'.ljust(name_len), 'Timestamp:'].join('    ')

time_format = '%Y-%m-%d %H:%M:%S'

groups.sort.each do |issuer,certs|
  certs.each do |name,timestamp|
    puts [issuer.ljust(iss_len), name.ljust(name_len), timestamp].join('    ')
  end
end

puts "Status as of: #{Time.now.strftime(time_format)}"
