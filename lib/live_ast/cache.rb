module LiveAST
  class Cache
    def initialize(*args)
      @source, @user_line, @asts = args
    end

    def fetch_ast(line)
      @asts ||= Parser.new.parse(@source).tap do
        @source = nil
      end
      @asts.delete(line - @user_line + 1)
    end
  end
end
