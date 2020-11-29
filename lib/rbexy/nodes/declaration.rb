module Rbexy
  module Nodes
    class Declaration < AbstractNode
      attr_reader :content

      def initialize(content)
        @content = content
      end

      def precompile
        [Raw.new(Util.escape_string(content))]
      end
    end
  end
end
