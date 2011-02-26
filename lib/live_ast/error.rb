module LiveAST
  class MultipleDefinitionsOnSameLineError < ScriptError
    def message
      "AST requested for a method or block that shares a line " <<
      "with another method or block."
    end
  end

  class ASTNotFoundError < StandardError
    def message
      "The requested AST could not be found (AST flushed or compiled code)."
    end
  end

  class RawEvalError < ASTNotFoundError
    def message
      "Must use ast_eval instead of eval in order to obtain AST."
    end
  end
end
