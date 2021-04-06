require "forwardable"

module ShuntingYard
  class Parser
    extend Forwardable

    attr_accessor :lexer
    attr_accessor :interpreter

    def initialize(lexer: nil, interpreter: nil)
      @lexer = lexer || Lexer.new
      @interpreter = interpreter || Interpreter.new
    end

    def_delegators :@lexer, :add_pattern, :separator_pattern, :separator_pattern=, :tokenize
    def_delegators :@interpreter, :add_function, :add_operator

    def evaluate(input)
      rpn_tokens = to_rpn(input)
      interpreter.evaluate(rpn_tokens)
    end

    def to_rpn(input)
      tokens = tokenize(input)
      interpreter.to_rpn(tokens)
    end
  end
end
