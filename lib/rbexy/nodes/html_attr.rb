module Rbexy
  module Nodes
    class HTMLAttr < AbstractAttr
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
