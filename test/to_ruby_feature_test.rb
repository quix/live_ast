require_relative 'shared/main'

class AAB_ToRubyFeatureTest < BaseTest
  def test_require
    [Method, UnboundMethod, Proc].each { |obj|
      assert !obj.instance_methods.include?(:to_ruby)
    }

    require 'live_ast/to_ruby'

    [Method, UnboundMethod, Proc].each { |obj|
      assert obj.instance_methods.include?(:to_ruby)
    }
  end
end
