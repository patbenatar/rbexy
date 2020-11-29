module Rbexy
  module Nodes
    class HTMLAttr < XMLAttr
      # TODO
      # KNOWN_BOOLEAN_ATTRIBUTES = ActionView::Helpers::TagHelper::BOOLEAN_ATTRIBUTES
      # %(#{key}="#{key}")

      def precompile
        [
          Raw.new(" #{name}=\""),
          value.precompile,
          Raw.new("\"")
        ].flatten
      end
    end
  end
end
