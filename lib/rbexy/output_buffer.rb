module Rbexy
  class OutputBuffer < String
    def <<(content)
      value = content.is_a?(Array) ? content.join : content
      super([nil, false].include?(value) ? "" : value.to_s)
    end
  end
end
