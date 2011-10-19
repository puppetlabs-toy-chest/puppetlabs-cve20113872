# CVE-2011-3872 Module #

This module provides two main pieces of functionality:

 * Help me get secure
 * Once secure, help me migrate to a new CA

# Quick Start #

This module is designed to be installed from the Forge, but until then:

    cd /tmp
    git clone git@github.com:puppetlabs/puppetlabs-cve20113872.git cve20113872
    cd cve20113872
    rake build
    cd <modulepath>
    puppet-module install /tmp/cve20113872/pkg/puppetlabs-cve20113872-0.0.1.tar.gz

## Install the Module ##

The first step in the remediation process is to install the cve20113872 module
into your Puppet Master module path.  This will likely be /etc/puppet/modules
or /etc/puppetlabs/puppet/modules for Puppet Enterprise.

Note, if the module is not yet on the forge, it may be built from source using
the build task:

    rake build
    cd /etc/puppetlabs/puppet/modules
    puppet-module install /tmp/puppetlabs-cve20113872-0.0.1.tar.gz

During the rest of these instructions, the modulepath where this module has
been installed will be referred to as <modulepath>.

## Step 1: Issue a new SSL cert for the master ##

In order to secure your Puppet infrastructure, all agents need to connect to a
DNS name that has not been listed in the certdnsnames option.  This will be
called the _intermediate dns name_ certificate.  To accomplish this goal, the
Puppet Master needs a new SSL certificate with the intermediate DNS name.

Step 1 helps you generate this new certificate and configure Puppet Enterprise
to use it.

PE Only Scripts.  These are specifically designed to work with PE.  These
scripts will need to be adapted to help FOSS users and customers.

    <modulepath>/cve20113872/bin/pe_step1_secure_the_master

On a Puppet Master, the `pe_step1_secure_the_master` script should be run first.
This script will perform the following actions:

  * Stop the Puppet Master (Apache)
  * Make a backup copy of all the files that will be modified.  This backup
    will be located at `/etc/puppetlabs/cve20113872.orig.tar.gz`
  * Turn off the `certdnsnames` option if it is enabled in puppet.conf.
  * Issue a new SSL cert for the master with the intermediate DNS name.
  * Configure Apache to use the new SSL certificate with the intermediate DNS name.
  * Generate a new CA with a different name from the existing CA.
  * Swap the new CA into place on the Puppet Master.
  * Reconfigure puppet on the master to connect to the intermediate DNS name.
  * Start everything back up.

At the end of step1, existing Puppet Agents should be able to reconnect to the
master as normal:

    puppet agent --test

However, they will not detect a MITM attack unless they use the new DNS name, e.g.

    puppet agent --test --server puppetmaster.intermediate.dns.name

Step 2 helps you with this migration of your agents from the existing DNS name
to the new DNS name.

## Step 2: Migrate Puppet Agents to the new DNS name and CA ##

This step will help you secure your Puppet Infrastructure by reconfiguring all
of your agent nodes to use the new, intermediate DNS name of the puppet master.
In addition, the agents will be issued a new SSL certificate that does not
contain the certdnsnames of the master.

cve20113872 is a fairly clean Puppet Module providing a set of facts and a
small class performs this migration.  The overall strategy is to move the agent
$ssldir out of the way and then put a known good $localcacert and $hostcrl file
in place.  The Agent will then generate a new CSR the next time it connects to
the master.

To enable the module by patching site.pp please run this script:

    <modulepath>/cve20113872/bin/pe_step2_install_remedy_module

This script will make sure the class cve20113872 is included in each node's
catalog in site.pp  Once the module is installed and the class added to all
node catalogs we can easily migrate an agent to the new Certificate Authority:

    puppet agent --test --server puppetmaster.intermediate.dns.name

And sign the certificate request on the master.  This will re-issue a
certificate that does not contain the certdnsnames problem.

    puppet cert sign --all

Finally, run a third time to make sure the new certificate works.

    puppet agent --test --server puppetmaster.intermediate.dns.name

Once all of the agents have been migrated to the new Certificate Authority and
reconfigured to connect to the intermediate dns name, we're ready for the final
step in the migration process.

## Step 3: Final Cut Over to the new CA ##

The final step in the migration process is to replace the master's SSL
certificate with one issued by the new CA.

    <modulepath>/cve20113872/bin/pe_step3_migrate_the_master

This script will reconfigure the Puppet Master to move back from the
intermediate DNS name to the original name.

The fleet will refuse to connect to this new node since the fleet only trusts a
master SSL certificate issued by the Old CA.  To operate with the master again
they need to re-establish their CA bundle:

    root@pe-debian5:~# rm -f "$(puppet agent --configprint hostcrl)"
    root@pe-debian5:~# rm -f "$(puppet agent --configprint localcacert)"

With these two files removed, the agent will re-download them from the master,
thus configuring them to only trust masters with an SSL certificate issued by
the new CA.

    puppet agent --test

EOF
