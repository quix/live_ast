#
# Some hacks to get LiveAST working with IRB.
#
# (1) Because Readline::HISTORY is empty at startup, we count the
# lines of the history file in order to determine where the new
# history begins for this IRB session.
#
# (2) IRB::ReadlineInputMethod#gets discards empty input lines,
# causing Readline::HISTORY to be out of sync with the current line
# number, thereby fouling up source_location. We redefine #gets to
# keep empty lines.
#

module LiveAST
  module IRBSpy
    class << self
      def code_at(line)
        history = Readline::HISTORY.to_a
        start = @history_start + line - 1
        grow = 0
        begin
          code = history[start..(start + grow)].join("\n")
          LiveAST.parser.new.parse(code) or raise "#{LiveAST.parser} error"
        rescue
          grow += 1
          retry if start + grow < history.size
          raise
        end
        code
      end

      #
      # Find the starting point of history for this IRB session.
      #
      def find_history_start
        if IRB.conf[:HISTORY_FILE]
          # cut & paste from irb/ext/save-history.rb
          if history_file = IRB.conf[:HISTORY_FILE]
            history_file = File.expand_path(history_file)
          end
          history_file = IRB.rc_file("_history") unless history_file
          
          if File.exist?(history_file)
            File.readlines(history_file).size
          else
            0
          end
        else
          0
        end
      end
    end

    @history_start = find_history_start
  end
end

#
# From irb/input-method.rb.
#
class IRB::ReadlineInputMethod
  alias_method :live_ast_original_gets, :gets
  def gets
    Readline.input = @stdin
    Readline.output = @stdout
    if l = readline(@prompt, false)
      HISTORY.push(l) #if !l.empty?  # <---- only this line modified
      @line[@line_no += 1] = l + "\n"
    else
      @eof = true
      l
    end
  end
end
