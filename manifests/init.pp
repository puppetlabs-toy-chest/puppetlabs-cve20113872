# Class: cve20113872
#
class cve20113872 {
  $module = "cve20113872"

  # The certificate has /CN=Puppet CA: $hostname
  cve20113872_validate_re($agent_cert_on_disk_issuer, "^/CN=")
  # pe-puppet or puppet
  cve20113872_validate_re($agent_user, "puppet")
  # pe-puppet or puppet
  cve20113872_validate_re($agent_group, "puppet")
  # /etc/puppetlabs/puppet/ssl
  cve20113872_validate_re($agent_ssldir, '^/')
  # /etc/puppetlabs/puppet/ssl/certs
  cve20113872_validate_re($agent_certdir, '^/')
  # /etc/puppetlabs/puppet/ssl/certs/ca.pem
  cve20113872_validate_re($agent_localcacert, "^/.*?\.pem$")
  # /etc/puppetlabs/puppet/ssl/crl.pem
  cve20113872_validate_re($agent_hostcrl, "^/.*?\.pem$")
  # /var/run/pe-puppet/agent.pid
  cve20113872_validate_re($agent_pidfile, "^/.*?\.pid$")
  # Certname can be anything, but it can't be empty.
  cve20113872_validate_re($agent_certname, ".")
  # Agents PID to reload it mid-run
  cve20113872_validate_re($agent_pid, '^\d+$')
  # Agents vardir.  We'll put scripts in here.
  cve20113872_validate_re($agent_vardir, '^/')
  # Agents config file (puppet.conf)
  cve20113872_validate_re($agent_config, '^/.*/puppet.conf$')

  Exec { path => "/opt/puppet/bin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/opt/csw/bin" }
  File {
    owner   => "${agent_user}",
    group   => "${agent_group}",
    mode    => '0644'
  }

  file { "${agent_vardir}/${module}":
    ensure => directory,
  }
  file { "${agent_vardir}/${module}/bin":
    ensure => directory,
  }
  # Needed in step2 to secure the agent
  file { "${agent_vardir}/${module}/bin/reconfigure_server.rb":
    ensure  => file,
    mode    => 0755,
    content => template("${module}/reconfigure_server.rb"),
  }
  # Needed for the switch to the new CA
  file { "${agent_vardir}/${module}/bin/disable_revocation.rb":
    ensure  => file,
    mode    => 0755,
    content => template("${module}/disable_revocation.rb"),
  }
}

