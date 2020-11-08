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
        "#{children.map(&:compile).map { |c| "@output_buffer << rbexy_prep_output(#{c})"}.join(";")};@output_buffer;"
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
      attr_reader :name, :members, :children

      def initialize(name, members, children)
        @name = name
        @members = members || []
        @children = children
      end

      def compile
        base_tag = "rbexy_tag.#{Util.safe_tag_name(name)}(#{compile_members})"
        tag = if children.length > 0
          [
            "#{base_tag} {",
              children.map(&:compile).map { |c| "@output_buffer << rbexy_prep_output(#{c})" }.join(";"),
            "}"
          ].join
        else
          base_tag
        end

        context_open = Rbexy.configuration.enable_context ? "rbexy_context.push({});" : nil
        context_close = Rbexy.configuration.enable_context ? "rbexy_context.pop;" : nil

        [
          "(",
            context_open,
            "value = (#{tag}).html_safe;",
            context_close,
            "value",
          ")"
        ].join
      end

      def compile_members
        members.each_with_object("") do |member, result|
          case member
          when ExpressionGroup
            result << "**#{member.compile},"
          when SilentNewline
            result << member.compile
          else
            result << "#{member.compile},"
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

      def compile
        "\"#{name}\": #{value.compile}"
      end
    end

    class SilentNewline
      def compile
        "\n"
      end
    end

    class Declaration
      attr_reader :content

      def initialize(content)
        @content = content
      end

      def compile
        "\"#{Util.safe_string(content)}\".html_safe"
      end
    end
  end
end
