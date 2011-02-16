require_relative 'shared/main'

class ZZZ_ReplaceEvalTest < RegularTest
  def setup
    super
    require 'live_ast/replace_eval'
  end

  def mu_pp(obj)
    obj.inspect
  end
    
  DEFINE_A = lambda do
    class A
      eval %{
        def f(x, y)
          x**y
        end
      }
    end
  end

  def test_a_def_method
    DEFINE_A.call
    assert_equal binop_def(:f, :**), A.instance_method(:f).to_ast
  end

  DEFINE_B = lambda do
    eval %{
      class B
        def f(x, y)
          x / y
        end
      end
    }
    nil
  end

  def test_def_class
    DEFINE_B.call
    assert_equal "ZZZ_ReplaceEvalTest::B", B.name
    assert_equal binop_def(:f, :/), B.instance_method(:f).to_ast
  end

  def moo
    a = 33
    binding
  end

  def test_binding_eval
    result = moo.eval("a")
    assert_equal 33, result

    lam = moo.eval("lambda { a }")
    assert_equal 33, lam.call
  end

  RESULT = {}

  DEFINE_P = lambda do
    class P
      eval %{
        def f
          @x = 33
          RESULT[:old] = live_ast_original_eval("@x")
          result = eval("@x")
          RESULT[:new] = result
        end
      }
    end
  end

  def test_const_lookup
    DEFINE_P.call
    p = P.new
    p.f
    assert_equal 33, RESULT[:old]
    assert_equal 33, RESULT[:new]
  end

  def test_const_lookup_2
    Class.new do
      eval %{
        def f
          @x = 44
          RESULT[:old] = live_ast_original_eval("@x")
          result = eval("@x")
          RESULT[:new] = result
        end
      }
      nil
    end.new.f
    assert_equal 44, RESULT[:old]
    assert_equal 44, RESULT[:new]
  end

  DEFINE_QS = lambda do
    class Q
      class R
        eval %{
          def f
            RESULT[:qr] = 55
          end
        }
      end
    end
  
    module S
      class T
        eval %{
          def f
            RESULT[:st] = 66
          end
        }
      end
    end
  end
  
  def test_const_lookup_3
    DEFINE_QS.call
    Q::R.new.f
    S::T.new.f
    assert_equal 55, RESULT[:qr]
    assert_equal 66, RESULT[:st]
  end

  def test_instance_eval_arg_error
    orig = assert_raise ArgumentError do
      Object.new.live_ast_original_instance_eval
    end
    live = assert_raise ArgumentError do
      Object.new.instance_eval
    end
    assert_equal orig.message, live.message
  end

  def test_instance_eval_block
    orig = {}
    orig.live_ast_original_instance_eval do
      self[:x] = 33
    end
    assert_equal 33, orig[:x]

    live = {}
    live.instance_eval do
      self[:x] = 33
    end
    assert_equal 33, live[:x]
  end

  def test_instance_eval_string
    orig = {}
    orig.live_ast_original_instance_eval %{
      self[:x] = 33
    }
    assert_equal 33, orig[:x]

    live = {}
    live.instance_eval %{
      self[:x] = 33
    }
    assert_equal 33, live[:x]
  end

  def test_instance_eval_binding
    x = 33
    orig = {}
    orig.live_ast_original_instance_eval %{
      self[:x] = x
      self[:f] = lambda { "f" }
    }
    assert_equal x, orig[:x]

    y = 44
    live = {}
    live.instance_eval %{
      self[:y] = y
      self[:g] = lambda { "g" }
    }
    assert_equal y, live[:y]
    
    assert_equal no_arg_block(:lambda, "g"), live[:g].to_ast
  end

  def test_module_eval_block
    orig = Module.new
    orig.live_ast_original_module_eval do
      def f
        "orig"
      end
    end
    assert_nothing_raised do
      orig.instance_method(:f)
    end

    live = Module.new
    live.module_eval do
      def f
        "live"
      end
    end
    result = live.instance_method(:f)
    assert_equal no_arg_def(:f, "live"), result.to_ast
  end

  def test_module_eval_string
    orig = Module.new
    orig.live_ast_original_module_eval %{
      def f
        "orig"
      end
    }
    orig.instance_method(:f)

    live = Module.new
    live.module_eval %{
      def h
        "live h"
      end
    }
    result = live.instance_method(:h)
    assert_equal no_arg_def(:h, "live h"), result.to_ast
  end

  def test_module_eval_binding
    x = 33
    orig = Class.new
    orig.live_ast_original_module_eval %{
      define_method :value do
        x
      end
      define_method :f do
        lambda { }
      end
    }
    assert_equal 33, orig.new.value
    assert orig.new.f.is_a?(Proc)

    y = 44
    live = Class.new
    live.module_eval %{
      define_method :value do
        y
      end
      define_method :g do
        lambda { "g return" }
      end
    }
    assert_equal 44, live.new.value
    assert live.new.g.is_a?(Proc)

    assert_equal no_arg_block(:lambda, "g return"), live.new.g.to_ast
  end

  def test_module_eval_file_line
    klass = Module.new
    result = klass.module_eval("[__FILE__, __LINE__]", "test", 102)

    unfixable do
      assert_equal ["test", 102], result
    end
  end

  def test_module_eval_to_str
    file = MiniTest::Mock.new
    file.expect(:to_str, "zebra.rb")
    Class.new.module_eval("33 + 44", file)
    file.verify
  end

  def foo(*args)
  end
  
  def test_eval_usage_error
    assert_raise LiveAST::EvalUsageError do
      foo(1, eval("2 + 3"))
    end

    result = eval("2 + 3")
    foo(1, result)

    assert_raise LiveAST::EvalUsageError do
      1.times do
        eval("1 + 2")
      end
    end

    1.times do
      result = eval("1 + 2")
      result
    end

    assert_raise LiveAST::EvalUsageError do
      eval %{ eval("1 + 2") } 
    end

    eval %{ result = eval("1 + 2") ; result }
  end

  def test_recursive
    result = eval %{
      res = eval %{ 2 + 3 }
      5 + res
    }
    assert_equal 10, result
  end

  def test_nutty_eval
    # From rubyspec via http://jira.codehaus.org/browse/JRUBY-5163

    # eval("self").should equal(self)

    result = eval("self")
    assert_equal self, result

    # Kernel.eval("self").should equal(Kernel)

    result = Kernel.eval("self")
    assert_equal Kernel, result
  end
end
