# frozen_string_literal: true

RSpec.describe Puppet::Rest::Client do
  let(:certname)       { 'bismati' }
  let(:uri)            { 'https://puppet:8140' }
  let(:version)        { '5.3.5' }
  let(:user_agent)     { "Puppet/#{version} Ruby/2.4.3-p205 (x86_64-darwin15)" }
  let(:client)         { described_class.new(uri, user_agent, version) }
  let(:cert)           { fixture('cert.pem') }

  def fixture(name)
    File.read(File.join(__dir__, '../../fixtures', name))
  end

  it 'includes common headers' do
    stub_request(:get, %r{^https://puppet:8140/puppet-ca/v1/certificate/#{certname}})
      .with(
        headers: {
          'User-Agent': user_agent,
          'X-PUPPET-VERSION': version
        }
      )

    client.find_certificate(certname)
  end

  describe '#find_certificate' do
    it "returns a PEM encoded certificate as 'text/plain'" do
      stub_request(:get, %r{^https://puppet:8140/puppet-ca/v1/certificate/#{certname}})
        .with(headers: { Accept: 'text/plain' })
        .to_return(body: cert)

      expect(client.find_certificate(certname).body).to eq(cert)
    end
  end
end
