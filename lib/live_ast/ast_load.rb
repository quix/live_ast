require 'live_ast/base'

module Kernel
  private

  #
  # For use in noninvasive mode (<code>require 'live_ast/base'</code>).
  #
  # Same behavior as the built-in +load+ except that AST-accessible
  # objects are created.
  #
  def ast_load(file, wrap = false)
    LiveAST::Loader.load(file, wrap)
  end
end
