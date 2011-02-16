require_relative 'shared/main'

class DefineMethodTest < RegularTest
  DEFINE = lambda do
    class A
      {
        :f => :+,
        :g => :*,
        :h => :-,
      }.each_pair do |name, op|
        case op
        when :+
          define_method name do |x, y|
            x + y
          end
        when :*
          define_method name do |x, y|
            x * y
          end
        when :-
          define_method name do |x, y|
            x - y
          end
        end
      end
    end
  end

  def test_define_method
    DEFINE.call

    assert_equal binop_define_method_with_var(:name, :+),
                 A.instance_method(:f).to_ast

    assert_equal binop_define_method_with_var(:name, :*),
                 A.instance_method(:g).to_ast

    assert_equal binop_define_method_with_var(:name, :-),
                 A.instance_method(:h).to_ast
  end
end
