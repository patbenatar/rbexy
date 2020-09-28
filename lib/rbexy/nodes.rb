require "active_support/inflector"

# New approach for compiler:
#
# Build a big string of ruby code, with our literals as strings and our expressions
# interpolated within it, then eval the whole thing at once.
# * At the top we use Context#instance_eval
# * Sub-expressions just use #eval so they have access to whatever scope they're in

module Rbexy
  module Nodes
    module Util
      def self.safe_string(str)
        str.gsub('"', '\\"')
      end
    end

    class Template
      attr_reader :children

      def initialize(children)
        @children = children
      end

      def compile
        <<-CODE
"".tap do |output|
#{children.map(&:compile).map { |c| "output << (#{c})"}.join("\n")}
end
        CODE
      end
    end

    class Text
      attr_reader :content

      def initialize(content)
        @content = content
      end

      def compile
        "\"#{Util.safe_string(content)}\""
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
        content.strip
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
        tag = "tag.#{name}(#{compile_attrs})"

        if children.length > 0
<<-CODE
#{tag} do
  "".tap do |output|
    #{children.map(&:compile).map { |c| "output << (#{c})"}.join("\n")}
  end.html_safe
end
CODE
        else
          tag
        end
      end

      def compile_attrs
        attrs.map do |attr|
          if attr.is_a? ExpressionGroup
            # TODO
          else
            compiled = attr.compile
            "#{ActiveSupport::Inflector.underscore(compiled[0])}: #{compiled[1]}"
          end
        end.join(",")
      end
    end

    class XmlAttr
      attr_reader :name, :value

      def initialize(name, value)
        @name = name
        @value = value
      end

      def compile
        [
          name,
          value.compile
        ]
      end
    end
  end
end
