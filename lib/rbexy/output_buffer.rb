require "active_support/core_ext/string/output_safety"

module Rbexy
  class OutputBuffer < ActiveSupport::SafeBuffer
    def <<(content)
      value = content.is_a?(Array) ? content.join.html_safe : content
      super([nil, false].include?(value) ? "" : value.to_s)
    end
  end
end
