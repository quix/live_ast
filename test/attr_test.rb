require_relative 'main'

class AttrTest < RegularTest
  class A
    attr_accessor :f
    attr_reader :g
    attr_writer :h
  end

  def test_attr
    assert_raises LiveAST::ASTNotFoundError do
      A.instance_method(:f).to_ast
    end
    assert_raises LiveAST::ASTNotFoundError do
      A.instance_method(:f=).to_ast
    end
    assert_raises LiveAST::ASTNotFoundError do
      A.instance_method(:g).to_ast
    end
    assert_raises LiveAST::ASTNotFoundError do
      A.instance_method(:h=).to_ast
    end
  end
end
