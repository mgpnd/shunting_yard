module ShuntingYard
  class Error < StandardError; end

  class InvalidArgumentsCountError < Error
    def initialize
      super "Invalid arguments count passed to one of functions or operators"
    end
  end

  class MismatchedParenthesesError < Error
    def initialize
      super "Mismatched parentheses"
    end
  end

  class UnknownTokenError < Error
    def initialize(token, position)
      super "Unknown token '#{token}' at position #{position}"
    end
  end

  class UnknownOperatorError < Error
    def initialize(token)
      super "Unknown operator '#{token.lexeme}'"
    end
  end

  class UnknownFunctionError < Error
    def initialize(token)
      super "Unknown function '#{token}'"
    end
  end

  class UnknownParenthesisError < Error
    def initialize(token)
      super "Token '#{token}' is not a parenthesis"
    end
  end

  class UnknownTokenTypeError < Error
    def initialize(name)
      super "Token '#{name}' is not defined"
    end
  end
end
