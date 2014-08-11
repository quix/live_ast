require 'main'

class AAA_NoninvasiveTest < BaseTest
  def test_no_clutter
    [Method, UnboundMethod, Proc].each do |klass|
      assert !klass.instance_methods.include?(:to_ast)
      assert !klass.instance_methods.include?(:to_ruby)
    end

    assert !respond_to?(:ast_eval)
    assert !private_methods.include?(:ast_eval)
    assert !Kernel.respond_to?(:ast_eval)
    assert !respond_to?(:ast_load)
    assert !private_methods.include?(:ast_load)
    assert !Kernel.respond_to?(:ast_load)
  end

  DEFINE_A = lambda do
    class A
      def f
        "A#f"
      end
    end
  end

  def test_method
    DEFINE_A.call

    expected = no_arg_def(:f, "A#f")
    assert_equal expected, LiveAST.ast(A.instance_method(:f))
    assert_equal expected, LiveAST.ast(A.new.method(:f))
  end

  def test_lambda
    a = lambda { |x, y| x ** y }

    assert_equal binop_block(:lambda, :**), LiveAST.ast(a)
  end

  def test_ast_eval
    code = %{ lambda { |x, y| x / y } }

    expected = binop_block(:lambda, :/)
    result = LiveAST.ast(LiveAST.eval(code, binding))
    assert_equal expected, result
  end

  def test_bogus
    assert_raises TypeError do
      LiveAST.ast(99)
    end
  end
end
