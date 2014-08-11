require 'main'

require 'live_ast/to_ruby'

class ToRubyFeatureTest < BaseTest
  def test_defines_to_ruby
    [Method, UnboundMethod, Proc].each { |obj|
      assert obj.instance_methods.include?(:to_ruby)
    }
  end
end
