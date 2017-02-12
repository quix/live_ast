module LiveAST
  module Evaler
    class << self
      include Common

      def eval(parser_source, *args)
        evaler_source, bind, *rest = handle_args(*args)

        file, line = location_for_eval(bind, *rest)
        file = LiveAST.strip_token(file)

        key, = Linker.new_cache_synced(parser_source, file, line, false)

        begin
          NATIVE_EVAL.call(evaler_source, bind, key, line)
        rescue Exception => ex
          ex.backtrace.map! { |s| LiveAST.strip_token s }
          raise ex
        end
      end

      def handle_args(*args)
        args.tap do
          check_arity(args, 2..4)
          args[0] = arg_to_str(args[0])
          check_is_binding(args[1])
          args[2] = arg_to_str(args[2]) if args[2]
        end
      end
    end
  end
end
