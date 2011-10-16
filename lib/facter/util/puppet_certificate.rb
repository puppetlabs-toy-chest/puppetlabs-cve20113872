require 'facter'
require 'openssl'

module Facter::Util
  class PuppetCertificateError < StandardError; end

  # This class is responsible for looking at the current Puppet Agent's
  # configured certificate and loading it from disk whenever Facter.value() is
  # called.
  class PuppetCertificate
    attr_reader :certificate_path
    attr_reader :certificate_pem
    attr_reader :certificate
    attr_reader :timestamp
    attr_accessor :fact_pattern

    # file_blk is a required block to dynamically obtain the filename at
    # runtime.  Puppet[:hostcert] Might be changed during the lifetime of an
    # agent daemon
    def initialize(&file_blk)
      @fact_pattern ||= 'agent_cert_on_disk_%s'
      @certificate_path_blk = file_blk
      @reload_count = 0
      @semaphore = Mutex.new
    end

    def reload_count
      @semaphore.synchronize do
        @reload_count
      end
    end

    def get_facts
      facts = {}
      @semaphore.synchronize do
        return facts if not @certificate
        cert_attributes = [ :subject, :issuer, :not_after, :not_before, :serial ]
        # Main attributes of the certificate
        facts = cert_attributes.inject(facts) do |hsh, attribute|
          val = @certificate.send attribute
          hsh[@fact_pattern % attribute] = val.to_s
          hsh
        end
        # Extension attributes of the certificate
        facts = @certificate.extensions.inject(facts) do |hsh, extension|
          name = extension.oid.to_s.downcase
          hsh[@fact_pattern % name] = extension.value
          hsh
        end
        facts[@fact_pattern % 'path'] = @certificate_path
      end
      facts
    end

    # Gives Facter a block for each fact we want to set.  The block
    # will dynamically reload the state of this object instance
    # when Facter flushes its cache.
    def add_facts
      # We need a binding to self because Facter.add does an instance_eval and
      # therfore changes scope on us.
      cert = self
      # This semaphore is here to prevent facts from reloading the certificate
      # while other facts are reading from the certificate in memory.
      fact_reload_semaphore = Mutex.new
      # Define a fact for each certificate attribute we have access to.
      cert.reload.get_facts.keys.each do |key|
        Facter.add(key.to_sym) do
          # Initialze each fact's reload sync counter to the current value of
          # the Certificate reload count.
          fact_value_version = cert.reload_count
          # The result of this block becomes the fact value every time Facts
          # are refreshed.
          setcode do
            begin
              # JJM: This is an attempt to keep all of the values in sync by
              # only calling reload if an individual fact is not up to date
              fact_reload_semaphore.synchronize do
                cert.reload unless cert.reload_count > fact_value_version
                fact_value_version = cert.reload_count
                cert.get_facts[key]
              end
            rescue PuppetCertificateError => detail
              nil
            end
          end
        end
      end
    end

    def reload
      @semaphore.synchronize do
        @reload_count = @reload_count + 1
        # Check if the path to the certificate has changed.
        @certificate_path = @certificate_path_blk.call
        # Note the time we reloaded ourselves.
        @timestamp = Time.now
        begin
          @certificate_pem = self.class.read_file(@certificate_path)
        rescue => detail
          @certificate_pem = nil
          @certificate = nil
          error = PuppetCertificateError.new "Could not reload from certificate #{@certificate_path}: #{detail.class} #{detail}"
          error.set_backtrace detail.backtrace
          raise error
        else
          @certificate = OpenSSL::X509::Certificate.new @certificate_pem
        end
      end
      self
    end

    private

    # This method is here to aid testing.  We can mock this out easily.
    def self.read_file(file)
      # Read at most 64KB of data from the file.
      File.open(file) { |f| f.read(65536) }
    end
  end
end
