module Rbexy
  module ViewContextHelper
    def rbexy_tag
      @rbexy_tag ||= Runtime.create_tag_builder(self)
    end

    def rbexy_context
      @rbexy_context ||= [{}]
    end

    def rbexy_prep_output(*value)
      return if value.length == 0
      value = value.first

      value = rbexy_is_html_safe_array?(value) ? value.join.html_safe : value
      [nil, false].include?(value) ? "" : value.to_s
    end

    def rbexy_is_html_safe_array?(value)
      value.is_a?(Array) && value.all? { |v| v.respond_to?(:html_safe?) && v.html_safe? }
    end
  end
end
