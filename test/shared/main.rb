$LOAD_PATH.unshift File.dirname(__FILE__) + '/../../lib'

# require first for stdlib_test
require 'pp'
require 'find'
require 'fileutils'

require 'minitest/unit'
require 'minitest/mock'
require 'minitest/autorun'
require 'live_ast/base'

require_relative "ast_generators"

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
    ":\n" << (char*72) << "\n"
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

  alias_method :assert_raise, :assert_raises
  alias_method :assert_not_equal, :refute_equal
  alias_method :assert_not_nil, :refute_nil

  def assert_nothing_raised
    assert_equal 3, 3
    yield
  rescue => ex
    raise MiniTest::Assertion,
      exception_details(ex, "Expected nothing raised, but got:")
  end
end

class BaseTest < JLMiniTest
  include ASTGenerators

  DATA_DIR = File.dirname(__FILE__) + "/data"

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
