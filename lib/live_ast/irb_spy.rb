
module LiveAST
  module IRBSpy
    def self.code_at(line)
      unless defined?(@history)
        raise NotImplementedError,
        "LiveAST cannot access history for this IRB input method"
      end
      grow = 0
      begin
        code = @history[line..(line + grow)].join
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

[
 IRB::StdioInputMethod,
 defined?(IRB::ReadlineInputMethod) ? IRB::ReadlineInputMethod : nil,
].compact.each do |klass|
  klass.module_eval do
    alias_method :live_ast_original_gets, :gets
    def gets
      live_ast_original_gets.tap do
        if defined?(@line)
          LiveAST::IRBSpy.instance_variable_set(:@history, @line)
        end
      end
    end
  end
end
