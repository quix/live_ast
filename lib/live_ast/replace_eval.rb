#
# ***NOTE: Before proceeding you will have to apply a patch for a
# continuation bug in the Ruby interpreter
# (http://redmine.ruby-lang.org/issues/show/4347). As of this writing
# the bug has not been fixed in the repository.
#
#   require 'live_ast/replace_eval'
#
# will redefine
# 
#   Kernel#eval
#   Binding#eval
#   BasicObject#instance_eval
#   Module#module_eval
#   Module#class_eval
# 
# When your code encounters one of the syntax limitations imposed by
# binding_of_caller, the following error message will appear:
#
module LiveAST ; EVAL_USAGE_ERROR = %q{

Hello and welcome to the craziness that is eval replacement!

Due to a limitation in tracing events needed to implement
binding_of_caller, the following usage restrictions apply. You are
seeing this message because you violated one of them.

(1) eval cannot appear inside a method call

  foo(1, eval("2 + 3"))   # illegal! eval inside method call

  result = eval("2 + 3")  # OK
  foo(1, result)

(2) eval cannot be the last statement of a block

  1.times do
    eval("1 + 2")  # illegal! eval is last statement in block
  end

  1.times do
    result = eval("1 + 2")  # OK
    result
  end
      
(3) eval cannot be the last statement of an anonymous scope

  eval %{ eval("1 + 2") }  # illegal! last statement of scope

  eval %{ result = eval("1 + 2") ; result }  # OK
  
}
end

require 'continuation'
require 'live_ast'

module LiveAST
  module ArgStack
    SYM = :_live_ast_arg_stack
    
    def push_arg_stack
      Thread.current[SYM] ||= []
      Thread.current[SYM] << {}
    end
    
    def pop_arg_stack
      Thread.current[SYM].pop
    end

    def arg_stack
      Thread.current[SYM] ||= []
      Thread.current[SYM].last
    end
  end

  class << self
    include ArgStack

    def binding_of_caller
      cont = nil
      event_count = 0
      
      tracer = lambda do |event, _, _, _, bind, _|
        event_count += 1
        if event_count == 4
          Thread.current.set_trace_func(nil)
          case event
          when "return", "line", "end"
            cont.call(nil, bind)
          else
            cont.call(nil, nil, lambda { raise EvalUsageError  })
          end
        end
      end
      
      cont, result, error = callcc { |cc| cc }
      if cont
        Thread.current.set_trace_func(tracer)
      elsif result
        yield result
      else
        error.call 
      end
    end
  end

  class EvalUsageError < ScriptError
    def message
      EVAL_USAGE_ERROR
    end
  end
end

module Kernel
  private

  alias_method :live_ast_original_eval, :eval
  def eval(*args)
    remote_self = live_ast_original_eval("self", binding)
    LiveAST.binding_of_caller do |caller_binding|
      remote_self.live_ast_original_instance_eval do
        ast_eval(args[0], args[1] || caller_binding, *args[2..-1])
      end
    end
  end

  class << self
    alias_method :live_ast_original_kernel_singleton_eval, :eval
    def eval(*args)
      string =
        "Kernel.live_ast_original_instance_eval do;" <<
          args[0] <<
        ";end"
      
      remote_self = live_ast_original_eval("self", binding)

      LiveAST.binding_of_caller do |caller_binding|
        remote_self.live_ast_original_instance_eval do
          ast_eval(string, args[1] || caller_binding, *args[2..-1])
        end
      end
    end
  end
end

class Binding
  alias_method :live_ast_original_binding_eval, :eval
  def eval(*args)
    local_self = self
    remote_self = live_ast_original_eval("self", self)
    LiveAST.binding_of_caller do
      remote_self.live_ast_original_instance_eval do
        ast_eval(args[0], local_self, *args[1..-1])
      end
    end
  end
end

class BasicObject
  alias_method :live_ast_original_instance_eval, :instance_eval
  def instance_eval(*args, &block)
    if block
      raise ::ArgumentError unless args.empty?

      live_ast_original_instance_eval(&block)
    else
      raise ::ArgumentError, "block not supplied" if args.empty?

      ::LiveAST.binding_of_caller do |caller_binding|
        ::LiveAST.push_arg_stack
        begin
          ::LiveAST.arg_stack[:self] = self
          ::LiveAST.arg_stack[:args] = args
          string = %{
            ::LiveAST.arg_stack[:self].live_ast_original_instance_eval do
              ast_eval(::LiveAST.arg_stack[:args][0],
                       binding,
                       *::LiveAST.arg_stack[:args][1..-1])
            end
          }
          live_ast_original_eval(string, caller_binding)
        ensure
          ::LiveAST.pop_arg_stack
        end
      end
    end
  end
end

class Module
  alias_method :live_ast_original_module_eval, :module_eval

  #
  # has to be cut & paste due to binding_of_caller
  #
  def module_eval(*args, &block)
    if block
      raise ::ArgumentError unless args.empty?

      live_ast_original_module_eval(&block)
    else
      raise ::ArgumentError, "block not supplied" if args.empty?

      ::LiveAST.binding_of_caller do |caller_binding|
        ::LiveAST.push_arg_stack
        begin
          ::LiveAST.arg_stack[:self] = self
          ::LiveAST.arg_stack[:args] = args
          string = %{
            ::LiveAST.arg_stack[:self].live_ast_original_module_eval do
              ast_eval(::LiveAST.arg_stack[:args][0],
                       binding,
                       *::LiveAST.arg_stack[:args][1..-1])
            end
          }
          live_ast_original_eval(string, caller_binding)
        ensure
          ::LiveAST.pop_arg_stack
        end
      end
    end
  end
  remove_method :class_eval
  alias_method :class_eval, :module_eval
end
