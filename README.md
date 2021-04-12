# ShuntingYard

## TL;DR Usage

```ruby
parser = ShuntingYard::Parser.new

parser.add_pattern :space, /\s+/, -> (_) { nil }
parser.add_pattern :argument_separator, /\,/
parser.add_pattern :operator, /[\+\-\*\/\^]/
parser.add_pattern :parenthesis, /[\(\)]/
parser.add_pattern :function, /(?:min|max)/
parser.add_pattern :operand, /d+/, -> (lexeme) { Integer(lexeme) }

parser.add_operator "+", 0, :left, -> (left, right) { left + right }
parser.add_operator "-", 0, :left, -> (left, right) { left - right }
parser.add_operator "*", 1, :left, -> (left, right) { left * right }
parser.add_operator "/", 1, :left, -> (left, right) { left / right }
parser.add_operator "^", 2, :right, -> (left, right) { left ** right }

parser.add_function "min", -> (left, right) { [left, right].min }
parser.add_function "max", -> (left, right) { [left, right].max }

input = "min(max(3, 4 / 2) * 2 ^ 3, 25)"

parser.to_rpn(input).to_s #=> 3 4 2 / max 2 3 ^ * 25 min
parser.evaluate(input) #=> 24
```

## Lexer

`ShuntingYard::Lexer` is responsible for splitting source string into tokens.
To recognize each possible token it needs to know corresponding patterns represented as regular expressions.

If substring is matched to multiple patterns, **the first match** will be used.

After matching a token, its lexeme is evaluated with provided function. If function is not provided - it returns the lexeme itself.

Tokens values evaluated to `nil` will not be included into output sequence.

```ruby
lexer = ShuntingYard::Lexer.new

lexer.add_pattern :operator, /\+/
lexer.add_pattern :space, /\s+/, -> (_) { nil }
lexer.add_pattern :operand, /\d+/, -> (lexeme) { Integer(lexeme) }

puts lexer.tokenize("3 + 5").inspect
```

```
[
  #<struct ShuntingYard::Token name=:operand, lexeme="3", value=3>,
  #<struct ShuntingYard::Token name=:operator, lexeme="+", value="+">,
  #<struct ShuntingYard::Token name=:operand, lexeme="5", value=5>
]
```

First argument in `#add_pattern` is a token name. It can have any value since `Lexer` doesn't make assumptions about names.

## Interpterer

Once we have token list, it needs to be converted to [Revese Polish Notation](https://en.wikipedia.org/wiki/Reverse_Polish_notation) before evalutation and here Shunting Yard algorithm comes in.

```ruby
...

interpreter = ShuntingYard::Interpreter.new
interpreter.add_operator "+", 0, :left, -> (left, right) { left + right }

tokens = lexer.tokenize("3 + 5")
puts interpreter.to_rpn(tokens).inspect
```

```
[
  #<struct ShuntingYard::Operand value=3>,
  #<struct ShuntingYard::Operand value=5>,
  #<struct ShuntingYard::Operator value="+", precedence=0, associativity=:left, evaluator=#<Proc:...>>
]
```

Interpreter defines **strict names list that are accepted in tokens**:

* `:operand` - arbitrary value, passed as argument operators and functions
* `:parenthesis` - currently interpreter accepts only "(" and ")" parentheses
* `:operator` - token value must match to one of registered in interpreter operators
* `:function` - token value must match to one of registered in interpreter functions
* `:argument_separator` - pattern that defines argument separation in functions (usually comma)

All other token types will not be recognized and interpreter throws `ShuntingYard::UnknownTokenError`.

### Registering functions

`#add_function(name, evaluator)`

* `name` - function name that must match to corresponding token value
* `evaluator` - a function that accepts fixed number of arguments and returns single value

### Registering operations

`#add_operator(name, precedence, associativity, evaluator)`

* `name` - function name that must match to corresponding token value
* `precedence` - operator precedence, can be any integer value
* `associativity` - [operator associativity](https://en.wikipedia.org/wiki/Operator_associativity), can be either `:left` or `:right`
* `evaluator` - a function that accepts fixed number of arguments and returns single value


### Evaluators

Evaluators for operators and functions can be defined as `proc` or `lambda` with at least one argument.
**Default arguments are not allowed** because interpreter uses `#arity` method to get number of operands required by function / operator.

```ruby
# Expected format
interpreter.add_operator "%", 0, :left, -> (left, right) { left % right }
interpreter.add_operator "~", 0, :left, proc { |left, right| left % right }

# Will not work
interpreter.add_operator "%", 0, :left, -> (left, right = 5) { left % right }
interpreter.add_function "max", -> (*args) { args.max }
```

## Parser

`ShuntingYard::Parser` is a proxy class for Lexer and Interpreter.

When you need to recognize and evaluate an expression in one go, Parser object is a single entry point for all actions.

```ruby
parser = ShuntingYard::Parser.new

# Add patterns to parser's lexer
parser.add_pattern :space, /\s+/, -> (_) { nil }
parser.add_pattern :operator, /[\+\-]/
parser.add_pattern :operand, /d+/, -> (lexeme) { Integer(lexeme) }

# Add operators to parser's interpreter
parser.add_operator "+", 0, :left, -> (left, right) { left + right }
parser.add_operator "-", 0, :left, -> (left, right) { left - right }

input = "5 + 3 - 2"

# Tokenize, convert to RPN and evaluate the expression
parser.evaluate(input) #=> 6
```
