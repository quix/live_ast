require 'ruby2ruby'

#
# Used by +to_ruby+ in LiveAST.
#
module LiveAST
  class RubyParser
    module Unparser
      #
      # Return a ruby source string which reflects the given AST.
      #
      def self.unparse(sexp)
        ::Ruby2Ruby.new.process(clone_sexp(sexp))
      end

      def self.clone_sexp(sexp)
        sexp.clone.map! do |elem|
          case elem
          when Sexp
            clone_sexp(elem)
          else
            elem
          end
        end
      end
    end
  end
end
