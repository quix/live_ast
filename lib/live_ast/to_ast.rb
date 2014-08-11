require 'live_ast/base'

[Method, UnboundMethod].each do |klass|
  klass.class_eval do
    def to_ast #:nodoc:
      LiveAST::Linker.find_method_ast(owner, name, *source_location)
    end
  end
end

class Proc
  # Extract the AST of this object.
  def to_ast
    LiveAST::Linker.find_proc_ast(self)
  end
end

class Method
  # :method: to_ast
  # Extract the AST of this object.
end

class UnboundMethod
  # :method: to_ast
  # Extract the AST of this object.
end
