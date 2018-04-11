# frozen_string_literal: true

module Puppet
  module Rest
    # TBD
    class Client
      attr_reader :ssl_config

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

        # secure defaults, trusted certs must be explicitly added
        @ssl_config = @http.ssl_config
        @ssl_config.clear_cert_store
        @ssl_config.verify_mode = OpenSSL::SSL::VERIFY_PEER
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

      def save_certificate_signing_request(name, io)
        @http.put(
          "puppet-ca/v1/certificate_request/#{name}",
          query: { environment: 'production' },
          header: {
            'Content-Type': 'text/plain',
            Accept: 'text/plain'
          },
          body: io
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
