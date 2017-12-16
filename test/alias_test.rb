require_relative 'main'

class AliasTest < RegularTest
  class A
    def f
      "A#f"
    end

    alias g f
  end

  def test_alias_unbound_method
    expected = no_arg_def(:f, "A#f")
    assert_equal expected, A.instance_method(:f).to_ast
    assert_equal expected, A.instance_method(:g).to_ast
  end

  def test_alias_method
    expected = no_arg_def(:f, "A#f")
    assert_equal expected, A.new.method(:f).to_ast
    assert_equal expected, A.new.method(:g).to_ast
  end
end
