# frozen_string_literal: true

# Bundler Audit

require 'bundler/audit/task'
Bundler::Audit::Task.new

# Bundler Gem Build

require 'bundler'
require 'bundler/gem_tasks'

begin
Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
warn e.message
warn 'Run `bundle install` to install missing gems'
exit e.status_code
end

CLEAN << 'pkg'
CLOBBER << 'Gemfile.lock'
