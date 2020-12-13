module Rbexy
  module Nodes
    class HTMLElement < AbstractElement
      KNOWN_VOID_ELEMENTS = ActionView::Helpers::TagHelper::TagBuilder::VOID_ELEMENTS.map(&:to_s).to_set

      def precompile
        nodes = []

        if void? && children.length == 0
          nodes.concat(precompile_open_tag)
        else
          nodes.concat(precompile_open_tag)
          nodes.concat(children.map(&:precompile).flatten)
          nodes << Raw.new("</#{name}>")
        end

        nodes
      end

      private

      def void?
        KNOWN_VOID_ELEMENTS.include?(name)
      end

      def precompile_open_tag
        nodes = [Raw.new("<#{name}")]
        nodes.concat(precompile_members)
        nodes << Raw.new(">")
        nodes
      end

      def precompile_members
        members.map do |node|
          if node.is_a? ExpressionGroup
            ExpressionGroup.new(
              node.members,
              inner_template: "Rbexy::Runtime.splat_attrs(%s)",
              outer_template: ExpressionGroup::OUTPUT_SAFE
            )
          else
            node
          end
        end.map(&:precompile).flatten
      end
    end
  end
end
