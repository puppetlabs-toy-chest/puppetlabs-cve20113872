require 'fileutils'
require 'yaml'

module Puppet::Parser::Functions
  newfunction(:cve20113872_store_progress, :doc => <<-'ENDHEREDOC') do |args|
    This function is used to write state information to persistent storage for
    an individual node working its way through the remediation process.

    This function expects the node cert name as the first argument and the step
    it has reached as the second argument, and finally a message to write to
    the state file which will be shown in the detailed progress report.

        cve20113872_store_progress($agent_certname, "step2", "OK")

    ENDHEREDOC
    if args.length < 3 then
      raise Puppet::ParseError, ("cve20113872_store_progress(): wrong number of arguments (#{args.length}; must >= 3)")
    end

    (agent_certname, step, message) = args

    # Write the state information to Puppet[:yamldir]/cve20113872
    folder = File.join(Puppet[:yamldir], "cve20113872")
    FileUtils.mkdir_p folder unless File.directory? folder
    progress_file = File.join(folder, "progress_#{agent_certname.downcase}.yaml")

    # Try and grab the issuer of the agent certificate from facter...
    agent_issuer = lookupvar('agent_cert_on_disk_issuer') || 'unknown'

    state = {
      agent_certname => {
        'agent_certname' => agent_certname,
        'step'           => step.to_i,
        'message'        => message,
        'timestamp'      => Time.now,
        'issuer'         => agent_issuer,
      }
    }

    # Write the file.
    File.open(progress_file, "w+", 0644) do |io|
      io.puts state.to_yaml
    end

    # Return the state hash if this function is ever converted to an rvalue
    state
  end
end
