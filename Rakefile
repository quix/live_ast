require 'rake/clean'
require "bundler/gem_tasks"
require 'rake/testtask'
require 'rdoc/task'

desc 'run tests'
Rake::TestTask.new(:test) do |t|
  t.libs = ['lib']
  t.ruby_opts += ["-w -Itest"]
  t.test_files = FileList['test/**/*_test.rb']
end

RDoc::Task.new(:rdoc) do |t|
  t.main = "README.rdoc"
  t.title = "LiveAST: Live Abstract Syntax Trees"
  t.options += ["--visibility", "private" ]
  t.rdoc_files.include("README.rdoc", "CHANGES.rdoc", "lib")

end

task default: :test
