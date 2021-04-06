require "spec_helper"

RSpec.describe ShuntingYard::Interpreter do
  def token(*args)
    ShuntingYard::Token.new(*args)
  end

  def operand(value)
    ShuntingYard::Operand.new(value)
  end

  def operator(name)
    operators[name]
  end

  def function(name)
    functions[name]
  end

  let(:interpreter) { described_class.new }

  let(:operators) { {
    "+" => ShuntingYard::Operator.new("+", 0, :left, -> (left, right) { left + right}),
    "-" => ShuntingYard::Operator.new("-", 0, :left, -> (left, right) { left - right}),
    "*" => ShuntingYard::Operator.new("*", 1, :left, -> (left, right) { left * right }),
    "/" => ShuntingYard::Operator.new("/", 1, :left, -> (left, right) { left / right }),
    "^" => ShuntingYard::Operator.new("^", 2, :left, -> (left, right) { left**right }),
  } }

  let(:functions) { {
    "min" => ShuntingYard::Function.new("min", -> (left, right) { [left, right].min }),
    "max" => ShuntingYard::Function.new("max", -> (left, right) { [left, right].max }),
  } }

  before do
    interpreter.operators = operators.values
    interpreter.functions = functions.values
  end

  describe "#to_rpn" do
    subject(:to_rpn) { interpreter.to_rpn(tokens) }

    context "when next operator precedence is higher than current" do
      let(:tokens) {[
        token(:operand, "3", 3),
        token(:operator, "+", "+"),
        token(:operand, "5", 5),
        token(:operator, "*", "*"),
        token(:operand, "2", 2),
      ]}

      it "pushes higher precedence operator first" do
        expect(to_rpn.to_s).to eq("3 5 2 * +")
        expect(to_rpn).to eq([operand(3), operand(5), operand(2), operator("*"), operator("+")])
      end
    end

    context "when next operator precedence is higher than current but current wrapped into parenthesis" do
      let(:tokens) {[
        token(:parenthesis, "(", "("),
        token(:operand, "3", 3),
        token(:operator, "+", "+"),
        token(:operand, "5", 5),
        token(:parenthesis, ")", ")"),
        token(:operator, "*", "*"),
        token(:operand, "2", 2),
      ]}

      it "pushes wrapped operator first" do
        expect(to_rpn.to_s).to eq("3 5 + 2 *")
        expect(to_rpn).to eq([operand(3), operand(5), operator("+"), operand(2), operator("*")])
      end
    end

    context "when next operator precedence is equal to current and next operator is left associative" do
      let(:tokens) {[
        token(:operand, "3", 3),
        token(:operator, "+", "+"),
        token(:operand, "5", 5),
        token(:operator, "-", "-"),
        token(:operand, "8", 8),
      ]}

      it "pushes operators in defined order" do
        expect(to_rpn.to_s).to eq("3 5 + 8 -")
        expect(to_rpn).to eq([operand(3), operand(5), operator("+"), operand(8), operator("-")])
      end
    end

    context "when next operator precedence is equal to current and next operator is right associative" do
      let(:tokens) {[
        token(:operand, "3", 3),
        token(:operator, "+", "+"),
        token(:operand, "5", 5),
        token(:operator, "^", "^"),
        token(:operand, "2", 2),
      ]}

      it "pushes right associative operator first" do
        expect(to_rpn.to_s).to eq("3 5 2 ^ +")
        expect(to_rpn).to eq([operand(3), operand(5), operand(2), operator("^"), operator("+")])
      end
    end

    context "when input has function with two arguments" do
      let(:tokens) {[
        token(:function, "min", "min"),
        token(:parenthesis, "(", "("),
        token(:operand, "5", 5),
        token(:argument_separator, ",", ","),
        token(:operand, "4", 4),
        token(:parenthesis, ")", ")"),
      ]}

      it "pushes function call after arguments" do
        expect(to_rpn.to_s).to eq("5 4 min")
        expect(to_rpn).to eq([operand(5), operand(4), function("min")])
      end
    end

    context "when input has function with expression as first argument" do
      let(:tokens) {[
        token(:function, "min", "min"),
        token(:parenthesis, "(", "("),
        token(:operand, "5", 5),
        token(:operator, "*", "*"),
        token(:operand, "2", 2),
        token(:argument_separator, ",", ","),
        token(:operand, "4", 4),
        token(:parenthesis, ")", ")"),
      ]}

      it "pushes argument calculation before function call" do
        expect(to_rpn.to_s).to eq("5 2 * 4 min")
        expect(to_rpn).to eq([operand(5), operand(2), operator("*"), operand(4), function("min")])
      end
    end

    context "when input has function with expression as second argument" do
      let(:tokens) {[
        token(:function, "min", "min"),
        token(:parenthesis, "(", "("),
        token(:operand, "5", 5),
        token(:argument_separator, ",", ","),
        token(:operand, "4", 4),
        token(:operator, "*", "*"),
        token(:operand, "2", 2),
        token(:parenthesis, ")", ")"),
      ]}

      it "pushes argument calculation before function call" do
        expect(to_rpn.to_s).to eq("5 4 2 * min")
        expect(to_rpn).to eq([operand(5), operand(4), operand(2), operator("*"), function("min")])
      end
    end

    context "when input has extra left parenthesis" do
      let("tokens") {[
        token(:parenthesis, "(", "("),
        token(:operand, "3", 3),
        token(:operator, "+", "+"),
        token(:operand, "5", 5),
      ]}

      it "throws MismatchedParenthesesError" do
        expect { to_rpn }.to raise_error(ShuntingYard::MismatchedParenthesesError)
      end
    end

    context "when input has extra right parenthesis" do
      let("tokens") {[
        token(:operand, "3", 3),
        token(:operator, "+", "+"),
        token(:operand, "5", 5),
        token(:parenthesis, ")", ")"),
      ]}

      it "throws MismatchedParenthesesError" do
        expect { to_rpn }.to raise_error(ShuntingYard::MismatchedParenthesesError)
      end
    end

    context "when input has unregistered operator" do
      let("tokens") {[
        token(:operand, "3", 3),
        token(:operator, "div", "div"),
        token(:operand, "5", 5),
      ]}

      it "throws UnknownOperatorError" do
        expect { to_rpn }.to raise_error(ShuntingYard::UnknownOperatorError)
      end
    end

    context "when input has unregistered function" do
      let("tokens") {[
        token(:function, "sin", "sin"),
        token(:parenthesis, "(", "("),
        token(:operand, "0", 0),
        token(:parenthesis, ")", ")"),
      ]}

      it "throws UnknownFunctionError" do
        expect { to_rpn }.to raise_error(ShuntingYard::UnknownFunctionError)
      end
    end

    context "when input has not supported parenthesis" do
      let("tokens") {[
        token(:parenthesis, "{", "{"),
        token(:operand, "3", 3),
        token(:operator, "div", "div"),
        token(:operand, "5", 5),
        token(:parenthesis, "}", "}"),
      ]}

      it "throws UnknownParenthesisError" do
        expect { to_rpn }.to raise_error(ShuntingYard::UnknownParenthesisError)
      end
    end

    context "when input has not supported token type" do
      let("tokens") { [token(:random, "x", "x")] }

      it "throws UnknownTokenTypeError" do
        expect { to_rpn }.to raise_error(ShuntingYard::UnknownTokenTypeError)
      end
    end
  end

  describe "#evaluate" do
    subject(:evaluate) { interpreter.evaluate(tokens) }

    context "when opearands count is correct" do
      let(:tokens) {[
        operand(2),
        operand(5),
        operand(3),
        operator("*"),
        operator("+"),
      ]}

      it "evaluates expression and retuns its result" do
        expect(evaluate).to eq(17)
      end
    end

    context "when extra operand provided" do
      let(:tokens) {[
        operand(1),
        operand(2),
        operand(5),
        operand(3),
        operator("*"),
        operator("+"),
      ]}

      it "throws InvalidArgumentsCountError" do
        expect { evaluate }.to raise_error(ShuntingYard::InvalidArgumentsCountError)
      end
    end

    context "when not enough operands provided" do
      let(:tokens) {[
        operand(5),
        operand(3),
        operator("*"),
        operator("+"),
      ]}

      it "throws InvalidArgumentsCountError" do
        expect { evaluate }.to raise_error(ShuntingYard::InvalidArgumentsCountError)
      end
    end
  end
end
