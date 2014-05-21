require 'rake/clean'
require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rdoc/task'

namespace :test do
  desc 'run tests'
  Rake::TestTask.new(:main) do |t|
    t.libs = ['lib']
    t.ruby_opts += ["-w -Itest"]
    t.test_files = FileList['test/*_test.rb']
  end

  Rake::TestTask.new(:base) do |t|
    t.libs = ['lib']
    t.ruby_opts += ["-w -Itest"]
    t.test_files = FileList['test/base/*_test.rb']
  end

  Rake::TestTask.new(:ast_load) do |t|
    t.libs = ['lib']
    t.ruby_opts += ["-w -Itest"]
    t.test_files = FileList['test/ast_load/*_test.rb']
  end

  Rake::TestTask.new(:ast_eval) do |t|
    t.libs = ['lib']
    t.ruby_opts += ["-w -Itest"]
    t.test_files = FileList['test/ast_eval/*_test.rb']
  end

  Rake::TestTask.new(:to_ast) do |t|
    t.libs = ['lib']
    t.ruby_opts += ["-w -Itest"]
    t.test_files = FileList['test/to_ast/*_test.rb']
  end

  Rake::TestTask.new(:to_ruby) do |t|
    t.libs = ['lib']
    t.ruby_opts += ["-w -Itest"]
    t.test_files = FileList['test/to_ruby/*_test.rb']
  end

  Rake::TestTask.new(:full) do |t|
    t.libs = ['lib']
    t.ruby_opts += ["-w -Itest"]
    t.test_files = FileList['test/full/*_test.rb']
  end

  task all: [:main, :base, :ast_load, :to_ast, :to_ruby, :full]
end

RDoc::Task.new(:rdoc) do |t|
  t.main = "README.rdoc"
  t.title = "LiveAST: Live Abstract Syntax Trees"
  t.options += ["--visibility", "private" ]
  t.rdoc_files.include("README.rdoc", "CHANGES.rdoc", "lib")
end

task default: 'test:all'
