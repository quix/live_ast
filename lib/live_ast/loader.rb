module LiveAST
  module Loader
    class << self
      def load(file, wrap)
        file = find_file(file)

        # guards to protect toplevel locals
        header, footer, warnings_ok = header_footer(wrap)
  
        parser_src = Reader.read(file)
        evaler_src = header << parser_src << footer
        
        run = lambda do
          Evaler.eval(parser_src, evaler_src, TOPLEVEL_BINDING, file, 1)
        end
        warnings_ok ? run.call : suppress_warnings(&run)
        true
      end
  
      def header_footer(wrap)
        if wrap
          return "class << Object.new;", ";end", true
        else
          locals = NATIVE_EVAL.call("local_variables", TOPLEVEL_BINDING)
  
          params = locals.empty? ? "" : ("|;" + locals.join(",") + "|")
  
          return "lambda do #{params}", ";end.call", locals.empty?
        end
      end
  
      def suppress_warnings
        previous = $VERBOSE
        $VERBOSE = nil
        begin
          yield
        ensure
          $VERBOSE = previous
        end
      end

      def find_file(file)
        if file.index Linker::REVISION_TOKEN
          raise "refusing to load file with revision token: `#{file}'"
        end
        search_paths(file) or
          raise LoadError, "cannot load such file -- #{file}"
      end

      def search_paths(file)
        return file if File.file? file
        $LOAD_PATH.each do |path|
          target = path + "/" + file
          return target if File.file? target
        end
        nil
      end
    end
  end
end
