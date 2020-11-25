module Rbexy
  module Nodes
    class Expression < AbstractNode
      attr_reader :content

      def initialize(content)
        @content = content
      end

      def compile
        content
      end
    end
  end
end
