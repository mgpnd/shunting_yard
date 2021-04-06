require "spec_helper"

RSpec.describe ShuntingYard::Lexer do
  def token(*args)
    ShuntingYard::Token.new(*args)
  end

  let(:lexer) { described_class.new }

  describe "#tokenize" do
    subject(:tokenize) { lexer.tokenize(input) }

    let(:input) { "3+4" }

    before do
      lexer.add_pattern :space, /\s+/, -> (_) { nil }
      lexer.add_pattern :operand, /-?\d+/
      lexer.add_pattern :operator, /\+/
    end

    it "returns tokens in provided order" do
      expect(lexer.tokenize("3+4")).to eq([
        token(:operand, "3", "3"),
        token(:operator, "+", "+"),
        token(:operand, "4", "4")
      ])
    end

    it "recognizes multiple patterns of the same type registered separately" do
      lexer.add_pattern :operator, /\//

      expect(lexer.tokenize("+/")).to include(
        token(:operator, "+", "+"),
        token(:operator, "/", "/")
      )
    end

    it "recognizes the longest match for ambiguous pattern" do
      expect(lexer.tokenize("-32+3")).to include(token(:operand, "-32", "-32"))
    end

    it "evaluates token value" do
      lexer.add_pattern :operand, /\d+\.\d+/, ->(l) { Float(l) }

      expect(lexer.tokenize("3.4")).to include(token(:operand, "3.4", 3.4))
    end

    it "excludes tokens with nil value" do
      expect(lexer.tokenize("5 + 2")).not_to include(token(:space, " ", nil))
    end

    context "when input contains not registered token" do
      let(:input) { "max(5 + 2, 6)" }

      context "when custom separator pattern is not registered" do
        it "puts string from current position to next space or EOL into error message" do
          expect { tokenize }.to raise_error(
            ShuntingYard::UnknownTokenError,
            "Unknown token 'max(5' at position 1"
          )
        end
      end

      context "when custom separator pattern is registered" do
        before do
          lexer.separator_pattern = /(?:\s|\(|\))/
        end

        it "puts string from current position to the closest separator into error message" do
          expect { tokenize }.to raise_error(
            ShuntingYard::UnknownTokenError,
            "Unknown token 'max' at position 1"
          )
        end
      end
    end
  end
end
