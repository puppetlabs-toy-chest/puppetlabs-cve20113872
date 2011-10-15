# CVE-2011-3872 Module #

This module provides two main pieces of functionality:

 * Help me get secure
 * Once secure, help me migrate to a new CA

# Quick Start (PE) #

PE Only Scripts.  These are specifically designed to work with PE.  These
scripts will need to be adapted to help FOSS users and customers.

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

