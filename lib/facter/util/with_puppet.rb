module Facter::Util::WithPuppet
  def with_puppet
    # This is in case this fact is running without Puppet loaded
    if Module.constants.include? "Puppet"
      begin
        yield if block_given?
      rescue Facter::Util::PuppetCertificateError => detail
        # To be as un-intrusive (e.g. when running 'facter')  as possible, this
        # doesn't even warn at the moment
        # Facter.warnonce "Could not load facts for #{Puppet[:hostcert]}: #{detail}"
      end
    else
      "Puppet is not loaded.  Didn't do anything... :("
    end
  end
end
