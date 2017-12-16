require_relative 'main'
require 'live_ast/irb_spy'

class IRBTest < RegularTest
  def with_module(parent, child)
    parent.const_set child, Module.new
    begin
      yield
    ensure
      parent.send :remove_const, child
    end
  end

  def setup
    LiveAST::IRBSpy.history = [
      nil,
      "class Foo; def bar; 'bar'; end; end",
      "class Bar",
      "  def foo",
      "    'foo'",
      "  end",
      "end"
    ]
  end

  def test_single_line
    with_module(Object, :IRB) do
      expected = no_arg_def(:bar, "bar")
      result = LiveAST::Linker.fetch_from_cache("(irb)", 1)
      assert_equal expected, result
    end
  end

  def test_multiple_lines
    with_module(Object, :IRB) do
      expected = no_arg_def(:foo, "foo")
      result = LiveAST::Linker.fetch_from_cache("(irb)", 3)
      assert_equal expected, result
    end
  end
end
