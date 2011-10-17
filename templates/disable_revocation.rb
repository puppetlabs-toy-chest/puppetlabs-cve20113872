#! /usr/bin/env ruby
#
# This script configures a Puppet Agent to not perform Certificate Revocation
# List checks.  This is necessary to allow the agent to operate with both the
# intermediate puppet certificate and the final puppet certificate issued by
# the new CA.

module Migration
  class Config
    attr_accessor :config

    def initialize(config_file=nil)
      if config_file then
        self.config = config_file
      else
        self.config = File.exists?("/opt/puppet/bin/puppet") ? "/etc/puppetlabs/puppet/puppet.conf" : "/etc/puppet/puppet.conf"
      end
    end

    def certificate_revocation_in_conf?
      File.open(config) do |f|
        f.each_line { |l| return true if l =~ /^\s*certificate_revocation\s*=/ }
      end
      return false
    end

    def agent_section_in_conf?
      File.open(config) do |f|
        f.each_line { |l| return true if l =~ /^\s*\[(agent|puppetd)\]/ }
      end
      return false
    end

    def agent_section_in_conf?
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

    def set_certificate_revocation(value='false')
      if certificate_revocation_in_conf?
        filter_config_by_line do |line|
          line.gsub!(/^(\s*)(certificate_revocation)\b(\s*?=\s*).*$/) { "#{$1}certificate_revocation = false" }
        end
      elsif agent_section_in_conf?
        filter_config_by_line do |line|
          line.gsub!(/^(\s*)\[(agent|puppetd)\].*$/) { "[#{$2}]\n    certificate_revocation = false" }
        end
      elsif main_section_in_conf?
        filter_config_by_line do |line|
          line.gsub!(/^(\s*)\[main\].*$/) { "[main]\n    certificate_revocation = false" }
        end
      else
        # Simply append the [main] section (Support all puppet versions)
        File.open(config, File::WRONLY|File::APPEND|File::CREAT) do |f|
          f.print "[main]\n    certificate_revocation = false\n"
        end
      end
    end
  end
end

raise ArgumentError, "Must pass path to puppet.conf as argument 1" unless File.readable?(ARGV[0] || "")

Migration::Config.new(ARGV[0]).set_certificate_revocation('false')

