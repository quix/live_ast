require_relative 'main'

class RecursiveEvalTest < RegularTest
  DEFINE = lambda do
    ast_eval %{
      class A
        ast_eval %{
          def f
            "A#f"
          end
        }, binding
  
        ast_eval %{
          ast_eval %{
            remove_method :f
            def f(x, y)
              x + y
            end

            def g
              "A#g"
            end
          }, binding
  
          LAMBDA = ast_eval %{
            lambda { |x, y| x * y }
          }, binding
        }, binding
      end
    }, binding
  end

  def test_method
    defined?(A) or DEFINE.call
    assert_equal "#{self.class}::A", A.name

    assert_equal binop_def(:f, :+),
                 A.instance_method(:f).to_ast

    assert_equal no_arg_def(:g, "A#g"),
                 A.instance_method(:g).to_ast
  end

  def test_lambda
    defined?(A) or DEFINE.call
    assert_equal "#{self.class}::A", A.name

    assert_equal binop_block(:lambda, :*),
                 A::LAMBDA.to_ast
  end
end

