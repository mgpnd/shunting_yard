require "strscan"

module ShuntingYard
  class Lexer
    SPACE_OR_EOL = /(\s|$)/.freeze

    attr_accessor :patterns
    attr_accessor :separator_pattern

    def initialize
      @patterns = []
      @separator_pattern = SPACE_OR_EOL
    end

    def add_pattern(name, regex, evaluator = -> (lexeme) { lexeme })
      @patterns << [name, regex, evaluator]
    end

    def tokenize(input)
      sc = StringScanner.new(input)
      matches = []

      until sc.eos?
        last_match = nil

        @patterns.each do |name, regex, evaluator|
          match = sc.check(regex)
          next if match.nil?

          value = evaluator.(match)
          last_match = [name, match, value]
          break
        end

        if last_match.nil?
          unknown_token = sc.check_until(separator_pattern).sub(separator_pattern, "")
          raise UnknownTokenError.new(unknown_token, sc.pos + 1)
        end

        sc.pos += last_match[1].bytesize
        matches << build_token(last_match) unless last_match[2].nil?
      end

      matches
    end

    private

    def build_token(args)
      Token.new(*args)
    end
  end
end
