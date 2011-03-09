module LiveAST
  class Cache
    def initialize(*args)
      @source, @user_line = args
      @asts = nil
    end

    def fetch_ast(line)
      @asts ||= LiveAST.parser.new.parse(@source).tap do
        @source = nil
      end
      @asts.delete(line - @user_line + 1)
    end
  end

  module Attacher
    VAR_NAME = :@_live_ast
      
    def attach_to_proc(obj, ast)
      obj.instance_variable_set(VAR_NAME, ast)
    end
    
    def fetch_proc_attachment(obj)
      if obj.instance_variable_defined?(VAR_NAME)
        obj.instance_variable_get(VAR_NAME)
      end
    end
    
    def attach_to_method(klass, method, ast)
      unless klass.instance_variable_defined?(VAR_NAME)
        klass.instance_variable_set(VAR_NAME, {})
      end
      klass.instance_variable_get(VAR_NAME)[method] = ast
    end
    
    def fetch_method_attachment(klass, method)
      if klass.instance_variable_defined?(VAR_NAME)
        klass.instance_variable_get(VAR_NAME)[method]
      end
    end
  end
    
  module Linker
    REVISION_TOKEN = "|ast@"

    @caches = {}
    @counter = "a"
    @mutex = Mutex.new

    class << self
      include Attacher

      def find_proc_ast(obj)
        @mutex.synchronize do
          fetch_proc_attachment(obj) or (
            ast = find_ast(*obj.source_location) or raise ASTNotFoundError
            attach_to_proc(obj, ast)
          )
        end
      end

      def find_method_ast(klass, name, *location)
        @mutex.synchronize do
          case ast = find_ast(*location)
          when nil
            fetch_method_attachment(klass, name) or raise ASTNotFoundError
          else
            attach_to_method(klass, name, ast)
          end
        end
      end

      def find_ast(*location)
        raise ASTNotFoundError unless location.size == 2
        raise RawEvalError if location.first == "(eval)"
        ast = fetch_from_cache(*location)
        raise MultipleDefinitionsOnSameLineError if ast == :multiple
        ast
      end

      def fetch_from_cache(file, line)
        cache = @caches[file]
        if !cache and !file.index(REVISION_TOKEN)
          _, cache =
            if defined?(IRB) and file == "(irb)"
              new_cache(IRBSpy.code_at(line), file, line, false)
            else
              #
              # File was loaded by 'require'.
              # Play catch-up: assume it has not changed in the meantime.
              #
              new_cache(Reader.read(file), file, 1, true)
            end
        end
        cache.fetch_ast(line) if cache
      end

      #
      # create a cache along with a unique key for it
      #
      def new_cache(contents, file, user_line, file_is_key)
        key = file_is_key ? file : file + REVISION_TOKEN + @counter
        cache = Cache.new(contents, user_line)
        @caches[key] = cache
        @counter.next!
        return key, cache
      end

      def new_cache_synced(*args)
        @mutex.synchronize do
          new_cache(*args)
        end
      end

      def flush_cache
        @mutex.synchronize do
          @caches.delete_if { |key, _| key.index REVISION_TOKEN }
        end
      end

      def strip_token(file)
        file.sub(/#{Regexp.quote REVISION_TOKEN}[a-z]+/, "")
      end
    end
  end
end
