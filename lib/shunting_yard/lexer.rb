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
        match = nil
        last_match = nil
        longest_match_size = 0

        @patterns.each do |name, regex, evaluator|
          match = sc.check(regex)
          next if match.nil?

          longest_match_size = [longest_match_size, match.size].max

          value = evaluator.(match)
          next if value.nil?

          last_match = [name, match, value] if last_match.nil? || last_match[1].size < match.size
        end

        if longest_match_size == 0
          unknown_token = sc.check_until(separator_pattern).sub(separator_pattern, "")
          raise UnknownTokenError.new(unknown_token, sc.pos + 1)
        end

        sc.pos += longest_match_size
        matches << build_token(last_match) unless last_match.nil?
      end

      matches
    end

    private

    def build_token(args)
      Token.new(*args)
    end
  end
end
