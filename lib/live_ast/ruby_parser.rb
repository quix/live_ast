require 'ruby_parser'
require 'live_ast/base'

class LiveAST::RubyParser
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
    when :defn, :defs, :iter
      store_sexp(sexp, sexp.line)
    end

    sexp.each do |elem|
      process(elem) if elem.is_a? Sexp
    end
  end

  def store_sexp(sexp, line)
    @defs[line] = @defs.has_key?(line) ? :multiple : sexp
  end
end

LiveAST::RubyParser.autoload :Unparser, 'live_ast/ruby_parser/unparser'
LiveAST::RubyParser.autoload :Test, 'live_ast/ruby_parser/test'

LiveAST.parser = LiveAST::RubyParser
