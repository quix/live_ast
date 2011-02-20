require 'ruby2ruby'

require 'live_ast/base'

[Method, UnboundMethod, Proc].each do |klass|
  klass.class_eval do
    def to_ruby  #:nodoc:
      Ruby2Ruby.new.process(LiveAST.ast(self))
    end
  end
end

class Method
  # :method: to_ruby
  # Generate ruby code which reflects the AST of this object.
  #
  # Defined by <code>require 'live_ast/to_ruby'</code>. The ruby2ruby
  # gem must be installed.
end

class UnboundMethod
  # :method: to_ruby
  # Generate ruby code which reflects the AST of this object.
  #
  # Defined by <code>require 'live_ast/to_ruby'</code>. The ruby2ruby
  # gem must be installed.
end

class Proc
  # :method: to_ruby
  # Generate ruby code which reflects the AST of this object.
  # 
  # Defined by <code>require 'live_ast/to_ruby'</code>. The ruby2ruby
  # gem must be installed.
end
