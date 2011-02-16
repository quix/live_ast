require 'ruby2ruby'

require 'live_ast/base'

[Method, UnboundMethod, Proc].each do |klass|
  klass.class_eval do
    # Generate ruby code which reflects the AST of this object.
    def to_ruby
      Ruby2Ruby.new.process(LiveAST.ast(self))
    end
  end
end
