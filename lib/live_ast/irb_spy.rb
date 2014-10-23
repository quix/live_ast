
module LiveAST
  @history = nil

  module IRBSpy
    class << self
      attr_writer :history

      def code_at(line)
        unless @history
          raise NotImplementedError,
            "LiveAST cannot access history for this IRB input method"
        end
        grow = 0
        begin
          code = @history[line..(line + grow)].join("\n")
          LiveAST.parser.new.parse(code) or raise "#{LiveAST.parser} error"
        rescue
          grow += 1
          retry if line + grow < @history.size
          raise
        end
        code
      end
    end
  end
end

[
  defined?(IRB::StdioInputMethod) ? IRB::StdioInputMethod : nil,
  defined?(IRB::ReadlineInputMethod) ? IRB::ReadlineInputMethod : nil,
].compact.each do |klass|
  klass.module_eval do
    alias_method :live_ast_original_gets, :gets
    def gets
      live_ast_original_gets.tap do
        LiveAST::IRBSpy.history = @line if defined?(@line)
      end
    end
  end
end
