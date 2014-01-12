
#
# Used by the LiveAST test suite.
#
module LiveAST::RubyParser::Test
  class << self
    #
    # Whether this is Ryan Davis's unified sexp format.
    #
    def unified_sexp?
      true
    end

    #
    # Whether the unparser output matches that of ruby2ruby.
    #
    def unparser_matches_ruby2ruby?
      true
    end
  end

  #
  # no_arg_def(:f, "A#f") returns the ast of
  #
  #   def f
  #     "A#f"
  #   end
  #
  def no_arg_def(name, ret)
    s(:defn, name, s(:args), s(:scope, s(:block, s(:str, ret))))
  end

  #
  # singleton_no_arg_def(:f, "foo") returns the ast of
  #
  #   def self.f
  #     "foo"
  #   end
  #
  def singleton_no_arg_def(name, ret)
    s(:defs, s(:self), name, s(:args), s(:scope, s(:block, s(:str, ret))))
  end

  #
  # no_arg_def_return(no_arg_def(:f, "A#f")) == "A#f"
  #
  def no_arg_def_return(ast)
    ast[3][1][1][1]
  end

  #
  # binop_def(:f, :+) returns the ast of
  #
  #   def f(x, y)
  #     x + y
  #   end
  #
  def binop_def(name, op)
    s(:defn,
      name,
      s(:args, :x, :y),
      s(:scope,
        s(:block, s(:call, s(:lvar, :x), op, s(:arglist, s(:lvar, :y))))))
  end

  #
  # singleton_binop_def(:A, :f, :+) returns the ast of
  #
  #   def A.f(x, y)
  #     x + y
  #   end
  #
  def singleton_binop_def(const, name, op)
    s(:defs,
      s(:const, const),
      name,
      s(:args, :x, :y),
      s(:scope,
        s(:block, s(:call, s(:lvar, :x), op, s(:arglist, s(:lvar, :y))))))
  end

  #
  # binop_define_method(:f, :*) returns the ast of
  #
  #   define_method :f do |x, y|
  #     x * y
  #   end
  #
  # binop_define_method(:f, :-, :my_def) returns the ast of
  #
  #   my_def :f do |x, y|
  #     x - y
  #   end
  #
  def binop_define_method(name, op, using = :define_method)
    s(:iter,
      s(:call, nil, using, s(:arglist, s(:lit, name))),
      s(:masgn, s(:array, s(:lasgn, :x), s(:lasgn, :y))),
      s(:call, s(:lvar, :x), op, s(:arglist, s(:lvar, :y))))
  end

  #
  # binop_define_method_with_var(:method_name, :/) returns the ast of
  #
  #   define_method method_name do |x, y|
  #     x / y
  #   end
  #
  def binop_define_method_with_var(var_name, op)
    s(:iter,
      s(:call, nil, :define_method, s(:arglist, s(:lvar, var_name))),
      s(:masgn, s(:array, s(:lasgn, :x), s(:lasgn, :y))),
      s(:call, s(:lvar, :x), op, s(:arglist, s(:lvar, :y))))
  end

  #
  # binop_define_singleton_method(:f, :+, :a) returns the ast of
  #
  #   a.define_singleton_method :f do |x, y|
  #     x + y
  #   end
  #
  def binop_define_singleton_method(name, op, receiver)
    s(:iter,
      s(:call, s(:lvar, receiver), :define_singleton_method,
        s(:arglist, s(:lit, name))),
      s(:masgn, s(:array, s(:lasgn, :x), s(:lasgn, :y))),
      s(:call, s(:lvar, :x), op, s(:arglist, s(:lvar, :y))))
  end
  
  #
  # no_arg_block(:foo, "bar") returns the ast of
  #
  #   foo { "bar" }
  #
  def no_arg_block(name, ret)
    s(:iter, s(:call, nil, name, s(:arglist)), nil, s(:str, ret))
  end
  
  #
  # binop_block(:foo, :+) returns the ast of
  #
  #   foo { |x, y| x + y }
  #
  def binop_block(name, op)
    s(:iter,
      s(:call, nil, name, s(:arglist)),
      s(:masgn, s(:array, s(:lasgn, :x), s(:lasgn, :y))),
      s(:call, s(:lvar, :x), op, s(:arglist, s(:lvar, :y))))
  end

  #
  # binop_proc_new(:*) returns the ast of
  #
  #   Proc.new { |x, y| x * y }
  #
  def binop_proc_new(op)
    s(:iter,
      s(:call, s(:const, :Proc), :new, s(:arglist)),
      s(:masgn, s(:array, s(:lasgn, :x), s(:lasgn, :y))),
      s(:call, s(:lvar, :x), op, s(:arglist, s(:lvar, :y))))
  end

  #
  # nested_lambdas("foo") returns the ast of
  #
  #   lambda {
  #     lambda {
  #       "foo"
  #     }
  #   }
  #  
  def nested_lambdas(str)
    s(:iter,
      s(:call, nil, :lambda, s(:arglist)),
      nil,
      s(:iter, s(:call, nil, :lambda, s(:arglist)), nil, s(:str, str)))
  end

  # nested_defs(:f, :g, "foo") returns the ast of
  #
  #   def f
  #     Class.new do
  #       def g
  #         "foo"
  #       end
  #     end
  #   end
  #   
  def nested_defs(u, v, str)
    s(:defn,
      u,
      s(:args),
      s(:scope,
        s(:block,
          s(:iter,
            s(:call, s(:const, :Class), :new, s(:arglist)),
            nil,
            s(:defn, v, s(:args), s(:scope, s(:block, s(:str, str))))))))
  end
end
