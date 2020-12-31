module Rbexy
  module Nodes
    class ComponentElement < AbstractElement
      attr_reader :template

      OUTPUT = "@output_buffer.safe_concat(%s);"
      EXPR_STRING = "%s.html_safe"

      def initialize(*args, template: OUTPUT)
        super(*args)
        @template = template
      end

      def precompile
        [ComponentElement.new(name, precompile_members, precompile_children)]
      end

      def compile
        templates = Rbexy.configuration.component_rendering_templates

        tag = templates[:component] % {
          component_class: name,
          view_context: "self",
          kwargs: compile_members,
          children_block: children.any? ? templates[:children] % { children: children.map(&:compile).join } : ""
        }

        if Rbexy.configuration.enable_context
          tag = "(rbexy_context.push({});#{tag}.tap{rbexy_context.pop})"
        end

        template % tag
      end

      def compile_members
        members.each_with_object("") do |member, result|
          case member
          when ExpressionGroup
            result << "**#{member.compile},"
          when Newline
            result << member.compile
          else
            result << "#{member.compile},"
          end
        end.gsub(/,\z/, "")
      end

      private

      def precompile_members
        members.map do |node|
          if node.is_a? ExpressionGroup
            ExpressionGroup.new(
              node.members,
              inner_template: ExpressionGroup::SUB_EXPR,
              outer_template: ExpressionGroup::SUB_EXPR
            )
          else
            node
          end
        end.map(&:precompile).flatten
      end

      def precompile_children
        compact(children.map(&:precompile).flatten)
      end
    end
  end
end
