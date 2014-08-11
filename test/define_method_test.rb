require_relative 'main'

class DefineMethodTest < RegularTest
  WITH_BLOCKS = lambda do
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

  def test_with_block
    WITH_BLOCKS.call

    assert_equal binop_define_method_with_var(:name, :+),
                 A.instance_method(:f).to_ast

    assert_equal binop_define_method_with_var(:name, :*),
                 A.instance_method(:g).to_ast

    assert_equal binop_define_method_with_var(:name, :-),
                 A.instance_method(:h).to_ast
  end

  WITH_PROCS = lambda do
    class B
      op = lambda { |x, y| x / y }

      no_arg = proc { "B#f" }

      define_method :g, &no_arg ; define_method :f, &op
    end
  end

  def test_via_block
    WITH_PROCS.call

    assert_equal binop_block(:lambda, :/),
                 B.instance_method(:f).to_ast

    assert_equal binop_block(:lambda, :/),
                 B.new.method(:f).to_ast

    assert_equal no_arg_block(:proc, "B#f"),
                 B.instance_method(:g).to_ast

    assert_equal no_arg_block(:proc, "B#f"),
                 B.new.method(:g).to_ast
  end
end
