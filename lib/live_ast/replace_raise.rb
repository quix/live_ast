require 'live_ast/base'

module Kernel
  private

  alias_method :live_ast_original_raise, :raise

  def raise(*args)
    ex = begin
           live_ast_original_raise(*args)
         rescue Exception => ex
           ex
         end

    ex.backtrace.reject! { |line| line.index __FILE__ }

    LiveAST::Evaler.fix_backtrace ex.backtrace

    live_ast_original_raise ex
  end
end
