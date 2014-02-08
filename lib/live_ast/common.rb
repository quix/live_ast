
module LiveAST
  module Common
    module_function
    
    def arg_to_str(arg)
      begin
        arg.to_str
      rescue NameError
        thing = if arg.nil? then nil else arg.class end

        raise TypeError,
          RUBY_VERSION < "2.0.0" ?
          "can't convert #{thing.inspect} into String" :
          "no implicit conversion of #{thing.inspect} into String"
      end
    end

    def check_arity(args, range)
      unless range.include? args.size
        range = 0 if range == (0..0)

        raise ArgumentError,
        "wrong number of arguments (#{args.size} for #{range})"
      end
    end

    def check_type(obj, klass)
      unless obj.is_a? klass
        raise TypeError, "wrong argument type #{obj.class} (expected #{klass})"
      end
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
