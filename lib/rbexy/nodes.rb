module Rbexy
  module Nodes
    class Template
      attr_reader :children

      def initialize(children)
        @children = children
      end

      def compile(compiler)
        children.map { |c| c.compile(compiler) }
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
      attr_reader :contents

      def initialize(contents)
        @contents = contents
      end

      def compile(compiler)
        contents
          .map { |c| c.is_a?(Expression) ? c : c.compile(compiler) }
          .join("")
      end
    end

    class Expression
      attr_reader :contents

      def initialize(contents)
        @contents = contents
      end

      def compile(compiler)
        contents
          .map { |c| c.is_a?(Expression) ? c : c.compile(compiler) }
          .join("")
      end
    end

    class XmlNode
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
          if attr.is_a? Expression
            unsplatted = attr.compile(compiler)
            memo.merge!(unsplatted)
          else
            compiled = attr.compile(compiler)
            memo[compiled[0]] = compiled[1]
          end
        end
      end

      def compile_children(compiler)
        children.map { |c| c.compile(compiler) }
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
