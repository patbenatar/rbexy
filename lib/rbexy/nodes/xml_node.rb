module Rbexy
  module Nodes
    class XMLNode < Base
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
            "#{base_tag} { capture {",
              children.map(&:compile).map { |c| "@output_buffer << rbexy_prep_output(#{c})" }.join(";"),
            "} }"
          ].join
        else
          base_tag
        end + ".html_safe"

        if Rbexy.configuration.enable_context
          [
            "(",
              "rbexy_context.push({});",
              "#{tag}.tap { rbexy_context.pop }",
            ")"
          ].join
        else
          tag
        end
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
  end
end
