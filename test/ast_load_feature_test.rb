require_relative 'main'

class AAB_ASTLoadFeatureTest < BaseTest
  def test_require
    assert !private_methods.include?(:ast_load)

    require 'live_ast/ast_load'

    assert private_methods.include?(:ast_load)
  end
end
