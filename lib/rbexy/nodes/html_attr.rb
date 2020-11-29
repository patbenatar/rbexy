module Rbexy
  module Nodes
    class HTMLAttr < XMLAttr
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
