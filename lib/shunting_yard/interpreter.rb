module ShuntingYard
  class Interpreter
    attr_accessor :functions
    attr_accessor :operators

    def initialize
      @functions = []
      @operators = []
    end

    def add_function(*args)
      functions << Function.new(*args)
    end

    def add_operator(*args)
      operators << Operator.new(*args)
    end

    def to_rpn(source_tokens)
      tokens = source_tokens.dup
      output = ReversePolishNotation.new
      op_stack = []

      while tokens.any?
        current = match_token(tokens.shift)

        case current
        when ArgumentSeparator
          while op_stack.any? &&
                op_stack.last.class != Parenthesis
            output << op_stack.pop
          end
        when Function
          op_stack << current
        when Parenthesis
          case current.side
          when :left
            op_stack << current
          when :right
            while op_stack.last.class != Parenthesis
              raise MismatchedParenthesesError if op_stack.empty?

              output << op_stack.pop
            end

            op_stack.pop
          end
        when Operand
          output << current
        when Operator
          while op_stack.any? &&
                op_stack.last.class != Parenthesis &&
                (op_stack.last.class == Function ||
                  op_stack.last.precedence > current.precedence ||
                  op_stack.last.precedence == current.precedence && current.associativity == :left)
            output << op_stack.pop
          end

          op_stack << current
        end
      end

      while op_stack.any?
        current = op_stack.pop
        raise MismatchedParenthesesError if current.class == Parenthesis

        output << current
      end

      output
    end

    def evaluate(rpn_tokens)
      rpn = rpn_tokens.dup
      stack = []

      while rpn.any?
        current = rpn.shift

        case current
        when Function, Operator
          arity = current.evaluator.arity
          raise InvalidArgumentsCountError if stack.size < arity

          operands = stack.pop(arity)
          stack << current.evaluator.(*operands)
        when Operand
          stack << current.value
        end
      end

      raise InvalidArgumentsCountError if stack.size > 1

      stack[0]
    end

    private

    def match_token(token)
      matched =
        case token.name
        when :argument_separator
          ArgumentSeparator.new(token.value)
        when :function
          function = functions.find { |f| f.value == token.value }
          raise UnknownFunctionError, token.lexeme unless function

          function
        when :parenthesis
          case token.value
          when "("
            Parenthesis.new(:left)
          when ")"
            Parenthesis.new(:right)
          else
            raise UnknownParenthesisError, token.lexeme
          end
        when :operand
          Operand.new(token.value)
        when :operator
          operator = operators.find { |op| binding.pry if op.kind_of?(Array); op.value == token.value }
          raise UnknownOperatorError, token unless operator

          operator
        else
          raise UnknownTokenTypeError, token.name
        end

      matched
    end
  end
end
