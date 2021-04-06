module ShuntingYard
  Token = Struct.new(:name, :lexeme, :value)

  # Matched tokens
  ArgumentSeparator = Struct.new(:value)
  Function = Struct.new(:value, :evaluator)
  Operand = Struct.new(:value)
  Operator = Struct.new(:value, :precedence, :associativity, :evaluator)
  Parenthesis = Struct.new(:side)
end
