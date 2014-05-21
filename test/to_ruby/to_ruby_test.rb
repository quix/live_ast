require 'main'

class AAC_ToRubyTest < RegularTest
  def setup
    super
    require 'live_ast/to_ruby'
  end

  def test_lambda_0
    src = %{lambda { "moo" }}
    dst = ast_eval(src, binding).to_ruby
    assert_equal src, dst
  end

  def test_lambda_1
    src = %{lambda { |x| (x ** 2) }}
    dst = ast_eval(src, binding).to_ruby
    assert_equal src, dst
  end

  def test_lambda_2
    src = %{lambda { |x, y| (x + y) }}
    dst = ast_eval(src, binding).to_ruby
    assert_equal src, dst
  end

  def test_proc_0
    src = %{proc { "moo" }}
    dst = ast_eval(src, binding).to_ruby
    assert_equal src, dst
  end

  def test_proc_1
    src = %{proc { |x| (x ** 2) }}
    dst = ast_eval(src, binding).to_ruby
    assert_equal src, dst
  end

  def test_proc_2
    src = %{proc { |x, y| (x * y) }}
    dst = ast_eval(src, binding).to_ruby
    assert_equal src, dst
  end

  def test_block_0
    src = %{return_block { "moo" }}
    dst = ast_eval(src, binding).to_ruby
    assert_equal src, dst
  end

  def test_block_1
    src = %{return_block { |x| (x ** 2) }}
    dst = ast_eval(src, binding).to_ruby
    assert_equal src, dst
  end

  def test_block_2
    src = %{return_block { |x, y| (x - y) }}
    dst = ast_eval(src, binding).to_ruby
    assert_equal src, dst
  end

  def test_method_0
    src = %{def f\n  "moo"\nend}
    dst = Class.new do
      ast_eval(src, binding)
    end.instance_method(:f).to_ruby
    assert_equal src, dst
  end

  def test_method_1
    src = %{def f(x)\n  (x ** 2)\nend}
    dst = Class.new do
      ast_eval(src, binding)
    end.instance_method(:f).to_ruby
    assert_equal src, dst
  end

  def test_method_2
    src = %{def f(x, y)\n  (x / y)\nend}
    dst = Class.new do
      ast_eval(src, binding)
    end.instance_method(:f).to_ruby
    assert_equal src, dst
  end
end if LiveAST.parser::Test.respond_to?(:unparser_matches_ruby2ruby?) &&
       LiveAST.parser::Test.unparser_matches_ruby2ruby?
