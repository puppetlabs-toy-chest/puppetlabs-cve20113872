# This is an autogenerated function, ported from the original legacy version.
# It /should work/ as is, but will not have all the benefits of the modern
# function API. You should see the function docs to learn how to add function
# signatures for type safety and to document this function using puppet-strings.
#
# https://puppet.com/docs/puppet/latest/custom_functions_ruby.html
#
# ---- original file header ----
require 'fileutils'
require 'yaml'

# ---- original file header ----
#
# @summary
#       This function is used to write state information to persistent storage for
#    an individual node working its way through the remediation process.
#
#    This function expects the node cert name as the first argument and the step
#    it has reached as the second argument, and finally a message to write to
#    the state file which will be shown in the detailed progress report.
#
#        cve20113872_store_progress($agent_certname, "step2", "OK")
#
#
#
Puppet::Functions.create_function(:'cve20113872_store_progress') do
  # @param args
  #   The original array of arguments. Port this to individually managed params
  #   to get the full benefit of the modern function API.
  #
  # @return [Data type]
  #   Describe what the function returns here
  #
  dispatch :default_impl do
    # Call the method named 'default_impl' when this is matched
    # Port this to match individual params for better type safety
    repeated_param 'Any', :args
  end


  def default_impl(*args)
    
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