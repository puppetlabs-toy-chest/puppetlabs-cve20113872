CVE-2011-3872 Remediation Toolkit Module
========================================

This module will help you permanently protect your site from attacks on CVE-2011-3872 (the AltNames vulnerability). 

## The AltNames vulnerability in brief

Puppet agent identifies the puppet master by comparing the puppet master DNS name it knows with the names in the master's certificate. The master's cert can include both a common name and a set of alternative DNS names. 

Alternative DNS names are an optional feature for master certs, and they have to be specifically enabled with the `certdnsnames` option. **In versions prior to 2.6.12 and 2.7.6, the Puppet CA will improperly insert any `certdnsnames` values into _agent_ certificates as well as master certificates.** 

This means that if the following two conditions are both met:

* Your puppet master has ever had its `certdnsnames` setting turned on during the current CA's lifetime
* Any of your agent nodes are configured to contact the master at a DNS alternative name that has ever been included in the `certdnsnames` setting

...then your site probably contains certificates that can be used to impersonate the puppet master in a man-in-the-middle attack. You should update Puppet and/or deactivate the `certdnsnames` setting, but **existing certificates will remain dangerous even after doing so.** 

This module will help you to make those existing certificates safe.

## How the fix works

Since two conditions must be true for your site to be vulnerable, you can protect yourself by breaking either condition:

* Configuring all agent nodes to reach the master at a new DNS name (which has never been included in a certificate) will prevent them from being spoofed by a rogue agent cert with the old DNS names.
* Migrating all machines to a new CA which has never had `certdnsnames` turned on will permanently disarm any rogue certs, since machines on the new CA will not recognize those certs as valid. 

This module automates _both_ of these tasks. Steps 1 and 2 will secure your site immediately by configuring all agents to use a new DNS name for the puppet master, and will turn off `certdnsnames` if you haven't already. Steps 3 through 5 will provide long-term protection (and let you resume use of your previous DNS names) by migrating all machines to a new CA.

## Choosing your repair plan

You have several options for remediating the AltNames vulnerability.

- If you have a **small-to-moderate number of nodes and can trivially SSH to all of them,** you can protect yourself permanently without using this module --- simply delete the `ssldir` from the master and all agents, re-generate the master's certificate, and sign new agent certificates. **See the README-easy-ssh-fix.markdown file** for step-by-step instructions.
- If mass SSH is impractical but you **don't mind permanently changing the puppet master's DNS name,** you can protect yourself by running only the first two steps of this module. Continue reading for instructions, and stop after step 2.
- If mass SSH is impractical and you **wish to continue using the current DNS name(s),** (or if you just want long-term protection against accidental re-use of the old names) you should run steps 1 through 5 of the remediation module. Continue reading for instructions.

## Remediating the AltNames vulnerability

To remediate your site with this module, you must: 

* Stop adding new nodes
* Create a new temporary DNS entry for the puppet master
* Install the module
* Ensure that your modules will not interfere with the remediation
* Run steps 1 and 2 immediately
* Optionally, run steps 3 through 5 at your earliest convenience

### Stop adding new nodes

You should not add nodes to your Puppet infrastructure during the remediation of this vulnerability, as there is an increased chance of putting new nodes into an "orphaned" state.

### Create a temporary DNS entry for the puppet master

As described above (see "How the fix works"), this module first secures your site by configuring agents to contact the master at a new DNS name. Before it can do this, you must choose a name yourself and edit your site's DNS configuration to make the master reachable at it. Configuring DNS is beyond the scope of this document. 

If your site's change-management policies do not allow timely modification of DNS records, you can use Puppet itself to add a host entry on every agent node. Simply add a host resource like the one below to your site.pp file, and allow every agent to run once.

    host {'puppetmaster.new.domain.com':
      ensure  => present,
      ip      => '172.16.158.132',
      comment => 'Temporary puppet master hostname for remediating CVE-2011-3872'
    }

You may want to log into a subset of agent nodes and ping the new name, to ensure that the DNS or host entry is working properly.

Although we refer to this as a temporary name, you may choose to make it permanent by stopping the remediation after step 2.

### Install the module 

This module must be installed to one of the directories in Puppet's `modulepath` before you can use it. You can discover your `modulepath` by running `puppet master --configprint modulepath`. The main modules directory will usually be `/etc/puppetlabs/puppet/modules` (for Puppet Enterprise) or `/etc/puppet/modules` (for open source Puppet).

To install the module from the Forge using the Puppet module tool, `cd` to your main modules directory and run the following:

    puppet-module install puppetlabs-cve20113872

To install the module from a tarball, simply unarchive it and move it to your modules directory, ensuring that it is named `cve20113872`. (Remove the `puppetlabs-` prefix if present.)

For developers: To install the module from source in a way that mimics the Forge install, run the following: 

    cd <source directory>
    rake build
    cd <modules directory>
    puppet-module install /tmp/puppetlabs-cve20113872-0.0.1.tar.gz

### Avoid interference

This module makes changes to the following files on every puppet agent node: 

* The main puppet.conf configuration file
* The contents of Puppet's `ssldir` (run `puppet agent --configprint ssldir` to display the path)

If you are using Puppet to manage any of these files --- that is, managing Puppet _with_ Puppet --- you **must** add a `noop => true` metaparameter to all such resources until the remediation is complete. After the remediation, you must ensure that your resources won't undo any permanent changes made by this module before turning them back on.

### Step 1

This step:

* Turns off the master's `certdnsnames` setting, if it hasn't already been turned off.
* Issues a new certificate for the puppet master. This certificate will contain all of the previous DNS names for the puppet master, with the addition of a new DNS name of your choice.

This step modifies only the puppet master. You can perform the next step immediately.

#### PE Users

From the top directory of this module, run the following:

    bin/pe_step1_enable_intermediate_dns_name <new DNS name>

#### Other users

TODO

#### Site status after running step 1:

- CA will create dangerous certs? **NO.** (fixed!)
- Agents can be spoofed by agent certs? **YES.** (not fixed)
- Potentially dangerous certs are still valid? **YES.** (not fixed)
- Agents can operate normally and receive catalogs from master? **YES.** (business as usual)

### Step 2

This step: 

* Adds the `cve20113972::step2` class to all agent catalogs. This class:
    * Configures each agent node to contact the puppet master at the new DNS name.

This step modifies agent nodes. **All agent nodes must run once before performing the next step.** 

#### PE Users

From the top directory of this module, run the following:

    bin/pe_step2_configure_agents_for_intermediate_dns_name

#### Other Users

TODO

#### Site status after running step 2:

After every agent node has checked in once:

- CA will create dangerous certs? **NO.** (fixed!)
- Agents can be spoofed by agent certs? **NO.** (fixed!)
- Potentially dangerous certs are still valid? **YES.** (not fixed)
- Agents can operate normally and receive catalogs from master? **YES.** (business as usual)

**Your site is now protected.** However, all of the master's previous DNS names are unsafe to use for the remaining lifetime of the CA. If you are content to leave the puppet master on the new DNS name, you can stop now; otherwise, continue to step 3.

**Schedule steps 3-5 carefully,** as step 4 entails a temporary disruption of service.

**You should not run step 3 until all agents have run once and your full site is protected.**

### Step 3

This step: 

* Generates a new CA certificate.
* Configures Puppet to sign any NEW certificate requests using the new CA.
* Prepares the puppet master to trust agent certificates from both the new and the old CA. 

This step modifies only the puppet master. You can perform the next step immediately.

#### PE Users

From the top directory of this module, run the following:

    bin/pe_step3_generate_new_authority

#### Other Users

TODO

#### Site status after running step 3:

- CA will create dangerous certs? **NO.** (fixed!)
- Agents can be spoofed by agent certs? **NO.** (fixed!)
- Potentially dangerous certs are still valid? **YES.** (not fixed)
- Agents can operate normally and receive catalogs from master? **YES.** (business as usual)

### Step 4

This step:

* Adds the `cve20113972::step2` class to all agent catalogs. This class:
    * Moves the agent's `ssldir` to a backup location.
    * Securely configures the agent to trust the new CA (and _only_ the new CA).
    * Configures the agent to contact the master at its old DNS name
    * Restarts puppet agent.
    * Submits a new certificate signing request.

This step modifies agent nodes. **All agent nodes must run once before performing the next step.** 

#### PE Users

From the top directory of this module, run the following:

    bin/pe_step4_migrate_agents_to_new_authority

#### Other Users

TODO

#### Site status after running step 4:

After every agent node has checked in once:

- CA will create dangerous certs? **NO.** (fixed!)
- Agents can be spoofed by agent certs? **NO.** (fixed!)
- Potentially dangerous certs are still valid? **NO.** (fixed!)
- Agents can operate normally and receive catalogs from master? **NO.** (disruption of service)

**The puppet master's previous DNS names have been rehabilitated,** and are safe to use in the future; accordingly, this step restores the agent's configuration so it will use the previous name.

**Note that agent nodes which have run a step 4 catalog will be unable to retrieve and run their normal catalogs until the end of step 5.**

**You should not run step 5 until all agents have run once.** If you run step 5 too early, any agents who have not run their step 4 catalogs **will be in an "orphaned" state** and must be repaired manually. Use the included status tool <!-- TODO --> to check whether your entire population has been migrated to the new CA. 

Orphaned nodes can be repaired by logging in, moving the `ssldir` to a new location, and restarting puppet agent. Run `puppet agent --configprint ssldir` to locate the `ssldir`.

### Step 5

This step: 

* Cleans out the puppet master's certificate from the old CA.
* Issues the master a certificate signed by the new CA. 
* Configures the master to distrust agent certificates from the old CA.

This step modifies only the puppet master.

#### PE Users

From the top directory of this module, run the following:

    bin/pe_step5_migrate_the_master

#### Other Users

TODO

#### Site status after running step 5:

After every agent node has checked in once:

- CA will create dangerous certs? **NO.** (fixed!)
- Agents can be spoofed by agent certs? **NO.** (fixed!)
- Potentially dangerous certs are still valid? **NO.** (fixed!)
- Agents can operate normally and receive catalogs from master? **YES.** (service has resumed)

This step completes the full remediation. 

**You must still sign any pending certificate signing requests** to reenable normal agent traffic --- if you don't use autosign, you should manually sign these requests with the `puppet cert --list` and `puppet cert --sign` commands. (If you recognize every certname in the list of CSRs and are confident that none were submitted by malicious nodes, you may wish to use `puppet cert --sign --all`.)

