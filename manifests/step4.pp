# Class: cve20113872::step4
#
#   This class provides a convenient way to migrate a Puppet Agent
#   from one CA to a new CA.
#
# Parameters:
#
#  There are no class parameters, but the facts distributed with this module
#  are required.  Please make sure pluginsync is turned on to distribute them
#  to the agents.
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
#   * pluginsync enabled.  The facts this class requires may not be distributed
#     to the agents if pluginsync is turned off.
#
# Sample Usage:
#
#     node default {
#       include cve20113872::step4
#     }
#
class cve20113872::step4 {
  $module = "cve20113872"

  # The certificate has /CN=Puppet CA: $hostname
  cve20113872_validate_re($agent_cert_on_disk_issuer, '^/CN=')
  # pe-puppet or puppet, but only check for a leading word character
  cve20113872_validate_re($agent_user, '^\w')
  # pe-puppet or puppet, but only check for a leading word character
  cve20113872_validate_re($agent_group, '^\w')
  # /etc/puppetlabs/puppet/ssl
  cve20113872_validate_re($agent_ssldir, '^/')
  # /etc/puppetlabs/puppet/ssl/certs
  cve20113872_validate_re($agent_certdir, '^/')
  # /etc/puppetlabs/puppet/ssl/certs/ca.pem
  cve20113872_validate_re($agent_localcacert, '^/.*?\.pem$')
  # /etc/puppetlabs/puppet/ssl/crl.pem
  cve20113872_validate_re($agent_hostcrl, '^/.*?\.pem$')
  # /var/run/pe-puppet/agent.pid
  cve20113872_validate_re($agent_pidfile, '^/.*?\.pid$')
  # Certname can be anything, but it can't be empty.
  cve20113872_validate_re($agent_certname, ".")
  # Agents PID to reload it mid-run
  cve20113872_validate_re($agent_pid, '^\d+$')
  # Agents vardir.  We'll put scripts in here.
  cve20113872_validate_re($agent_vardir, '^/')
  # Agents config file (puppet.conf)
  cve20113872_validate_re($agent_config, '^/.*/puppet.conf$')

  # Common class is the "main" class
  include "${module}"

  Exec { path => "/opt/puppet/bin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/opt/csw/bin" }
  File {
    require => Exec["CVE-2011-3872 step1"],
    notify  => Exec["CVE-2011-3872 Reload"],
    owner   => "${agent_user}",
    group   => "${agent_group}",
    mode    => '0644'
  }

  $master_ca_cn       = inline_template('<%= Puppet[:ca_name] %>')
  $master_localcacert = inline_template('<%= Puppet[:localcacert] %>')
  $master_hostcrl     = inline_template('<%= Puppet[:hostcrl] %>')
  $master_ssldir      = inline_template('<%= Puppet[:ssldir] %>')

  # NOTE, We have to be REALLY careful not to do this with the puppet master.
  # Otherwise, the agent will replace the CRL and CA bundle being used
  # by the PE Apache server, causing all existing agents with an "old" certificate
  # to be unauthenticated by the master.
  case $is_migration_host {
    "false": {
      case $agent_cert_on_disk_issuer {
        "/CN=${master_ca_cn}": {
          notify { "CVE-2011-3872 Already Migrated":
            message => "This node has already been issued a certificate by CA ${master_ca_cn}.  No migration is necessary.",
          }
        }
        default: {
          notify { "CVE-2011-3872 Migration":
            message => "Migrating ${agent_certname}",
            before  => Exec["CVE-2011-3872 step1"],
          }
          # When we generate the new CA in the step3 script, the existing SSL
          # directory MUST be moved to the path referenced in the creates parameter
          # otherwise the agent on the master will disable the new CA.
          exec { "CVE-2011-3872 step1":
            command => "mv '${agent_ssldir}' '${agent_ssldir}.previous'",
            creates => "${agent_ssldir}.previous",
          }
          file { "${agent_ssldir}":
            ensure => directory,
            mode   => '0771',
          }
          file { "${agent_certdir}":
            ensure => directory,
            mode   => '0755',
          }
          # For security, give the agent the list of CA's it should trust at the same
          # time we cause it to submit a new CSR.  This prevents a third party from
          # Fooling the agent in trusting more CA's than it should.
          # This resource configures the agent to trust ONLY the new CA.
          file { "CVE-2011-3872 Trusted CA Certificates":
            path    => "${agent_localcacert}",
            content => file("${master_ssldir}/ca/ca_crt.pem"),
          }
          file { "CVE-2011-3872 Trusted CA Revocation Lists":
            path    => "${agent_hostcrl}",
            content => file("${master_ssldir}/ca/ca_crl.pem"),
          }
          # Restore the backup of the puppet.conf file if it was created in step2
          exec { "CVE-2011-3872 Restore puppet.conf":
            onlyif  => "sh -c \"test -f '${agent_config}.backup.${module}'\"",
            command => "sh -c \"cp -p '${agent_config}.backup.${module}' '${agent_config}'\"",
            notify  => Exec["CVE-2011-3872 Reload"],
            require => File["${agent_config}.backup.${module}"],
          }
          # Reload the agent.  This is OK to not be idemopotent because we should only
          # add these resources to the catalog if the agent has a certificate issued
          # by an authority the master is not currently using.
          exec { "CVE-2011-3872 Reload":
            command => "kill -HUP ${agent_pid}",
          }
        }
      }
    }
    default: {
      notice("Not applying resources in ${module}::step4 to the migration host.")
    }
  }
}
