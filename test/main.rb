$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')

# require first for stdlib_test
require 'pp'
require 'find'
require 'fileutils'

require 'minitest/unit'
require 'minitest/mock'
require 'minitest/autorun' unless defined? Rake

require 'live_ast/base'

def define_unsorted_test_case(name, superclass, &block)
  klass = Class.new superclass, &block
  letter = ('A'..'Z').to_a[rand(26)]
  Object.const_set "#{letter}#{name}", klass
end

class JLMiniTest < MiniTest::Unit::TestCase
  def self.test_methods
    default = super
    onlies = default.select { |m| m =~ %r!__only\Z! }
    if onlies.empty?
      default
    else
      puts "\n!!! NOTE: running ONLY *__only tests for #{self}"
      onlies
    end
  end

  def delim(char)
    "\n" << (char*72) << "\n"
  end

  def mu_pp(obj)
    delim("_") <<
    obj.pretty_inspect.chomp <<
    delim("=")
  end

  def unfixable
    begin
      yield
      raise "claimed to be unfixable, but assertion succeeded"
    rescue MiniTest::Assertion
    end
  end

  def assert_nothing_raised
    assert_equal 3, 3
    yield
  rescue => ex
    raise MiniTest::Assertion,
    exception_details(ex, "Expected nothing raised, but got:")
  end

  %w[
    empty
    equal
    in_delta
    in_epsilon
    includes
    instance_of
    kind_of
    match
    nil
    operator
    respond_to
    same
  ].each { |name|
    alias_method "assert_not_#{name}", "refute_#{name}"
  }
end

class BaseTest < JLMiniTest
  include LiveAST.parser::Test

  DATA_DIR = File.expand_path(File.dirname(__FILE__) + "/data")

  def self.stdlib_has_source?
    case RUBY_ENGINE
    when "ruby"  # MRI; possibly others; not jruby
      true
    end
  end

  def temp_file(basename = nil)
    basename ||= ('a'..'z').to_a.shuffle.join + ".rb"
    path = DATA_DIR + "/" + basename
    FileUtils.mkdir DATA_DIR unless File.directory? DATA_DIR

    FileUtils.rm_f path
    begin
      yield path
    ensure
      FileUtils.rm_f path
      FileUtils.rmdir DATA_DIR rescue nil
    end
  end

  def write_file(file, contents)
    File.open(file, "w") { |f| f.print contents }
  end

  def return_block(&block)
    block
  end

  def exception_backtrace
    begin
      yield
    rescue Exception => e
      e.backtrace
    end
  end
end

class RegularTest < BaseTest
  def setup
    super
    require 'live_ast'
  end
end
