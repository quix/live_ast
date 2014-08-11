require_relative 'main'

class CovertDefineMethodTest < RegularTest
  DEFINE = lambda do
    class A
      def A.my_def(*args, &block)
        define_method(*args, &block)
      end

      my_def :h do |x, y|
        x + y
      end
    end
  end

  def test_covert_define_method
    DEFINE.call
    assert_equal 77, A.new.h(33, 44)

    assert_equal binop_define_method(:h, :+, :my_def),
                 A.instance_method(:h).to_ast
  end
end
