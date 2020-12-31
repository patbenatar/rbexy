module Rbexy
  module Nodes
    class Text < AbstractNode
      attr_accessor :content

      def initialize(content)
        @content = content
      end

      def precompile
        [Raw.new(Util.escape_string(content))]
      end
    end
  end
end
