# frozen_string_literal: true

module Puppet
  module Rest
    # TBD
    class Client
      def initialize(uri, user_agent, version)
        @http = HTTPClient.new(
          base_url: uri,
          agent_name: nil,
          default_header: {
            'User-Agent': user_agent,
            'X-PUPPET-VERSION': version
          }
        )

        # enable to see traffic on the wire
        # @http.debug_dev = $stderr

        @http.tcp_keepalive = true
        @http.connect_timeout = 10
        @http.receive_timeout = 60 * 60
        @http.request_filter << self

        ssl_config = @http.ssl_config
        ssl_config.clear_cert_store
        ssl_config.verify_mode = OpenSSL::SSL::VERIFY_PEER
        ssl_config.add_trust_ca(
          File.expand_path('~/.puppetlabs/etc/puppet/ssl/certs/ca.pem')
        )
        ssl_config.set_client_cert_file(
          File.expand_path('~/.puppetlabs/etc/puppet/ssl/certs/localhost.pem'),
          File.expand_path('~/.puppetlabs/etc/puppet/ssl/private_keys/localhost.pem')
        )
        ssl_config.add_crl(
          File.expand_path('~/.puppetlabs/etc/puppet/ssl/crl.pem')
        )
      end

      def disconnect
        @http.reset_all
      end

      def find_certificate(name)
        @http.get(
          "puppet-ca/v1/certificate/#{name}",
          query: { environment: 'production' },
          header: { Accept: 'text/plain' }
        )
      end

      def filter_request(req)
        warn "Connecting to #{req.header.request_uri} (#{req.header.request_method})"
      end

      def filter_response(_req, res)
        warn "Done #{res.status} #{res.reason}\n\n"
      end
    end
  end
end
