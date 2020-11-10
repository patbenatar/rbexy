module Rbexy
  module ViewContextHelper
    def rbexy_tag
      @rbexy_tag ||= Runtime.create_tag_builder(self)
    end

    def rbexy_context
      @rbexy_context ||= [{}]
    end

    # TODO: this might be an html-injection vulnerabity if an expression is like: {["<h1>Text</h1>"]}
    # consider checking if all members of an array are html_safe? and only then calling the joined result html_safe
    def rbexy_prep_output(*content)
      return if content.length == 0
      content = content.first

      value = content.is_a?(Array) ? content.join.html_safe : content
      [nil, false].include?(value) ? "" : value.to_s
    end
  end
end
