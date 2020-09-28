module Rbexy
  module Nodes
    module ChildrenCompiler
      def compile_children(compiler)
        children
          .map { |c| c.compile(compiler) }
          .reject { |v| !v }
          .join("")
      end
    end

    class Template
      include ChildrenCompiler

      attr_reader :children

      def initialize(children)
        @children = children
      end

      def compile(compiler)
        compile_children(compiler)
      end
    end

    class Text
      attr_reader :content

      def initialize(content)
        @content = content
      end

      def compile(compiler)
        content
      end
    end

    class ExpressionGroup
      attr_reader :statements

      def initialize(statements)
        @statements = statements
      end

      def compile(compiler)
        compiler.eval(combined_expression(compiler))
      end

      def combined_expression(compiler)
        statements.map { |s| prepare_to_combine(s, compiler) }.join("")
      end

      def prepare_to_combine(statement, compiler)
        if statement.is_a?(Expression)
          # Collect sub-statements as code strings and wait to eval them
          # until we have the whole combined_expression in a code string
          statement.content
        else
          "\"#{statement.compile(compiler).gsub('"', '\\"')}\""
        end
      end
    end

    class Expression
      attr_reader :content

      def initialize(content)
        @content = content
      end

      def compile(compiler)
        compiler.eval(content)
      end
    end

    class XmlNode
      include ChildrenCompiler

      attr_reader :name, :attrs, :children

      def initialize(name, attrs, children)
        @name = name
        @attrs = attrs || {}
        @children = children
      end

      def compile(compiler)
        compiler.tag(name, compile_attrs(compiler)) do
          compile_children(compiler)
        end
      end

      def compile_attrs(compiler)
        attrs.each_with_object({}) do |attr, memo|
          if attr.is_a? ExpressionGroup
            unsplatted = attr.compile(compiler)
            memo.merge!(unsplatted)
          else
            compiled = attr.compile(compiler)
            memo[compiled[0]] = compiled[1]
          end
        end
      end
    end

    class XmlAttr
      attr_reader :name, :value

      def initialize(name, value)
        @name = name
        @value = value
      end

      def compile(compiler)
        [
          name,
          value&.compile(compiler)
        ]
      end
    end
  end
end
