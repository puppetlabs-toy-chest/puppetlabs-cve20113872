# CVE-2011-3872 Module #

This module provides two main pieces of functionality:

 * Help me get secure
 * Once secure, help me migrate to a new CA

# Quick Start (PE) #

PE Only Scripts.  These are specifically designed to work with PE.  These
scripts will need to be adapted to help FOSS users and customers.

    /vagrant/modules/cve20113872/bin/step1_secure_the_master

On a Puppet Master, the `step1_secure_the_master` script should be run first.
This script will perform the following actions:

  * Stop the Puppet Master (Apache)
  * Issue a new SSL cert for the master with a unique name
  * Issue a new CA with a unique name
  * Swap the new CA into place.
  * Reconfigure fileserver and puppet.conf on the master to use the new name.
  * Start things back up.

At this point, existing Puppet Agent's should be able to reconnect to the master with a simple:

    puppet agent --test --server puppetmaster.new

e.g. the only change to clients is the server configuration setting.

# Migrate an Agent #

Once all of the Agents has been configured to use the new dns name, securing
the fleet, they all need to be migrated to the new Certificate Authority.

A fairly clean Puppet Module providing a set of facts and a small class
performs this migration.  The overall strategy is to move the agent $ssldir out
of the way and then place down a known good $localcacert and $hostcrl file.
The Agent will then generate a new CSR the next time it connects to the master.

    /vagrant/modules/cve20113872/bin/step2_install_remedy_module

This script will install the Puppet Module into
/opt/puppet/share/puppet/modules and make sure it's included in each node's
catalog in site.pp  To migrate an agent simply run:

    puppet agent --test --server puppetmaster.new

Then, run again to generate a new CSR:

    puppet agent --test --server puppetmaster.new

And sign the certificate request on the master.  This will re-issue a
certificate that does not contain the certdnsnames problem.

    puppet cert sign --all

Finally, run a third time to make sure the new certificate works.

    puppet agent --test --server puppetmaster.new

# Final Cut Over #

The final step in the migration process, once all Agents have been issued new
SSL certificates by the new CA, is to replace the master's SSL certificate with
one issued by the new CA.

    /opt/puppet/share/puppet/modules/cve20113872/bin/step3_migrate_the_master

This script will reconfigure the Puppet Master to move back from
"puppetmaster.new" to "puppetmaster"  The SSL certificate for puppetmaster will
contain the certdnsname for puppetmaster.new, but it will be issued by the new,
trustworthy CA.

The fleet will refuse to connect to this new node since the fleet only trusts a
master SSL certificate issued by the Old CA.  To operate with the master again
they need to re-establish their CA bundle:

    root@pe-debian5:~# rm -f "$(puppet agent --configprint hostcrl)"
    root@pe-debian5:~# rm -f "$(puppet agent --configprint localcacert)"

With these two files removed, the agent will re-download them from the master,
thus configuring them to only trust masters with an SSL certificate issued by
the new CA.

    puppet agent --test --server puppetmaster

EOF
