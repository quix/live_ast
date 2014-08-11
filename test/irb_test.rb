require_relative 'main'

class IRBTest < RegularTest
  def with_module(parent, child)
    parent.const_set child, Module.new
    begin
      yield
    ensure
      parent.send :remove_const, child
    end
  end

  def test_irb
    with_module(Object, :IRB) do
      with_module(LiveAST, :IRBSpy) do
        LiveAST::IRBSpy.class_eval do
          def self.code_at(_line)
            "def f ; end"
          end
        end
        LiveAST::Linker.fetch_from_cache("(irb)", 1)
      end
    end
  end
end
