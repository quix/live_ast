module LiveAST
  class Cache
    Node = Struct.new(:source, :user_line, :asts)

    def initialize(*args)
      @node = Node.new(*args)
    end

    def fetch_ast(line)
      if @node == :flushed
        :flushed
      else
        @node.asts ||= Parser.new.parse(@node.source).tap do
          @node.source = nil
        end
        @node.asts.delete(line - @node.user_line + 1)
      end
    end

    def flush
      @node = :flushed
    end
  end
end
