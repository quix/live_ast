require 'main'

require 'live_ast/ast_eval'

class ASTEvalTest < BaseTest
  def test_defines_ast_eval
    assert respond_to?(:ast_eval)

    assert private_methods.include?(:ast_eval)
  end
end
