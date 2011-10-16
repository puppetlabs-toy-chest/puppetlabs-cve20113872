require 'spec_helper'
require 'facter/agent_cert'

describe 'Certificate Facts' do
  subject { Facter::AgentCert }
  it { should respond_to :add_file_facts }

  context "When running inside of Puppet" do
    let(:puppet_hostcert) { Puppet[:hostcert] = "/etc/puppet/ssh/agent.pem" }

    before :all do
      @mock_cert = Facter::AgentCert::Mock.new.certs.first
    end

    it "should ask Puppet for the agent cert path" do
      Facter::Util::PuppetCertificate.expects(:read_file).with(puppet_hostcert).returns(@mock_cert)
      subject.add_file_facts
    end

    context "Facter values for the puppet configuration" do
      it "should set the agent_certname fact" do
        Facter.value('agent_certname').should == Puppet[:certname]
      end
    end

    context "Facter values for the on-disk certificate" do
      before :each do
        Facter::Util::PuppetCertificate.stubs(:read_file).with(puppet_hostcert).returns(@mock_cert)
        subject.add_file_facts
      end
      it "should set a agent_cert_on_disk_basicconstraints fact" do
        Facter.value('agent_cert_on_disk_basicconstraints').should == "CA:FALSE"
      end
      it "should set a agent_cert_on_disk_extendedkeyusage fact" do
        Facter.value('agent_cert_on_disk_extendedkeyusage').should == "TLS Web Server Authentication, TLS Web Client Authentication, E-mail Protection"
      end
      it "should set a agent_cert_on_disk_issuer fact" do
        Facter.value('agent_cert_on_disk_issuer').should == "/CN=Puppet CA: puppet"
      end
      it "should set a agent_cert_on_disk_subject fact" do
        Facter.value('agent_cert_on_disk_subject').should == "/CN=pe-centos5.26.agent1"
      end
      it "should set a agent_cert_on_disk_keyusage fact" do
        Facter.value('agent_cert_on_disk_keyusage').should == "Digital Signature, Key Encipherment"
      end
      it "should set a agent_cert_on_disk_not_after fact" do
        Facter.value('agent_cert_on_disk_not_after').should == "Wed Oct 05 21:11:32 UTC 2016"
      end
      it "should set a agent_cert_on_disk_not_before fact" do
        Facter.value('agent_cert_on_disk_not_before').should == "Fri Oct 07 21:11:32 UTC 2011"
      end
      it "should set a agent_cert_on_disk_nscomment fact" do
        Facter.value('agent_cert_on_disk_nscomment').should == "Puppet Ruby/OpenSSL Generated Certificate"
      end
      it "should set a agent_cert_on_disk_path fact" do
        Facter.value('agent_cert_on_disk_path').should == puppet_hostcert
      end
      it "should set a agent_cert_on_disk_serial fact" do
        Facter.value('agent_cert_on_disk_serial').should == "3"
      end
      it "should set a agent_cert_on_disk_subjectaltname fact" do
        Facter.value('agent_cert_on_disk_subjectaltname').should == "DNS:vulnerable, DNS:puppet, DNS:pe-centos5.26.agent1"
      end
      it "should set a agent_cert_on_disk_subjectkeyidentifier fact" do
        Facter.value('agent_cert_on_disk_subjectkeyidentifier').should == "B0:3E:E0:9D:F6:F5:FC:5C:40:7E:C4:96:35:91:6B:8F:C4:15:3A:11"
      end
    end
  end
end

module Facter
  class AgentCert
    class Mock
      attr_reader :certs

      def initialize
        @certs = Array.new
        @certs << <<-'EOCERT'
-----BEGIN CERTIFICATE-----
MIIChzCCAfCgAwIBAgIBAzANBgkqhkiG9w0BAQUFADAcMRowGAYDVQQDDBFQdXBw
ZXQgQ0E6IHB1cHBldDAeFw0xMTEwMDcyMTExMzJaFw0xNjEwMDUyMTExMzJaMB8x
HTAbBgNVBAMMFHBlLWNlbnRvczUuMjYuYWdlbnQxMIGfMA0GCSqGSIb3DQEBAQUA
A4GNADCBiQKBgQDAYQQ2GY3JDWLk/6WlEJ8WecWNDYwONC+BMDcwwcGYsUFJpHrC
CT6IBLvnO8m6HIxLuFTkUgmPlZ/LXWD4uU4RzII6lcawyX3gp7nOsWFz2xBeRXmr
BcXrn815avHCiKLy/T1Ma8JXA/GEW2bMtM59gBfQhUC+1q43/ODWt1DapwIDAQAB
o4HVMIHSMDgGCWCGSAGG+EIBDQQrFilQdXBwZXQgUnVieS9PcGVuU1NMIEdlbmVy
YXRlZCBDZXJ0aWZpY2F0ZTAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBSwPuCd9vX8
XEB+xJY1kWuPxBU6ETALBgNVHQ8EBAMCBaAwJwYDVR0lBCAwHgYIKwYBBQUHAwEG
CCsGAQUFBwMCBggrBgEFBQcDBDAzBgNVHREELDAqggp2dWxuZXJhYmxlggZwdXBw
ZXSCFHBlLWNlbnRvczUuMjYuYWdlbnQxMA0GCSqGSIb3DQEBBQUAA4GBAFq1TqVV
eJ1g1bpcTZx1rTkP67V4825gYjIEJK3lT/Dx49sosNUdOCI+jjs2dvQo2c7xqBrY
4mVjxyTVJILZvmizJSIoNKs1AWGbpagAu1d9g/s8auKfHWAYg4tSRp120a1aSwjZ
Dm7WULaCl2jefOSrzBqi7Tp1POtpBiZozhe4
-----END CERTIFICATE-----
        EOCERT
      end
    end
  end
end
