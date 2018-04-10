# frozen_string_literal: true

RSpec.describe Puppet::Rest do
  it 'has a version number' do
    expect(Puppet::Rest::VERSION).not_to be nil
  end
end
