# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'

RuboCop::RakeTask.new do |task|
  task.plugins << %w[rubocop-rspec]
end

task default: %i[spec rubocop]
