require_relative 'main'

class AAB_ASTEvalFeatureTest < BaseTest
  def test_require
    assert !private_methods.include?(:ast_eval)

    require 'live_ast/ast_eval'

    assert private_methods.include?(:ast_eval)
  end
end
