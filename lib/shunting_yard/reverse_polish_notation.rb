module ShuntingYard
  class ReversePolishNotation < Array
    def to_s
      self.map(&:value).join(" ")
    end
  end
end
