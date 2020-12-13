module Rbexy
  class Parser
    class ParseError < StandardError; end

    attr_reader :tokens
    attr_accessor :position

    def initialize(tokens)
      @tokens = tokens
      @position = 0
    end

    def parse
      validate_tokens!
      Nodes::Root.new(parse_tokens)
    end

    def parse_tokens
      results = []

      while result = parse_token
        results << result
      end

      results
    end

    def parse_token
      parse_text || parse_newline || parse_expression || parse_tag || parse_declaration
    end

    def parse_text
      return unless token = take(:TEXT)
      Nodes::Text.new(token[1])
    end

    def parse_expression
      return unless take(:OPEN_EXPRESSION)

      members = []

      eventually!(:CLOSE_EXPRESSION)
      until take(:CLOSE_EXPRESSION)
        members << (parse_expression_body || parse_tag)
      end

      Nodes::ExpressionGroup.new(members)
    end

    def parse_expression!
      peek!(:OPEN_EXPRESSION)
      parse_expression
    end

    def parse_expression_body
      return unless token = take(:EXPRESSION_BODY)
      Nodes::Expression.new(token[1])
    end

    def parse_tag
      return unless take(:OPEN_TAG_DEF)

      details = take!(:TAG_DETAILS)[1]
      attr_class = details[:type] == :component ? Nodes::ComponentProp : Nodes::HTMLAttr

      members = []
      members.concat(take_all(:NEWLINE).map { Nodes::Newline.new })
      members.concat(parse_attrs(attr_class))

      take!(:CLOSE_TAG_DEF)

      children = parse_children

      if details[:type] == :component
        Nodes::ComponentElement.new(details[:component_class], members, children)
      else
        Nodes::HTMLElement.new(details[:name], members, children)
      end
    end

    def parse_attrs(attr_class)
      return [] unless take(:OPEN_ATTRS)

      attrs = []

      eventually!(:CLOSE_ATTRS)
      until take(:CLOSE_ATTRS)
        attrs << (parse_splat_attr || parse_newline || parse_attr(attr_class))
      end

      attrs
    end

    def parse_splat_attr
      return unless take(:OPEN_ATTR_SPLAT)

      expression = parse_expression!
      take!(:CLOSE_ATTR_SPLAT)

      expression
    end

    def parse_newline
      return unless take(:NEWLINE)
      Nodes::Newline.new
    end

    def parse_attr(attr_class)
      name = take!(:ATTR_NAME)[1]
      value = nil

      if take(:OPEN_ATTR_VALUE)
        value = parse_text || parse_expression
        raise ParseError, "Missing attribute value" unless value
        take(:CLOSE_ATTR_VALUE)
      else
        value = default_empty_attr_value
      end

      attr_class.new(name, value)
    end

    def parse_children
      children = []

      eventually!(:OPEN_TAG_END)
      until take(:OPEN_TAG_END)
        children << parse_token
      end

      take(:TAG_NAME)
      take!(:CLOSE_TAG_END)

      children
    end

    private

    def parse_declaration
      return unless token = take(:DECLARATION)
      Nodes::Declaration.new(token[1])
    end

    def take(token_name)
      if token = peek(token_name)
        self.position += 1
        token
      end
    end

    def take_all(token_name)
      result = []
      while token = take(token_name)
        result << token
      end
      result
    end

    def take!(token_name)
      take(token_name) || unexpected_token!(token_name)
    end

    def peek(token_name)
      if (token = tokens[position]) && token[0] == token_name
        token
      end
    end

    def peek!(token_name)
      peek(token_name) || unexpected_token!(token_name)
    end

    def eventually!(token_name)
      tokens[position..-1].first { |t| t[0] == token_name } ||
        raise(ParseError, "Expected to find a #{token_name} but never did")
    end

    def default_empty_attr_value
      Nodes::Text.new("")
    end

    def error_window
      window_start = position - 2
      window_start = 0 if window_start < 0
      window_end = position + 2
      window_end = tokens.length-1 if window_end >= tokens.length

      tokens[window_start..window_end].map.with_index do |token, i|
        prefix = window_start + i == position ? "=>" : "  "
        "#{prefix} #{token}"
      end.join("\n")
    end

    def unexpected_token!(expected_token)
      raise(ParseError, "Unexpected token #{tokens[position][0]}, expecting #{expected_token}\n#{error_window}")
    end

    def validate_tokens!
      validate_all_tags_close!
    end

    def validate_all_tags_close!
      open_count = tokens.count { |t| t[0] == :OPEN_TAG_DEF }
      close_count = tokens.count { |t| t[0] == :OPEN_TAG_END }
      if open_count != close_count
        raise(ParseError, "#{open_count - close_count} tags fail to close. All tags must close, either <NAME></NAME> or self-closing <NAME />")
      end
    end
  end
end
