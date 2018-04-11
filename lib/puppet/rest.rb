# frozen_string_literal: true

require 'httpclient'

module Puppet
  # TBD
  module Rest
    require_relative 'rest/version'
    require_relative 'rest/client'
    require_relative 'rest/bootstrap'
  end
end
