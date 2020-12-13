module Rbexy
  module Nodes
    class Expression < AbstractNode
      attr_accessor :content

      def initialize(content)
        @content = content
      end

      def compile
        content
      end
    end
  end
end
