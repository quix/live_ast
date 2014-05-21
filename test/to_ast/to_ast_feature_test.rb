require 'main'

class AAB_ToASTFeatureTest < BaseTest
  def test_require
    [Method, UnboundMethod, Proc].each { |obj|
      assert !obj.instance_methods.include?(:to_ast)
    }

    require 'live_ast/to_ast'

    [Method, UnboundMethod, Proc].each { |obj|
      assert obj.instance_methods.include?(:to_ast)
    }
  end
end
