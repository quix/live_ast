require 'ruby_parser'
require 'sexp_processor'

module LiveAST
  class Parser < SexpProcessor
    def parse(source)
      @defs = {}
      process RubyParser.new.parse(source)
      @defs
    end

    def process_defn(sexp)
      result = Sexp.new
      result << sexp.shift
      result << sexp.shift
      result << process(sexp.shift)
      result << process(sexp.shift)

      store_sexp(result, sexp.line)
      s()
    end

    def process_iter(sexp)
      line = sexp[1].line

      result = Sexp.new
      result << sexp.shift
      result << process(sexp.shift)
      result << process(sexp.shift)
      result << process(sexp.shift)

      #
      # ruby_parser bug: a method without args attached to a
      # multi-line block reports the wrong line. workaround.
      #
      if result[1][3].size == 1
        line = sexp.line
      end

      store_sexp(result, line)
      s()
    end

    def store_sexp(sexp, line)
      @defs[line] = @defs.has_key?(line) ? :multiple : sexp
    end
  end
end
