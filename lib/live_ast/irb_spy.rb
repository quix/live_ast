
module LiveAST
  @history = nil

  module IRBSpy
    class << self
      attr_writer :history

      def code_at(line)
        code = ""
        checked_history[line..-1].each do |code_line|
          code << code_line << "\n"
          return code if can_parse code
        end
      end

      def can_parse(code)
        LiveAST.parser.new.parse(code)
      rescue
        false
      end

      def checked_history
        return @history if @history
        raise NotImplementedError,
          "LiveAST cannot access history for this IRB input method"
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
