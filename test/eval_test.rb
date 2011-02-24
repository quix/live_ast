require_relative 'main'

class EvalTest < RegularTest
  DEFINE_A = lambda do
    class A
      ast_eval %{
        def f(x, y)
          x + y
        end
      }, binding
    end
  end

  def test_eval_method
    DEFINE_A.call
    assert_equal "#{self.class}::A", A.name
    assert_equal A, A.instance_method(:f).owner

    assert_equal binop_def(:f, :+),
                 A.instance_method(:f).to_ast

    assert_equal binop_def(:f, :+),
                 A.new.method(:f).to_ast
  end

  DEFINE_B = lambda do
    ast_eval %{
      class B
        def f(x, y)
          x * y
        end
      end
    }, binding
  end

  def test_eval_class
    DEFINE_B.call
    assert_equal "#{self.class}::B", B.name
    assert_equal B, B.instance_method(:f).owner

    assert_equal binop_def(:f, :*),
                 B.instance_method(:f).to_ast

    assert_equal binop_def(:f, :*),
                 B.new.method(:f).to_ast
  end

  def test_eval_method_anon
    klass = Class.new do
      ast_eval %{
        def f(x, y)
          x - y
        end
      }, binding
    end

    assert_nil klass.name
    assert_equal klass, klass.instance_method(:f).owner

    assert_equal binop_def(:f, :-),
                 klass.instance_method(:f).to_ast

    assert_equal binop_def(:f, :-),
                 klass.new.method(:f).to_ast
  end

  def test_eval_class_anon
    klass = ast_eval %{
      Class.new do
        def f(x, y)
          x / y
        end
      end
    }, binding

    assert_nil klass.name
    assert_equal klass, klass.instance_method(:f).owner

    assert_equal binop_def(:f, :/),
                 klass.instance_method(:f).to_ast

    assert_equal binop_def(:f, :/),
                 klass.new.method(:f).to_ast
  end

  DEFINE_C = lambda do
    class C
      ast_eval %{
        define_method :g do |x, y|
          x + y
        end
      }, binding
    end
  end

  def test_eval_method_dynamic
    DEFINE_C.call
    assert_equal "#{self.class}::C", C.name
    assert_equal C, C.instance_method(:g).owner

    assert_equal binop_define_method(:g, :+), 
                 C.instance_method(:g).to_ast

    assert_equal binop_define_method(:g, :+), 
                 C.new.method(:g).to_ast
  end

  DEFINE_D = lambda do
    ast_eval %{
      class D
        define_method :g do |x, y|
          x * y
        end
      end
    }, binding
  end

  def test_eval_class_dynamic
    DEFINE_D.call
    assert_equal "#{self.class}::D", D.name
    assert_equal D, D.instance_method(:g).owner

    assert_equal binop_define_method(:g, :*),
                 D.instance_method(:g).to_ast

    assert_equal binop_define_method(:g, :*),
                 D.new.method(:g).to_ast
  end

  def test_eval_method_anon_dynamic
    klass = Class.new do
      ast_eval %{
        define_method :g do |x, y|
          x - y
        end
      }, binding
    end

    assert_nil klass.name
    assert_equal klass, klass.instance_method(:g).owner

    assert_equal binop_define_method(:g, :-),
                 klass.instance_method(:g).to_ast

    assert_equal binop_define_method(:g, :-),
                 klass.new.method(:g).to_ast
  end

  def test_eval_class_anon_dynamic
    klass = ast_eval %{
      Class.new do
        define_method :g do |x, y|
          x / y
        end
      end
    }, binding

    assert_nil klass.name
    assert_equal klass, klass.instance_method(:g).owner

    assert_equal binop_define_method(:g, :/),
                 klass.instance_method(:g).to_ast

    assert_equal binop_define_method(:g, :/),
                 klass.new.method(:g).to_ast
  end
  
  DEFINE_GH = lambda do
    ast_eval %{
      class G
        def f
          "G#f"
        end
      end
  
      class H
        def g
          "H#g"
        end
      end
    }, binding
  end
  
  def test_reuse_string
    DEFINE_GH.call
    assert_equal "#{self.class}::G", G.name
    assert_equal "#{self.class}::H", H.name

    assert_equal no_arg_def(:f, "G#f"),
                 G.instance_method(:f).to_ast

    assert_equal no_arg_def(:f, "G#f"),
                 G.new.method(:f).to_ast
    
    assert_equal no_arg_def(:g, "H#g"),
                 H.instance_method(:g).to_ast

    assert_equal no_arg_def(:g, "H#g"),
                 H.new.method(:g).to_ast
  end

  def test_module_eval
    klass = Class.new
    klass.module_eval do
      ast_eval %{
        def f
          "z"
        end
      }, binding
    end

    assert_equal klass, klass.instance_method(:f).owner

    assert_equal no_arg_def(:f, "z"),
                 klass.instance_method(:f).to_ast

    assert_equal no_arg_def(:f, "z"),
                 klass.new.method(:f).to_ast
  end

  def test_singleton_class
    obj = Object.new
    obj.singleton_class.module_eval do
      ast_eval %{
        def f
          "singleton"
        end
      }, binding
    end

    assert_equal no_arg_def(:f, "singleton"),
                 obj.method(:f).to_ast
  end

  def test_proc_in_eval
    a = ast_eval %{ proc { |x, y| x + y } }, binding

    assert_equal binop_block(:proc, :+), a.to_ast
  end

  def test_proc_new_in_eval
    a = ast_eval %{ Proc.new { |x, y| x * y } }, binding

    assert_equal binop_proc_new(:*), a.to_ast
  end

  def test_method_block_in_eval
    a = ast_eval %{ return_block { |x, y| x - y } }, binding

    assert_equal binop_block(:return_block, :-), a.to_ast
  end

  def test_lambda_in_eval
    a = ast_eval %{ lambda { |x, y| x / y } }, binding

    assert_equal binop_block(:lambda, :/), a.to_ast

    # sanity check
    assert_not_equal binop_block(:lambda, :+), a.to_ast
  end
  
  # from rubyspec
  def test_to_str_on_file
    file = MiniTest::Mock.new
    file.expect(:to_str, "zebra.rb")
    ast_eval "33 + 44", binding, file
    file.verify
  end
end
