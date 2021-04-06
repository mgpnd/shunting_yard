require "pry"
require "bigdecimal"
require "shunting_yard"

sy = ShuntingYard::Parser.new

sy.separator_pattern = /(?:\s|$|\,|\(|\))/

sy.add_pattern :space, /\s+/, -> (_) { nil }
sy.add_pattern :argument_separator, /\,/
sy.add_pattern :operator, /[\+\-\*\/\^]/
sy.add_pattern :parenthesis, /[\(\)]/
sy.add_pattern :function, /(?:min|max)/
sy.add_pattern :operand, /\-?(?:0|[1-9]\d*)(?:\.\d+)?/, -> (lexeme) { BigDecimal(lexeme) }
sy.add_pattern :operand, /(\w+)_(\w+)_(\w+)/, -> (lexeme) { 300 }

sy.add_operator "+", 0, :left, -> (left, right) { left + right }
sy.add_operator "-", 0, :left, -> (left, right) { left - right }
sy.add_operator "*", 1, :left, -> (left, right) { left * right }
sy.add_operator "/", 1, :left, -> (left, right) { left / right }
sy.add_operator "^", 2, :right, -> (left, right) { left**right }

sy.add_function "min", -> (left, right) { [left, right].min }
sy.add_function "max", -> (left, right) { [left, right].max }

input = "min(max(3, 4 / 2) * 2 ^ 3, 25)"

puts sy.to_rpn(input).to_s
puts sy.evaluate(input)
