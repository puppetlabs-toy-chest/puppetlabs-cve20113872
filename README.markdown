# CVE-2011-3872 Module #

This module provides three main pieces of functionality:

 * Am I vulnerable?
 * Help me get secure
 * Once secure, help me migrate to a new CA

# Usage Guides #

Please see the detailed usage guides at:

 * [README-detailed.markdown](README-detailed.markdown)
 * [README-manual-ssh.markdown](README-manual-ssh.markdown)

# Quick Start #

Download the tarball of this module and install with the puppet-module command.

    cd /tmp
    wget http://links.puppetlabs.com/puppetlabs-cve20113872-0.0.1.tar.gz
    cd $(puppet master --configprint confdir)/modules
    puppet-module install /tmp/puppetlabs-cve20113872-0.0.1.tar.gz

If you're running an older version of the puppet-module tool, you may need to:

    mv puppetlabs-cve20113872 cve20113872

# Check if you're vulnerable #

A small script is provided to help determine if you're vulnerable or not.  The
script scans all of the certificates the Puppet CA has issued.  If you
regularly clean out your "signed" directory then this script won't be able to
determine if agents possess certificates with subjectAltNames.

To scan:

    cd $(puppet master --configprint confdir)/modules
    ./cve20113872/bin/scan_certs

You should see output similar to this:

    Status as of: 2011-10-23 19:42:26
    
                       Total Certificates Found:      7 *
                         Potentially Vulnerable:      7 (100.0%)
    
    * (Determined by looking at /etc/puppetlabs/puppet/ssl/ca/signed/\*.pem)
    
    Potentially Vulnerable nodes are those who have the subjectAltName extension in
    their certificate.  The --yaml option to this script will provide detailed
    information

This information means that the utility found 7 certificates in $cadir/signed
and all 7 certificates have the subjectAltNames attribute set.  These
certificates might be able to impersonate the Puppet Master and launch and man
in the middle attack.

# Check Progress #

During the remediation process, please use the `check_progress` script to see
the number of nodes in your fleet that have made progress through the
remediation process.

The script produces summary output which looks like:

    Status as of: 2011-10-23 16:57:30
    
                                    Total Nodes:      4 *
                           Step 0 (Has not run):      1 (25.0%)
                            Step 2 (DNS Switch):      1 (25.0%)
                            Step 4 (SSL Switch):      2 (50.0%)
    
     * Total of the nodes active within the last 30 days
    
                         Potentially Vulnerable:      1 (25.0%)
             Risk Mitigated (Issued a new Cert):      1 (25.0%)
                   Risk Mitigated (Pending CSR):      1 (25.0%)
            Risk Mitigated (Using new DNS name):      1 (25.0%)
        --------------------------------------------------------
                      Total of Nodes Remediated:      3 (75.0%)

# Additional Information #

Please see the detailed information in
[README-detailed.markdown](README-detailed.markdown) and instructions about a
generic remediation process using SSH at
[README-manual-ssh.markdown](README-manual-ssh.markdown).

