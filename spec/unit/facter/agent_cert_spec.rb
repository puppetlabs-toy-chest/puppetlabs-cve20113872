require 'spec_helper'
require 'facter/agent_cert'

describe Facter::AgentCert do
  it { should respond_to :add_file_facts }
  it { should respond_to :add_certname_facts }

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

module Facter::AgentCert
  class Mock
    attr_reader :certs

    def initialize
      @certs = Array.new
      @certs << <<-'EOCERT'
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 3 (0x3)
        Signature Algorithm: sha1WithRSAEncryption
        Issuer: CN=Puppet CA: puppet
        Validity
            Not Before: Oct  7 21:11:32 2011 GMT
            Not After : Oct  5 21:11:32 2016 GMT
        Subject: CN=pe-centos5.26.agent1
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (1024 bit)
                Modulus:
                    00:c0:61:04:36:19:8d:c9:0d:62:e4:ff:a5:a5:10:
                    9f:16:79:c5:8d:0d:8c:0e:34:2f:81:30:37:30:c1:
                    c1:98:b1:41:49:a4:7a:c2:09:3e:88:04:bb:e7:3b:
                    c9:ba:1c:8c:4b:b8:54:e4:52:09:8f:95:9f:cb:5d:
                    60:f8:b9:4e:11:cc:82:3a:95:c6:b0:c9:7d:e0:a7:
                    b9:ce:b1:61:73:db:10:5e:45:79:ab:05:c5:eb:9f:
                    cd:79:6a:f1:c2:88:a2:f2:fd:3d:4c:6b:c2:57:03:
                    f1:84:5b:66:cc:b4:ce:7d:80:17:d0:85:40:be:d6:
                    ae:37:fc:e0:d6:b7:50:da:a7
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            Netscape Comment: 
                Puppet Ruby/OpenSSL Generated Certificate
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Subject Key Identifier: 
                B0:3E:E0:9D:F6:F5:FC:5C:40:7E:C4:96:35:91:6B:8F:C4:15:3A:11
            X509v3 Key Usage: 
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage: 
                TLS Web Server Authentication, TLS Web Client Authentication, E-mail Protection
            X509v3 Subject Alternative Name: 
                DNS:vulnerable, DNS:puppet, DNS:pe-centos5.26.agent1
    Signature Algorithm: sha1WithRSAEncryption
        5a:b5:4e:a5:55:78:9d:60:d5:ba:5c:4d:9c:75:ad:39:0f:eb:
        b5:78:f3:6e:60:62:32:04:24:ad:e5:4f:f0:f1:e3:db:28:b0:
        d5:1d:38:22:3e:8e:3b:36:76:f4:28:d9:ce:f1:a8:1a:d8:e2:
        65:63:c7:24:d5:24:82:d9:be:68:b3:25:22:28:34:ab:35:01:
        61:9b:a5:a8:00:bb:57:7d:83:fb:3c:6a:e2:9f:1d:60:18:83:
        8b:52:46:9d:76:d1:ad:5a:4b:08:d9:0e:6e:d6:50:b6:82:97:
        68:de:7c:e4:ab:cc:1a:a2:ed:3a:75:3c:eb:69:06:26:68:ce:
        17:b8
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
