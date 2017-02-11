require 'live_ast/base'
require 'binding_of_caller'

module LiveAST
  module ReplaceEval
    class << self
      def module_or_instance_eval(which, remote_self, bind, args)
        handle_args(args)

        cache[:remote_self] = remote_self
        cache[:args] = args

        code = %{
          ::LiveAST::ReplaceEval.cache[:remote_self].
          live_ast_original_#{which}_eval %{
            ::LiveAST.eval(
              ::LiveAST::ReplaceEval.cache[:args][0],
              ::Kernel.binding,
              *::LiveAST::ReplaceEval.cache[:args][1..-1])
          }
        }

        live_ast_original_eval(code, bind)
      ensure
        cache.clear
      end

      def cache
        Thread.current[:_live_ast_arg_cache] ||= {}
      end

      private

      def handle_args(args)
        LiveAST::Common.check_arity(args, 1..3)
        args[0] = Common.arg_to_str(args[0])
        args[1] = Common.arg_to_str(args[1]) if args.length > 1
      end
    end
  end

  # ensure the parser is loaded -- rubygems calls eval
  parser
end

# Override for Kernel#eval and Kernel.eval
module Kernel
  class << self
    alias_method :live_ast_original_singleton_eval, :eval
  end

  alias_method :live_ast_original_eval, :eval

  def eval(*args)
    LiveAST::Common.check_arity(args, 1..4)
    LiveAST.eval(
      args[0],
      args[1] || binding.of_caller(1),
      *LiveAST::Common.location_for_eval(*args[1..3]))
  end
end

# Override for Binding#eval
class Binding
  alias_method :live_ast_original_binding_eval, :eval

  def eval(*args)
    LiveAST.eval(args[0], self, *args[1..-1])
  end
end

# Override for BasicObject#instance_eval
class BasicObject
  alias_method :live_ast_original_instance_eval, :instance_eval

  def instance_eval(*args, &block)
    if block
      live_ast_original_instance_eval(*args, &block)
    else
      ::LiveAST::ReplaceEval.
        module_or_instance_eval(:instance,
                                self,
                                ::Kernel.binding.of_caller(1),
                                args)
    end
  end
end

# Overrides for Module#module_eval and Module#class_eval
class Module
  alias_method :live_ast_original_module_eval, :module_eval

  def module_eval(*args, &block)
    if block
      live_ast_original_module_eval(*args, &block)
    else
      LiveAST::ReplaceEval.
        module_or_instance_eval(:module, self, binding.of_caller(1), args)
    end
  end

  remove_method :class_eval
  alias_method :class_eval, :module_eval
end
