module Rbexy
  module ViewContextHelper
    def rbexy_tag
      @rbexy_tag ||= Runtime.create_tag_builder(self)
    end

    def rbexy_context
      @rbexy_context ||= [{}]
    end

    def rbexy_prep_output(*content)
      return if content.length == 0
      content = content.first

      value = content.is_a?(Array) ? content.join.html_safe : content
      [nil, false].include?(value) ? "" : value.to_s
    end
  end
end
