# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

group(:test) do
  gem 'rubocop', '~> 0.50', require: false
  gem 'simplecov', require: false
end

gemspec

local_gemfile = File.join(__dir__, 'Gemfile.local')
if File.exist? local_gemfile
  eval_gemfile local_gemfile
end
