require 'ruby_parser'
require 'live_ast/base'

class LiveASTRubyParser
  #
  # Returns a line-to-sexp hash where sexp corresponds to the method
  # or block defined at the given line.
  #
  # This method is the only requirement of a LiveAST parser plugin.
  #
  def parse(source)
    @defs = {}
    process RubyParser.new.parse(source)
    @defs
  end

  def process(sexp)
    case sexp.first
    when :defn, :defs
      store_sexp(sexp, sexp.line)
    when :iter
      #
      # ruby_parser bug: a method without args attached to a
      # multi-line block reports the wrong line. workaround.
      #
      # http://rubyforge.org/tracker/index.php?func=detail&aid=28940&group_id=439&atid=1778
      #
      store_sexp(sexp, sexp[1][3].size == 1 ? sexp.line : sexp[1].line)
    end

    sexp.each do |elem|
      process(elem) if elem.is_a? Sexp
    end
  end

  def store_sexp(sexp, line)
    @defs[line] = @defs.has_key?(line) ? :multiple : sexp
  end
end

LiveASTRubyParser.autoload :Unparser, 'live_ast_ruby_parser/unparser'
LiveASTRubyParser.autoload :Test, 'live_ast_ruby_parser/test'

LiveAST.parser = LiveASTRubyParser
