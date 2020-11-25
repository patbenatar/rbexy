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
        nodes.concat(members.map(&:precompile).flatten)
        nodes << Raw.new(close ? " />" : ">")
        nodes
      end
    end
  end
end
