# New approach for compiler:
#
# Build a big string of ruby code, with our literals as strings and our expressions
# interpolated within it, then eval the whole thing at once.
# * At the top we use Context#instance_eval
# * Sub-expressions just use #eval so they have access to whatever scope they're in

module Rbexy
  module Nodes
    class Template
      attr_reader :children

      def initialize(children)
        @children = children
      end

      def compile
        <<-CODE
output = ""
#{children.map(&:compile).map { |c| "output << (#{c})"}.join("\n")}
output
        CODE
        # ["output = \"\""]
        #   .concat(children.map(&:compile))
        #   .concat(["output"])
        #   .join("\n")
      end
    end

    class Text
      attr_reader :content

      def initialize(content)
        @content = content
      end

      def compile
        "\"#{content.gsub('"', '\\"')}\""
      end
    end

    class ExpressionGroup
      attr_reader :statements

      def initialize(statements)
        @statements = statements
      end

      def compile
        statements.map(&:compile).join
      end
    end

    class Expression
      attr_reader :content

      def initialize(content)
        @content = content
      end

      def compile
        content
      end
    end

    class XmlNode
      attr_reader :name, :attrs, :children

      def initialize(name, attrs, children)
        @name = name
        @attrs = attrs || {}
        @children = children
      end

      def compile

      end
    end

    class XmlAttr
      attr_reader :name, :value

      def initialize(name, value)
        @name = name
        @value = value
      end
    end
  end
end
