require 'facter/util/puppet_certificate'

# The facts this file provides look like:
# agent_cert_on_disk_basicconstraints => CA:FALSE
# agent_cert_on_disk_extendedkeyusage => TLS Web Server Authentication, TLS Web Client Authentication, E-mail Protection
# agent_cert_on_disk_issuer => /CN=Puppet CA: puppet
# agent_cert_on_disk_keyusage => Digital Signature, Key Encipherment
# agent_cert_on_disk_not_after => Wed Oct 05 21:11:32 UTC 2016
# agent_cert_on_disk_not_before => Fri Oct 07 21:11:32 UTC 2011
# agent_cert_on_disk_nscomment => Puppet Ruby/OpenSSL Generated Certificate
# agent_cert_on_disk_path => /etc/puppet/tmp/ssl/certs/pe-centos5.26.agent1.pem
# agent_cert_on_disk_serial => 3
# agent_cert_on_disk_subject => /CN=pe-centos5.26.agent1
# agent_cert_on_disk_subjectaltname => DNS:vulnerable, DNS:puppet, DNS:pe-centos5.26.agent1
# agent_cert_on_disk_subjectkeyidentifier => B0:3E:E0:9D:F6:F5:FC:5C:40:7E:C4:96:35:91:6B:8F:C4:15:3A:11

module Facter
module AgentCert
  def self.with_puppet
    # This is in case this fact is running without Puppet loaded
    if Module.constants.include? "Puppet"
      begin
        yield if block_given?
      rescue Facter::Util::PuppetCertificateError => detail
        # To be as un-intrusive (e.g. when running 'facter')  as possible, this
        # doesn't even warn at the moment
        # Facter.warnonce "Could not load facts for #{Puppet[:hostcert]}: #{detail}"
      end
    else
      "Puppet is not loaded.  Didn't do anything... :("
    end
  end

  def self.add_file_facts
    with_puppet do
      # The block will be evaluated each time the facts are flushed to figure out the certificate file to load.
      crt = Facter::Util::PuppetCertificate.new() { Puppet[:hostcert] }
      crt.add_facts
    end
  end

  def self.add_certname_facts
    with_puppet do
      Facter.add(:agent_certname) do
        setcode { Puppet[:certname] }
      end
    end
  end

  def self.add_memory_facts
    raise NotImplementedError, "REVISIT: Provide facts for certificate in memory"
  end
end
end

Facter::AgentCert.add_file_facts
Facter::AgentCert.add_certname_facts

