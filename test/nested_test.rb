require_relative 'main'

class NestedTest < RegularTest
  def test_lambda
    a = lambda {
      lambda {
        "33"
      }
    }

    assert_equal nested_lambdas("33"), a.to_ast
    assert_equal no_arg_block(:lambda, "33"), a.call.to_ast
  end

  class A
    def f
      Class.new do
        def g
          "44"
        end
      end
    end
  end

  def test_defs
    assert_equal nested_defs(:f, :g, "44"), A.instance_method(:f).to_ast
    assert_equal no_arg_def(:g, "44"), A.new.f.instance_method(:g).to_ast
  end
end
