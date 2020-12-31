module Rbexy
  class Lexer
    class SyntaxError < StandardError
      def initialize(lexer)
        super(
          "Invalid syntax: `#{lexer.scanner.peek(20)}`\n" +
          "Stack: #{lexer.stack}\n" +
          "Tokens: #{lexer.tokens}"
        )
      end
    end

    Patterns = OpenStruct.new(
      open_expression: /{/,
      close_expression: /}/,
      expression_content: /[^}{"'<]+/,
      open_tag_def: /<(?!\/)/,
      open_tag_end: /<\//,
      close_tag: /\s*\/?>/,
      close_self_closing_tag: /\s*\/>/,
      tag_name: /\/?[A-Za-z0-9\-_.]+/,
      text_content: /[^<{#]+/,
      comment: /^\p{Blank}*#.*(\n|\z)/,
      whitespace: /\s+/,
      attr: /[A-Za-z0-9\-_\.:]+/,
      open_attr_splat: /{\*\*/,
      attr_assignment: /=/,
      double_quote: /"/,
      single_quote: /'/,
      double_quoted_text_content: /[^"]+/,
      single_quoted_text_content: /[^']+/,
      expression_internal_tag_prefixes: /(\s+(&&|\?|:|do|do\s*\|[^\|]+\||{|{\s*\|[^\|]+\|)\s+\z|\A\s*\z)/,
      declaration: /<![^>]*>/
    )

    attr_reader :stack, :tokens, :scanner, :element_resolver, :template
    attr_accessor :curr_expr, :curr_default_text,
                  :curr_quoted_text

    def initialize(template, element_resolver)
      @template = template
      @scanner = StringScanner.new(template.source)
      @element_resolver = element_resolver
      @stack = [:default]
      @curr_expr = ""
      @curr_default_text = ""
      @curr_quoted_text = ""
      @tokens = []
    end

    def tokenize
      until scanner.eos?
        case stack.last
        when :default
          if scanner.scan(Patterns.declaration)
            tokens << [:DECLARATION, scanner.matched]
          elsif scanner.scan(Patterns.open_tag_def)
            open_tag_def
          elsif scanner.scan(Patterns.open_expression)
            open_expression
          elsif scanner.scan(Patterns.comment)
            tokens << [:NEWLINE]
          elsif scanner.check(Patterns.text_content)
            stack.push(:default_text)
          else
            raise SyntaxError, self
          end
        when :tag
          if scanner.scan(Patterns.open_tag_def)
            open_tag_def
          elsif scanner.scan(Patterns.open_tag_end)
            tokens << [:OPEN_TAG_END]
            stack.push(:tag_end)
          elsif scanner.scan(Patterns.open_expression)
            open_expression
          elsif scanner.scan(Patterns.comment)
            tokens << [:NEWLINE]
          elsif scanner.check(Patterns.text_content)
            stack.push(:default_text)
          else
            raise SyntaxError, self
          end
        when :default_text
          if scanner.scan(Patterns.text_content)
            self.curr_default_text += scanner.matched
            if scanner.matched.end_with?('\\') && scanner.peek(1) == "{"
              self.curr_default_text += scanner.getch
            elsif scanner.matched.end_with?('\\') && scanner.peek(1) == "#"
              self.curr_default_text += scanner.getch
            else
              if scanner.peek(1) == "#"
                # If the next token is a comment, trim trailing whitespace from
                # the text value so we don't add to the indentation of the next
                # value that is output after the comment
                self.curr_default_text = curr_default_text.gsub(/^\p{Blank}*\z/, "")
              end
              tokens << [:TEXT, curr_default_text]
              self.curr_default_text = ""
              stack.pop
            end
          else
            raise SyntaxError, self
          end
        when :expression
          if scanner.scan(Patterns.close_expression)
            tokens << [:EXPRESSION_BODY, curr_expr]
            tokens << [:CLOSE_EXPRESSION]
            self.curr_expr = ""
            stack.pop
          elsif scanner.scan(Patterns.open_expression)
            expression_inner_bracket
          elsif scanner.scan(Patterns.double_quote)
            expression_inner_double_quote
          elsif scanner.scan(Patterns.single_quote)
            expression_inner_single_quote
          elsif scanner.scan(Patterns.open_tag_def)
            potential_expression_inner_tag
          elsif expression_content?
            self.curr_expr += scanner.matched
          else
            raise SyntaxError, self
          end
        when :expression_inner_bracket
          if scanner.scan(Patterns.close_expression)
            self.curr_expr += scanner.matched
            stack.pop
          elsif scanner.scan(Patterns.open_expression)
            expression_inner_bracket
          elsif scanner.scan(Patterns.double_quote)
            expression_inner_double_quote
          elsif scanner.scan(Patterns.single_quote)
            expression_inner_single_quote
          elsif scanner.scan(Patterns.open_tag_def)
            potential_expression_inner_tag
          elsif expression_content?
            self.curr_expr += scanner.matched
          else
            raise SyntaxError, self
          end
        when :expression_inner_double_quote
          if scanner.check(Patterns.double_quote)
            expression_quoted_string_content
          elsif scanner.scan(Patterns.double_quoted_text_content)
            self.curr_expr += scanner.matched
          else
            raise SyntaxError, self
          end
        when :expression_inner_single_quote
          if scanner.check(Patterns.single_quote)
            expression_quoted_string_content
          elsif scanner.scan(Patterns.single_quoted_text_content)
            self.curr_expr += scanner.matched
          else
            raise SyntaxError, self
          end
        when :tag_def
          if scanner.scan(Patterns.close_self_closing_tag)
            tokens << [:CLOSE_TAG_DEF]
            tokens << [:OPEN_TAG_END]
            tokens << [:CLOSE_TAG_END]
            stack.pop(2)
          elsif scanner.scan(Patterns.close_tag)
            tokens << [:CLOSE_TAG_DEF]
            stack.pop
          elsif scanner.scan(Patterns.tag_name)
            tokens << [:TAG_DETAILS, tag_details(scanner.matched)]
          elsif scanner.scan(Patterns.whitespace)
            scanner.matched.count("\n").times { tokens << [:NEWLINE] }
            tokens << [:OPEN_ATTRS]
            stack.push(:tag_attrs)
          else
            raise SyntaxError, self
          end
        when :tag_end
          if scanner.scan(Patterns.close_tag)
            tokens << [:CLOSE_TAG_END]
            stack.pop(2)
          elsif scanner.scan(Patterns.tag_name)
            tokens << [:TAG_NAME, scanner.matched]
          else
            raise SyntaxError, self
          end
        when :tag_attrs
          if scanner.scan(Patterns.whitespace)
            scanner.matched.count("\n").times { tokens << [:NEWLINE] }
          elsif scanner.check(Patterns.close_tag)
            tokens << [:CLOSE_ATTRS]
            stack.pop
          elsif scanner.scan(Patterns.attr_assignment)
            tokens << [:OPEN_ATTR_VALUE]
            stack.push(:tag_attr_value)
          elsif scanner.scan(Patterns.attr)
            tokens << [:ATTR_NAME, scanner.matched.strip]
          elsif scanner.scan(Patterns.open_attr_splat)
            tokens << [:OPEN_ATTR_SPLAT]
            tokens << [:OPEN_EXPRESSION]
            stack.push(:tag_attr_splat, :expression)
          else
            raise SyntaxError, self
          end
        when :tag_attr_value
          if scanner.scan(Patterns.double_quote)
            stack.push(:quoted_text)
          elsif scanner.scan(Patterns.open_expression)
            open_expression
          elsif scanner.scan(Patterns.whitespace) || scanner.check(Patterns.close_tag)
            tokens << [:CLOSE_ATTR_VALUE]
            scanner.matched.count("\n").times { tokens << [:NEWLINE] }
            stack.pop
          else
            raise SyntaxError, self
          end
        when :tag_attr_splat
          # Splat is consumed by :expression. It pops control back to here once
          # it's done, and we just record the completion and pop back to :tag_attrs
          tokens << [:CLOSE_ATTR_SPLAT]
          stack.pop
        when :quoted_text
          if scanner.scan(Patterns.double_quoted_text_content)
            self.curr_quoted_text += scanner.matched
            if scanner.matched.end_with?('\\') && scanner.peek(1) == "\""
              self.curr_quoted_text += scanner.getch
            end
          elsif scanner.scan(Patterns.double_quote)
            tokens << [:TEXT, curr_quoted_text]
            self.curr_quoted_text = ""
            stack.pop
          else
            raise SyntaxError, self
          end
        else
          raise SyntaxError, self
        end
      end

      tokens
    end

    def potential_expression_inner_tag
      if self.curr_expr =~ Patterns.expression_internal_tag_prefixes
        tokens << [:EXPRESSION_BODY, curr_expr]
        self.curr_expr = ""
        open_tag_def
      else
        self.curr_expr += scanner.matched
      end
    end

    def open_tag_def
      tokens << [:OPEN_TAG_DEF]
      stack.push(:tag, :tag_def)
    end

    def open_expression
      tokens << [:OPEN_EXPRESSION]
      stack.push(:expression)
    end

    def expression_inner_bracket
      self.curr_expr += scanner.matched
      stack.push(:expression_inner_bracket)
    end

    def expression_inner_double_quote
      self.curr_expr += scanner.matched
      stack.push(:expression_inner_double_quote)
    end

    def expression_inner_single_quote
      self.curr_expr += scanner.matched
      stack.push(:expression_inner_single_quote)
    end

    def expression_quoted_string_content
      self.curr_expr += scanner.getch
      stack.pop unless curr_expr.end_with?('\\')
    end

    def expression_content?
      # Patterns.expression_content ends at `<` characters, because we need to
      # separately scan for allowed open_tag_defs within expressions. We should
      # support any found open_tag_ends as expression content, as that means the
      # open_tag_def was not considered allowed (or stack would be inside
      # :tag_def instead of :expression) so we should thus also consider the
      # open_tag_end to just be a part of the expression (maybe its in a string,
      # etc).
      scanner.scan(Patterns.expression_content) || scanner.scan(Patterns.open_tag_end)
    end

    def tag_details(name)
      type = element_resolver.component?(name, template) ? :component : :html
      details = { name: scanner.matched, type: type }
      details[:component_class] = element_resolver.component_class(name, template) if type == :component
      details
    end
  end
end
