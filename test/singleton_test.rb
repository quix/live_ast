require_relative 'main'

class SingletonTest < RegularTest
  class A
    def self.f
      "A.f"
    end
  end

  def test_self_dot
    expected = singleton_no_arg_def(:f, "A.f")
    assert_equal expected, A.method(:f).to_ast
  end

  class B
    def B.f(x, y)
      x + y
    end
  end

  def test_name_dot
    expected = singleton_binop_def(:B, :f, :+)
    assert_equal expected, B.method(:f).to_ast
  end
end
