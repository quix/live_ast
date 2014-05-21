require 'main'

require 'live_ast/to_ast'

class AAB_ToASTFeatureTest < BaseTest
  def test_require
    [Method, UnboundMethod, Proc].each { |obj|
      assert obj.instance_methods.include?(:to_ast)
    }
  end
end
