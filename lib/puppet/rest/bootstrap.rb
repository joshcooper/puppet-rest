# frozen_string_literal: true

require 'json'
require 'openssl'

module Puppet
  module Rest
    # TBD
    class Bootstrap
      def initialize(ca_path, crl_path, csr_path, certname, cert_path, key_path)
        @ca_path = ca_path
        @crl_path = crl_path
        @csr_path = csr_path
        @certname = certname
        @cert_path = cert_path
        @key_path = key_path
      end

      def bootstrap(client)
        bootstrap_ca_bundle

        client.ssl_config.add_trust_ca(@ca_path)
        puts 'Added CA certs'

        client_cert, private_key = bootstrap_client(client)
        client.ssl_config.client_cert = client_cert
        client.ssl_config.client_key = private_key
        puts "Added client cert for #{client_cert.subject}"

        crls = bootstrap_crl_bundle(client)
        crls.each do |crl|
          client.ssl_config.add_crl(crl)
          puts "Added CRL for #{crl.issuer}"
        end

        puts 'SSL initialized'
        puts
      end

      private

      def bootstrap_ca_bundle
        # Bootstrap CA cert bundle insecurely
        unless File.exist?(@ca_path)
          insecure = Puppet::Rest::Client.new('https://localhost:8140', 'Puppet/6.0.0', '6.0.0')
          begin
            insecure.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
            response = insecure.find_certificate('ca')
            handle_response(response, 'Failed to download CA bundle')

            File.open(@ca_path, 'w', 0644) { |f| f.write(response.body) }
          ensure
            insecure.disconnect
          end
        end
      end

      def bootstrap_client(client)
        submit_csr = true
        until File.exist?(@cert_path)
          # Try to download cert
          response = client.find_certificate(@certname)
          if response.ok?
            File.open(@cert_path, 'w', 0644) { |f| f.write(response.body) }
            break
          end

          if submit_csr
            submit_csr = false

            response = client.save_certificate_signing_request(@certname, File.new(@csr_path))
            handle_response(response, 'Failed to submit CSR')
            # fall through to download cert
          else
            raise 'Exiting; no certificate found and waitforcert is disabled'
          end
        end

        client_cert = ::OpenSSL::X509::Certificate.new(File.read(@cert_path))
        private_key = ::OpenSSL::PKey::RSA.new(File.open(@key_path))

        if client_cert.check_private_key(private_key)
          puts 'Private key matches client certificate'
        else
          raise 'Signed client certificate does not match host private key'
        end

        [client_cert, private_key]
      end

      def bootstrap_crl_bundle(client)
        # puppet requires client certs to download the CRL
        unless File.exist?(@crl_path)
          response = client.find_certificate_revocation_list('ca')
          handle_response(response, 'Failed to download CRL bundle')

          File.open(@crl_path, 'w', 0644) { |f| f.write(response.body) }
        end

        File.readlines(@crl_path, '-----END X509 CRL-----')
            .map(&:strip)
            .reject(&:empty?)
            .uniq
            .map { |entry| OpenSSL::X509::CRL.new(entry) }
      end

      def handle_response(response, message)
        unless response.ok?
          detail = JSON.parse(response.body)['message'] || response.reason
          raise "#{message}: #{detail}"
        end
      end
    end
  end
end
