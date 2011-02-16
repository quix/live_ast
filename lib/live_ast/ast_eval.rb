require 'live_ast/base'

module Kernel
  private

  #
  # The same as +eval+ except that the binding argument is required
  # and AST-accessible objects are created.
  #
  def ast_eval(*args)
    LiveAST::Evaler.eval(args[0], *args)
  end
end
