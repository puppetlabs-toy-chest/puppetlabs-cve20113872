require 'facter/util/with_puppet'

# This fact's value will only be available when running with facter --puppet
# Or when loaded inside of Puppet.  Otherwise, it will be nil
# 'true' if the dns_name exists in /var/opt/lib/pe-puppet/cve20113872/
# (PE) This file is written in step 1 of the cve20113872 migration
# module.  'false' otherwise.  This provides the three states we need.
# Absolutely yes (true), absolutely no (false), and we have no idea (nil).
module Facter
  class IsMigrationHost
    # Provides the with_puppet method
    extend Facter::Util::WithPuppet
    def self.add_facts
      with_puppet do
        Facter.add(:is_migration_host) do
          setcode { File.exists? File.join(Puppet[:vardir], "cve20113872", "dns_name") }
        end
      end
    end
  end
end

Facter::IsMigrationHost.add_facts
