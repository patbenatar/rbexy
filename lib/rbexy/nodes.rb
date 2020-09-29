require "active_support/inflector"

module Rbexy
  module Nodes
    module Util
      def self.safe_string(str)
        str.gsub('"', '\\"')
      end

      def self.safe_tag_name(name)
        name.gsub(".", "__")
      end
    end

    class Template
      attr_reader :children

      def initialize(children)
        @children = children
      end

      def compile
        <<-CODE
Rbexy::OutputBuffer.new.tap do |output|
  #{children.map(&:compile).map { |c| "output << (#{c})"}.join("\n")}
end.html_safe
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
        StringIO.new.tap do |code|
          code.puts "Rbexy::OutputBuffer.new.tap do |output|"
          code.puts "rbexy_context.push({}) if respond_to?(:rbexy_context)"

          tag = "rbexy_tag.#{Util.safe_tag_name(name)}(#{compile_attrs})"

          code.puts(if children.length > 0
<<-CODE.strip
output << (#{tag} do
  Rbexy::OutputBuffer.new.tap do |output|
    #{children.map(&:compile).map { |c| "output << (#{c})"}.join("\n")}
  end.html_safe
end)
CODE
          else
            "output << (#{tag})"
          end)

          code.puts "rbexy_context.pop if respond_to?(:rbexy_context)"
          code.puts "end"
        end.string
      end

      def compile_attrs
        attrs.map do |attr|
          attr.is_a?(ExpressionGroup) ? "**#{attr.compile}" : attr.compile
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
        "\"#{name}\": #{value.compile}"
      end
    end
  end
end
