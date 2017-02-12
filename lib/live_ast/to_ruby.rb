require 'live_ast/base'

[Method, UnboundMethod, Proc].each do |klass|
  klass.class_eval do
    def to_ruby #:nodoc:
      LiveAST.parser::Unparser.unparse(LiveAST.ast(self))
    end
  end
end

class Method
  # :method: to_ruby
  # Generate ruby code which reflects the AST of this object.
end

class UnboundMethod
  # :method: to_ruby
  # Generate ruby code which reflects the AST of this object.
end

class Proc
  # :method: to_ruby
  # Generate ruby code which reflects the AST of this object.
end
