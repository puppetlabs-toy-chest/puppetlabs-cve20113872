require 'facter/util/with_puppet'

module Facter
  class AgentSettings
    # Get the with_puppet method
    extend Facter::Util::WithPuppet
    def self.add_settings_facts(settings = nil)
      settings ||= [
        :localcacert,
        :hostcrl,
        :certdir,
        :certname,
        :hostcert,
        :hostprivkey,
        :privatekeydir,
        :certificate_revocation,
        :config,
        :confdir,
        :vardir,
        :ssldir,
        :statedir,
        :pidfile,
        :user,
        :group,
      ]
      with_puppet do
        settings.each do |setting|
          Facter.add("agent_#{setting}".to_sym) do
            setcode { Puppet[setting] }
          end
        end
      end
    end
  end
end

Facter::AgentSettings.add_settings_facts
