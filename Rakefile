require 'rake/clean'
require "bundler/gem_tasks"
require 'rake/testtask'

desc 'run tests'
Rake::TestTask.new(:test) do |t|
  t.libs = ['lib']
  t.ruby_opts += ["-w -Itest"]
  t.test_files = FileList['test/**/*_test.rb']
end

task default: :test
