# Class: cve20113872
#
#   This class provides a convenient way to migrate a Puppet Agent
#   from one CA to a new CA.
#
# Parameters:
#
#  There are no class parameters, but the following facts are required:
#  
#
# Actions:
#
#   * Do nothing if the agent posses a certificate issued by the
#     CA configured on the puppet master.  (The CA we're migrating to)
#   * Move ssldir to ssldir.previous
#   * Put known good localcacert and hostcrl files in place.
#   * Restart Puppet to generate a new CSR
#
# Requires:
#
#   * stdlib version 2.1.1
#
# Sample Usage:
#
#     node default {
#       include cve20113872
#     }
#
class cve20113872 {
  $module = "cve20113872"

  Exec { path => "/bin:/usr/bin:/sbin:/usr/sbin" }
  File {
    require => Exec["CVE-2011-3872 step1"],
    owner   => 'pe-puppet',
    group   => 'root',
    mode    => '0644',
  }

  validate_re($agent_cert_on_disk_issuer, "^/CN=")
  # FIXME We need to determine the currently configured CN of the CA of this master
  # For testing, assume it is '/CN=Puppet CA: puppetmaster.new'
  if ($agent_cert_on_disk_issuer != '/CN=Puppet CA: puppetmaster.new') {
    # FIXME: We need a fact for the SSL directory
    exec { "CVE-2011-3872 step1":
      command => 'mv /etc/puppetlabs/puppet/ssl /etc/puppetlabs/puppet/ssl.previous',
      creates => '/etc/puppetlabs/puppet/ssl.previous',
    }
    file { "/etc/puppetlabs/puppet/ssl":
      ensure => directory,
      mode   => '0771'
    }
    file { "/etc/puppetlabs/puppet/ssl/certs":
      ensure => directory,
      mode   => '0755'
    }
    # Configure the agent to trust the old and the new CA.
    # FIXME: We need a fact for the localcacert of the agent.
    file { "CVE-2011-3872 ca.pem":
      path    => "/etc/puppetlabs/puppet/ssl/certs/ca.pem",
      content => file('/etc/puppetlabs/puppet/ssl/certs/ca_bundle.pem'),
    }
    # Configure the agent to trust the old and the new CA CRL.
    # FIXME: We need a fact for the hostcrl of the agent.
    file { "CVE-2011-3872 crl.pem":
      path    => "/etc/puppetlabs/puppet/ssl/crl.pem",
      content => file("/etc/puppetlabs/puppet/ssl/crl_bundle.pem"),
    }
    # FIXME: Send a HUP single to the agent if it's running.
  }
}

