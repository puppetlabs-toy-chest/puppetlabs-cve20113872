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
        f.each_line { |l| return true if l =~ /^[^#]*certificate_revocation\b/ }
      end
      return false
    end

    def agent_section_in_conf?
      File.open(config) do |f|
        f.each_line { |l| return true if l =~ /^[^#]*\[agent\]/ }
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
          line.gsub!(/^(\s*)([^#]*certificate_revocation)\b(.*?=\s*).*$/) { "#{$1}certificate_revocation = false" }
        end
      elsif agent_section_in_conf?
        filter_config_by_line do |line|
          line.gsub!(/^[^#]*\[agent\].*$/) { "[agent]\n    certificate_revocation = false" }
        end
      else
        # Simply append the [agent] section
        File.open(config, File::WRONLY|File::APPEND|File::CREAT) do |f|
          f.print "[agent]\n  certificate_revocation = false\n"
        end
      end
    end
  end
end

Migration::Config.new.set_certificate_revocation('false')

