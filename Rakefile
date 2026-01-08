# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'bundler/setup'

APP_RAKEFILE = File.expand_path('test/dummy/Rakefile', __dir__)
load 'rails/tasks/engine.rake'

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'

  t.test_files = Dir['test/active_record/**/*_test.rb']
end

task default: :test
