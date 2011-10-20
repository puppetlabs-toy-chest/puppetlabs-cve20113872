This outlines the process for migrating clients to the new SSL infrastructure via SSH.

These commands generally need to be run as root or via sudo.

  1. Stop puppet agents everywhere.
    * Stop service for daemonized agents
    * Disable cron job for non-daemonized agents
  1. Stop puppet master.
  1. Remove ssldir on all agents
    * Find ssldir with: `puppet agent --configprint ssldir`
    * Remove ssldir with: `rm -r /path/to/ssldir`
  1. Remove ssldir on master
    * Find ssldir with: `puppet master --configprint ssldir`
    * Remove ssldir with: `rm -r /path/to/ssldir`
  1. disable certdnsnames on master (if not upgraded)
    * **Remove any certdnsnames line in the master config file.**
  1. set a new `$ca_name` (so you can easily tell rotated certs)
    * This is an arbitrary string
    * Defaults to `Puppet CA: $fqdn-of-CA-machine`
    * Add `ca_name = 'Puppet CA: Created on $fqdn at 2011/10/20'` (need a better suggestion)
  1. Generate new ssl cert and CA on master (with certdnsnames if needed)
    * `puppet cert --generate $(puppet master --configprint certname)`
      *  `puppet cert --generate --certdnsnames 'foo:bar' $(puppet master --configprint certname)`
  1. start master
  1. start agents
  1. sign certs
    * `puppet cert --sign <pending-certificate-request>`
    * `puppet cert --sign --all` (will sign all certificate requests)
