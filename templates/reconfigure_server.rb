#! /usr/bin/env ruby
#
# Reconfigure the server setting in puppet.conf

module Migration
  class ConfigServer
    attr_accessor :config

    def initialize(config_file=nil)
      if config_file then
        self.config = config_file
      else
        self.config = File.exists?("/opt/puppet/bin/puppet") ? "/etc/puppetlabs/puppet/puppet.conf" : "/etc/puppet/puppet.conf"
      end
    end

    def server_in_conf?
      File.open(config) do |f|
        f.each_line { |l| return true if l =~ /^\s*server\s*=/ }
      end
      return false
    end

    def agent_section_in_conf?
      File.open(config) do |f|
        f.each_line { |l| return true if l =~ /^\s*\[(agent|puppetd)\]/ }
      end
      return false
    end

    def main_section_in_conf?
      File.open(config) do |f|
        f.each_line { |l| return true if l =~ /^\s*\[main\]/ }
      end
      return false
    end

    # The block is expected to filter the line in place.
    def filter_config_by_line
      File.open(config, 'r+') do |f|
        lines = f.readlines
        lines.each do |line|
          yield line
        end
        f.pos = 0
        f.print lines
        f.truncate(f.pos)
      end
    end

    def set_server(value)
      if server_in_conf?
        filter_config_by_line do |line|
          line.gsub!(/^(\s*)(server)(\s*?=\s*).*$/) { "#{$1}server = #{value}" }
        end
      elsif agent_section_in_conf?
        filter_config_by_line do |line|
          line.gsub!(/^(\s*)\[(agent|puppetd)\].*$/) { "[#{$2}]\n    server = #{value}" }
        end
      elsif main_section_in_conf?
        filter_config_by_line do |line|
          line.gsub!(/^(\s*)\[main\].*$/) { "[main]\n    server = #{value}" }
        end
      else
        # Simply append the [main] section (Support all puppet versions)
        File.open(config, File::WRONLY|File::APPEND|File::CREAT) do |f|
          f.print "[main]\n    server = #{value}\n"
        end
      end
    end
  end
end

raise ArgumentError, "Must pass path to puppet.conf as argument 1" unless File.readable?(ARGV[0] || "")
raise ArgumentError, "Must pass the new server name as argument 2" unless ARGV[1]

Migration::ConfigServer.new(ARGV[0]).set_server(ARGV[1])

