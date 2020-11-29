module Rbexy
  module Nodes
    class HTMLElement < XMLNode
      KNOWN_VOID_ELEMENTS = ActionView::Helpers::TagHelper::TagBuilder::VOID_ELEMENTS.map(&:to_s).to_set

      def precompile
        nodes = []

        if children.length > 0
          nodes.concat(precompile_open_tag)
          nodes.concat(children.map(&:precompile).flatten)
          nodes << Raw.new("</#{name}>")
        elsif void?
          nodes.concat(precompile_open_tag)
        else
          nodes.concat(precompile_open_tag(close: true))
        end

        nodes
      end

      private

      def void?
        KNOWN_VOID_ELEMENTS.include?(name)
      end

      def precompile_open_tag(close: false)
        nodes = [Raw.new("<#{name}")]
        nodes.concat(precompile_members)
        nodes << Raw.new(close ? " />" : ">")
        nodes
      end

      def precompile_members
        members.map do |node|
          if node.is_a? ExpressionGroup
            ExpressionGroup.new(node.statements, template: "Rbexy::Runtime.splat_attrs(%s)", safe: true)
          else
            node
          end
        end.map(&:precompile).flatten
      end
    end
  end
end
