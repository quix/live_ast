require 'live_ast/base'
require 'boc'

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

      def handle_args(args)
        if args.empty?
          raise ArgumentError, "block not supplied"
        end
        
        args[0] = Common.arg_to_str(args[0])
        
        unless (1..3).include? args.size
          raise ArgumentError,
          "wrong number of arguments: instance_eval(src) or instance_eval{..}"
        end
        
        args[1] = Common.arg_to_str(args[1]) if args[1]
      end
    end
  end
  
  # ensure the parser is loaded -- rubygems calls eval
  parser
end

# squelch alias warnings
prev_verbose = $VERBOSE
$VERBOSE = nil

module Kernel
  class << self
    alias_method :live_ast_original_singleton_eval, :eval

    def eval(*args)
      LiveAST::Common.check_arity(args, 1..4)
      LiveAST.eval(
        "::Kernel.live_ast_original_instance_eval do;" << args[0] << ";end",
        args[1] || Boc.value,
        *LiveAST::Common.location_for_eval(*args[1..3]))
    end

    Boc.enable self, :eval
  end

  private

  alias_method :live_ast_original_eval, :eval

  def eval(*args)
    LiveAST::Common.check_arity(args, 1..4)
    LiveAST.eval(
      args[0],
      args[1] || Boc.value,
      *LiveAST::Common.location_for_eval(*args[1..3]))
  end

  Boc.enable self, :eval
end

class Binding
  alias_method :live_ast_original_binding_eval, :eval

  def eval(*args)
    LiveAST.eval(args[0], self, *args[1..-1])
  end
end

class BasicObject
  alias_method :live_ast_original_instance_eval, :instance_eval

  def instance_eval(*args, &block)
    if block
      live_ast_original_instance_eval(*args, &block)
    else
      ::LiveAST::ReplaceEval.
      module_or_instance_eval(:instance, self, ::Boc.value, args)
    end
  end

  ::Boc.enable_basic_object self, :instance_eval
end

class Module
  alias_method :live_ast_original_module_eval, :module_eval

  def module_eval(*args, &block)
    if block
      live_ast_original_module_eval(*args, &block)
    else
      LiveAST::ReplaceEval.
      module_or_instance_eval(:module, self, Boc.value, args)
    end
  end

  Boc.enable self, :module_eval

  remove_method :class_eval
  alias_method :class_eval, :module_eval
end

# unsquelch alias warnings
$VERBOSE = prev_verbose
