require_relative 'shared/main'

class DefTest < RegularTest
  class A
    def f
      "A#f"
    end
  end

  def test_def_unbound_method_a
    expected = no_arg_def(:f, "A#f")
    assert_equal expected, A.instance_method(:f).to_ast
  end

  def test_def_method_a
    expected = no_arg_def(:f, "A#f")
    assert_equal expected, A.new.method(:f).to_ast
  end

  class B
    def f(x, y)
      x + y
    end
  end

  def test_def_unbound_method_b
    expected = binop_def(:f, :+)
    assert_equal expected, B.instance_method(:f).to_ast
  end

  def test_def_instance_method_b
    expected = binop_def(:f, :+)
    assert_equal expected, B.new.method(:f).to_ast
  end
end
