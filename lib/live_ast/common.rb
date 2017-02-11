
module LiveAST
  module Common
    module_function

    def arg_to_str(arg)
      arg.to_str
    rescue NameError
      thing = arg.nil? ? nil : arg.class

      message = if RUBY_VERSION < "2.0.0"
                  "can't convert #{thing.inspect} into String"
                else
                  "no implicit conversion of #{thing.inspect} into String"
                end
      raise TypeError, message
    end

    def check_arity(args, range)
      return if range.include? args.size

      range = 0 if range == (0..0)

      message = if RUBY_VERSION < "2.3.0"
                  "wrong number of arguments (#{args.size} for #{range})"
                else
                  "wrong number of arguments (given #{args.size}, expected #{range})"
                end
      raise ArgumentError, message
    end

    def check_is_binding(obj)
      return if obj.is_a? Binding
      message = if RUBY_VERSION < "2.1.0"
                  "wrong argument type #{obj.class} (expected Binding)"
                else
                  "wrong argument type #{obj.class} (expected binding)"
                end
      raise TypeError, message
    end

    def location_for_eval(*args)
      bind, *location = args

      if bind
        case location.size
        when 0
          NATIVE_EVAL.call("[__FILE__, __LINE__]", bind)
        when 1
          [location.first, 1]
        else
          location
        end
      else
        ["(eval)", 1]
      end
    end
  end
end
