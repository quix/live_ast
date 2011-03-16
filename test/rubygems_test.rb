require_relative 'main'
require_relative '../devel/levitate'

class RubygemsTest < RegularTest
  def test_rubygems
    lib = File.expand_path(File.dirname(__FILE__) + "/../lib")
    result = Levitate::Ruby.run_code_and_capture %{
      $LOAD_PATH.unshift '#{lib}'
      require 'live_ast/full'
      defined?(LiveASTRipper) and LiveASTRipper.steamroll = true
      f = eval %{
        lambda { 'abc' }
      }
      p f.to_ast
    }
    assert_equal no_arg_block(:lambda, 'abc').to_s, result.chomp
  end
end
