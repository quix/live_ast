module LiveAST
  module Evaler
    class << self
      def eval(parser_source, *args)
        evaler_source, bind, *location = handle_args(*args)

        file, line = handle_location(bind, *location)
        file = Linker.strip_token(file)

        key, _ = Linker.new_cache_synced(parser_source, file, line, false)

        begin
          NATIVE_EVAL.call(evaler_source, bind, key, line)
        rescue Exception => ex
          fix_backtrace(ex.backtrace)
          raise ex
        end
      end

      #
      # match eval's error messages
      #
      def handle_args(*args)
        unless (2..4).include? args.size
          raise ArgumentError,
          "wrong number of arguments (#{args.size} for 2..4)"
        end
        unless args[1].is_a? Binding
          raise TypeError,
          "wrong argument type #{args[1].class} (expected Binding)"
        end
        args[0] = arg_to_str(args[0])
        args[2] = arg_to_str(args[2]) unless args[2].nil?
        args
      end

      def arg_to_str(arg)
        begin
          arg.to_str
        rescue
          raise TypeError, "can't convert #{arg.class} into String"
        end
      end

      #
      # match eval's behavior
      #
      def handle_location(bind, *location)
        case location.size
        when 0
          NATIVE_EVAL.call("[__FILE__, __LINE__]", bind)
        when 1
          [location.first, 1]
        else
          location
        end
      end

      def fix_backtrace(backtrace)
        backtrace.map! { |line|
          LiveAST::Linker.strip_token line
        }
      end
    end
  end
end
