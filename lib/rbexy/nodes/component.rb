module Rbexy
  module Nodes
    class Component < XMLNode
      def precompile
        [Component.new(name, precompile_members, precompile_children)]
      end

      def compile
        kwargs = members.any? ? ",#{compile_members}" : ""
        base_tag = "::#{name}.new(self#{kwargs}).render"
        tag = if children.length > 0
          "#{base_tag}{capture{#{children.map(&:compile).join}}}"
        else
          base_tag
        end

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
