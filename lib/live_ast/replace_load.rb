require 'live_ast/base'

module Kernel
  alias live_ast_original_load load

  def load(file, wrap = false)
    LiveAST.load(file, wrap)
  end

  class << self
    remove_method :load
  end
  module_function :load
end
