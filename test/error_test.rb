require_relative 'main'

class ErrorTest < RegularTest
  def test_multiple_lambda_same_line
    a = lambda { } ; b = lambda { }
    
    assert_raises LiveAST::MultipleDefinitionsOnSameLineError do
      a.to_ast
    end
  end

  DEFINE_A = lambda do
    class A
      def f ; end ; def g ; end
    end
  end

  def test_multi_defs
    DEFINE_A.call
    assert_raises LiveAST::MultipleDefinitionsOnSameLineError do
      A.instance_method(:f).to_ast
    end
  end

  def test_ast_not_found
    assert_raises LiveAST::ASTNotFoundError do
      File.method(:open).to_ast
    end
  end

  def test_arg_error_too_many
    orig = assert_raises ArgumentError do
      eval("s", binding, "f", 99, nil)
    end

    live = assert_raises ArgumentError do
      ast_eval("s", binding, "f", 99, nil)
    end

    assert_equal orig.message.sub("1..4", "2..4"), live.message
  end

  def test_bad_args
    [99, Object.new, File].each do |bad|
      orig = assert_raises TypeError do
        eval(bad, binding)
      end
      live = assert_raises TypeError do
        ast_eval(bad, binding)
      end
      assert_equal orig.message, live.message

      orig = assert_raises TypeError do
        eval("3 + 4", binding, bad)
      end
      live = assert_raises TypeError do
        ast_eval("3 + 4", binding, bad)
      end
      assert_equal orig.message, live.message
    end
  end

  def test_raw_eval
    f = eval("lambda { }")
    assert_raises LiveAST::RawEvalError do
      f.to_ast
    end
  end

  def test_reload_with_raw_eval_1
    ast_eval("lambda { }", binding)
    eval("lambda { }")
  end
  
  def test_reload_with_raw_eval_2
    c = ast_eval %{
      Class.new do
        def f
        end
      end
    }, binding
    c.module_eval do
      eval %{
        remove_method :f
        def f(x, y)
          x + y
        end
      }
      nil
    end
    
    assert_raises LiveAST::RawEvalError do
      c.instance_method(:f).to_ast
    end
  end
  
  def test_bad_binding
    orig = assert_raises TypeError do
      eval("", "bogus")
    end

    live = assert_raises TypeError do
      ast_eval("", "bogus")
    end

    assert_equal orig.message, live.message
  end

  def test_shenanigans
    error = assert_raises RuntimeError do
      LiveAST.load "foo.rb|ast@4"
    end
    assert_match(/revision token/, error.message)
  end
end
