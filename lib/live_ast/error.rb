module LiveAST
  class MultipleDefinitionsOnSameLineError < ScriptError
    def message
      "AST requested for a method or block that shares a line " <<
      "with another method or block."
    end
  end

  class ASTNotFoundError < StandardError
  end

  class RawEvalError < ASTNotFoundError
    def message
      "Must use ast_eval instead of eval in order to obtain AST."
    end
  end
  
  class NoSourceError < ASTNotFoundError
    def message
      "No source found for the requested AST."
    end
  end

  class FlushedError < ASTNotFoundError
    def message
      "The requested AST was flushed from the cache."
    end
  end
end
