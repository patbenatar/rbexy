module Rbexy
  module Nodes
    class Component < XMLNode
      def precompile
        [Component.new(name, precompile_members, precompile_children)]
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
          tag = "rbexy_context.push({});#{tag}.tap{rbexy_context.pop}"
        end

        "@output_buffer.safe_append=(#{tag});"
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
        end.gsub(/,\z/, "")
      end

      private

      def precompile_members
        members.map(&:precompile).flatten
      end

      def precompile_children
        compact(children.map(&:precompile).flatten)
      end
    end
  end
end
