# Class: cve20113872::step2
#
#   This class reconfigures the Puppet Agent to use an intermediate DNS name to
#   contact the Puppet Master.  This name will not be one of the
#   alternate names erroneously issued to all agents as described in
#   CVE-2011-3872.
#
#   Once an agent successfully applies this class, it will not be vulnerable to
#   a man in the middle impersonation of the puppet master.
#
# Parameters:
#
#  There are no class parameters, but the facts distributed with this module
#  are required.  Please make sure pluginsync is turned on to distribute them
#  to the agents.
#
# Actions:
#
#   * Reconfigure puppet.conf to contact the master on the intermediate DNS name.
#   * Send a HUP signal to the agent to reload itself.
#
# Requires:
#
# Sample Usage:
#
class cve20113872::step2 {
  $module = "cve20113872"

  # pe-puppet or puppet, but only check for a leading word character
  cve20113872_validate_re($agent_user, '^\w')
  # pe-puppet or puppet, but only check for a leading word character
  cve20113872_validate_re($agent_group, '^\w')
  # Agents vardir.  We'll put scripts in here.
  cve20113872_validate_re($agent_vardir, '^/')
  # Agent config file
  cve20113872_validate_re($agent_config, '^/')
  # Agent config file
  cve20113872_validate_re($agent_config, '^/')
  # Agent certname
  cve20113872_validate_re($agent_certname, '.')

  # Common class is the "main" class
  include "${module}"

  Exec { path => "/opt/puppet/bin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/opt/csw/bin" }
  File {
    owner   => "${agent_user}",
    group   => "${agent_group}",
    mode    => '0644'
  }

  # We need to figure out the intermediate DNS name.  This should have been
  # written in step1 to persistent storage in the puppet confdir.
  $dns_name_file = inline_template("<%= File.join(Puppet[:vardir], '${module}', 'dns_name') %>")
  $dns_name = inline_template("<%= File.read('${dns_name_file}').chomp rescue '' %>")
  if $dns_name == "" {
    fail("Error: could not read DNS name from file: ${dns_name_file} (This should have been set in step1)")
  }
  # Make a backup of the original puppet.conf to restore in step4
  file { "${agent_config}.backup.${module}":
    replace => false,
    source  => "${agent_config}",
    before  => Exec["CVE-2011-3872 Use Intermediate DNS Name"],
  }
  exec { "CVE-2011-3872 Use Intermediate DNS Name":
    command => "${agent_vardir}/${module}/bin/reconfigure_server.rb '${agent_config}' '${dns_name}'",
    onlyif  => "sh -c '[ -f ${agent_vardir}/${module}/step2_complete ] && exit 1 || exit 0'",
    unless  => "sh -c \"puppet agent --configprint server | grep '^${dns_name}\$'\"",
    require => File["${agent_vardir}/${module}/bin/reconfigure_server.rb"],
  }
  file { "CVE_2011-3872 Step2 Semaphore":
    path    => "${agent_vardir}/${module}/step2_complete",
    ensure  => file,
    require => Exec["CVE-2011-3872 Use Intermediate DNS Name"],
  }
  # The step 2 reload exec resource is here to resubmit facts to provide up to
  # date status information.
  # Instead of reloading the agent to resubmit facts which may cause undue
  # stress on a Puppet Master infrastructure doing catalog runs twice in a run
  # interval, we're going to write status information from the compiler phase
  # itself.
  # exec { "CVE-2011-3872 Step2 Reload":
  #   command     => "kill -HUP ${agent_pid}",
  #   refreshonly => true,
  # }

  # Store state information
  cve20113872_store_progress($agent_certname, "2", "OK: Agent configured to connect to ${dns_name}")
}
