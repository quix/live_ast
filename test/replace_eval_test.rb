require_relative 'main'

class ZZY_ReplaceEvalTest < ReplaceEvalTest
  RESULT = {}

  def setup
    RESULT.clear
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
  end

  def test_def_class
    DEFINE_B.call
    assert_equal "ZZY_ReplaceEvalTest::B", B.name
    assert_equal binop_def(:f, :/), B.instance_method(:f).to_ast
  end

  def moo
    a = 22
    binding
  end

  def test_binding_eval
    assert_equal 22, moo.eval("a")
    assert_equal 22, moo.eval("lambda { a }").call
  end

  DEFINE_P = lambda do
    class P
      eval %{
        def f
          @x = 33
          RESULT[:old] = live_ast_original_eval("@x")
          RESULT[:new] = eval("@x")
        end
      }
    end
  end

  def test_const_lookup
    DEFINE_P.call
    P.new.f

    assert_equal 33, RESULT[:old]
    assert_equal 33, RESULT[:new]
  end

  def test_const_lookup_2
    Class.new do
      eval %{
        def f
          @x = 44
          RESULT[:old] = live_ast_original_eval("@x")
          RESULT[:new] = eval("@x")
        end
      }
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

  def test_eval_arg_error
    [[], (1..5).to_a].each do |args|
      orig = assert_raises ArgumentError do
        live_ast_original_eval(*args)
      end
      live = assert_raises ArgumentError do
        eval(*args)
      end
      assert_equal orig.message, live.message
    end
  end

  def test_singleton_eval_arg_error
    [[], (1..5).to_a].each do |args|
      orig = assert_raises ArgumentError do
        Kernel.live_ast_original_singleton_eval(*args)
      end
      live = assert_raises ArgumentError do
        Kernel.eval(*args)
      end
      assert_equal orig.message, live.message
    end
  end

  def test_instance_eval_arg_error_no_block
    [[], ('a'..'z').to_a].each do |args|
      orig = assert_raises ArgumentError do
        Object.new.live_ast_original_instance_eval(*args)
      end
      live = assert_raises ArgumentError do
        Object.new.instance_eval(*args)
      end
      assert_equal orig.message, live.message
    end

    orig = assert_raises TypeError do
      Object.new.live_ast_original_instance_eval(nil)
    end
    live = assert_raises TypeError do
      Object.new.instance_eval(nil)
    end
    assert_equal orig.message, live.message

    [[nil], [Object.new], [3], [4,3,2], (1..10).to_a].each do |args|
      orig = assert_raises TypeError do
        Object.new.live_ast_original_instance_eval(*args)
      end
      live = assert_raises TypeError do
        Object.new.instance_eval(*args)
      end
      assert_equal orig.message, live.message
    end
  end

  def test_instance_eval_arg_error_with_block
    orig = assert_raises ArgumentError do
      Object.new.live_ast_original_instance_eval(3,4,5) { }
    end
    live = assert_raises ArgumentError do
      Object.new.instance_eval(3,4,5) { }
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
      self[:x] = 44
    end
    assert_equal 44, live[:x]
  end

  def test_instance_eval_string
    orig = {}
    orig.live_ast_original_instance_eval %{
      self[:x] = 33
    }
    assert_equal 33, orig[:x]

    live = {}
    live.instance_eval %{
      self[:x] = 44
    }
    assert_equal 44, live[:x]
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
    orig.instance_method(:f)

    live = Module.new
    live.module_eval do
      def f
        "live"
      end
    end
    assert_equal no_arg_def(:f, "live"),
                 live.instance_method(:f).to_ast
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
    assert_equal no_arg_def(:h, "live h"),
                 live.instance_method(:h).to_ast
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

    assert_equal no_arg_block(:lambda, "g return"),
                 live.new.g.to_ast
  end

  def test_module_eval_file_line
    klass = Module.new

    orig =
      klass.live_ast_original_module_eval("[__FILE__, __LINE__]", "test", 102)
    live =
      klass.module_eval("[__FILE__, __LINE__]", "test", 102)

    unfixable do
      assert_equal orig, live
    end
    
    live.first.sub!(/#{Regexp.quote LiveAST::Linker::REVISION_TOKEN}.*\Z/, "")
    assert_equal orig, live
    assert_equal ["test", 102], live
  end

  def test_module_eval_to_str
    file = MiniTest::Mock.new
    file.expect(:to_str, "zebra.rb")
    Class.new.module_eval("33 + 44", file)
    file.verify
  end

  def test_eval_not_hosed
    assert_equal 3, eval("1 + 2")
    1.times do
      assert_equal 3, eval("1 + 2")
    end

    assert_equal(3, eval(%{ eval("1 + 2") }))
    1.times do
      assert_equal(3, eval(%{ eval("1 + 2") }))
    end

    x = 5
    eval %{
      assert_equal(3, eval(%{ eval("1 + 2") }))
      x = 6
    }
    assert_equal 6, x
  end

  def test_local_var_collision
    args = 33

    assert_equal 33, live_ast_original_eval("args")
    assert_equal 33, eval("args")

    assert_equal 33, Kernel.live_ast_original_singleton_eval("args")
    assert_equal 33, Kernel.eval("args")

    assert_equal 33, binding.live_ast_original_binding_eval("args")
    assert_equal 33, binding.eval("args")

    assert_equal 33, Object.new.live_ast_original_instance_eval("args")
    assert_equal 33, Object.new.instance_eval("args")

    assert_equal 33, Class.new.live_ast_original_module_eval("args")
    assert_equal 33, Class.new.module_eval("args")

    assert_equal 33, Class.new.live_ast_original_instance_eval("args")
    assert_equal 33, Class.new.instance_eval("args")
  end

  def test_location_without_binding
    expected = ["(eval)", 2]

    assert_equal expected, live_ast_original_eval("\n[__FILE__, __LINE__]")

    unfixable do
      assert_equal expected, eval("\n[__FILE__, __LINE__]")
    end

    file, line = eval("\n[__FILE__, __LINE__]")
    file = LiveAST.strip_token file

    assert_equal expected, [file, line]
  end

  DEFINE_BO_TEST = lambda do
    class BasicObject
      Kernel.eval("1 + 1")
    end
  end

  def test_basic_object
    ::BasicObject.new.instance_eval %{
      t = 33
      ::ZZY_ReplaceEvalTest::RESULT[:bo_test] = t + 44
    }
    assert_equal 77, RESULT[:bo_test]
  end
end
