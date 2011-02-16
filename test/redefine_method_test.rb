require_relative 'shared/main'

class RedefineMethodTest < RegularTest
  DEFINE_A = lambda do
    class A
      def f
        "old A#f"
      end
      
      PREVIOUS_Af = instance_method(:f)
      remove_method :f
      
      def f(x, y)
        x * y
      end
    end
  end

  def test_inclass_redef
    DEFINE_A.call

    assert_equal binop_def(:f, :*),
                 A.instance_method(:f).to_ast

    assert_equal no_arg_def(:f, "old A#f"),
                 A::PREVIOUS_Af.to_ast
  end

  DEFINE_B = lambda do
    class B
      def f
        "old B#f"
      end
    end
  end

  def test_dynamic_redef
    DEFINE_B.call

    assert_equal "old B#f", B.new.f
    assert_equal no_arg_def(:f, "old B#f"), B.instance_method(:f).to_ast

    B.class_eval do
      remove_method :f
      define_method :f do |x, y|
        x - y
      end
    end

    assert_equal 11, B.new.f(44, 33)

    assert_equal binop_define_method(:f, :-),
                 B.instance_method(:f).to_ast
  end

  DEFINE_C = lambda do
    class C
      def f
        "old C#f"
      end
    end
  end

  def test_dynamic_redef_with_eval
    DEFINE_C.call

    assert_equal "old C#f", C.new.f

    C.class_eval do
      ast_eval %{
        remove_method :f
        define_method :f do |x, y|
          x * y
        end
      }, binding
    end

    assert_equal 12, C.new.f(3, 4)

    assert_equal binop_define_method(:f, :*),
                 C.instance_method(:f).to_ast
  end
end
