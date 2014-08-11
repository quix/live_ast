require_relative 'main'

# test for flushing side-effects: unsort this TestCase from other
# TestCases.

define_unsorted_test_case "FlushCacheTest", RegularTest do
  def test_cache
    # testing global state of cache -- must be sequential
    uncached_method_from_require
    uncached_method_from_eval
    cached_method_from_eval
    lost_method_from_require
    flush_lambda
  end

  def uncached_method_from_require
    klass = Class.new do
      def f; end
      def g; end
    end

    LiveAST.flush_cache

    #
    # file never made it into the cache; unaffected by flush
    #
    assert_nothing_raised do
      klass.instance_method(:g).to_ast
    end
  end

  def uncached_method_from_eval
    klass = Class.new do
      ast_eval %{
        def f ; end
        def g ; end
      }, binding
    end

    LiveAST.flush_cache

    assert_raises LiveAST::ASTNotFoundError do
      klass.instance_method(:g).to_ast
    end
  end

  def cached_method_from_eval
    klass = Class.new do
      ast_eval %{
        def f ; end
        def g ; end
      }, binding
    end

    f_ast = klass.instance_method(:f).to_ast

    LiveAST.flush_cache

    assert_equal f_ast.object_id,
                 klass.instance_method(:f).to_ast.object_id

    assert_raises LiveAST::ASTNotFoundError do
      klass.instance_method(:g).to_ast
    end
  end

  def lost_method_from_require
    klass = Class.new do
      def f; end
      def g; end
    end

    # check that previous flushing did not cause side effect
    assert_nothing_raised do
      klass.instance_method(:f).to_ast
    end
  end

  def flush_lambda
    a, b = ast_eval %{
      [
        lambda { "aaa" },
        lambda { "bbb" },
      ]
    }, binding

    a_ast = a.to_ast
    assert_equal no_arg_block(:lambda, "aaa"), a_ast

    LiveAST.flush_cache

    assert_equal a_ast.object_id, a.to_ast.object_id

    assert_raises LiveAST::ASTNotFoundError do
      b.to_ast
    end
  end
end
