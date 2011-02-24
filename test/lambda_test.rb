require_relative 'main'

class LambdaTest < RegularTest
  def test_block_braces_multiline
    block = return_block { |x, y|
      x + y
    }

    expected = binop_block(:return_block, :+)
    assert_equal expected, block.to_ast
  end

  def test_block_do_end_multiline
    block = return_block do |x, y|
      x * y
    end

    expected = binop_block(:return_block, :*)
    assert_equal expected, block.to_ast
  end

  def test_lambda
    a = lambda { |x, y| x - y }

    expected = binop_block(:lambda, :-)
    assert_equal expected, a.to_ast
  end

  def test_proc
    a = proc { |x, y| x / y }

    expected = binop_block(:proc, :/)
    assert_equal expected, a.to_ast
  end

  def test_proc_new
    a = Proc.new { |x, y| x + y }

    expected = binop_proc_new(:+)
    assert_equal expected, a.to_ast
  end

  def test_block_braces_one_line
    block = return_block { |x, y| x * y }

    expected = binop_block(:return_block, :*)
    assert_equal expected, block.to_ast
  end

  def test_block_do_end_one_line
    block = return_block do |x, y| x - y end

    expected = binop_block(:return_block, :-)
    assert_equal expected, block.to_ast
  end
end
