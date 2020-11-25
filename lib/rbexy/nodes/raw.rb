module Rbexy
  module Nodes
    class Raw < AbstractNode
      attr_reader :content

      def initialize(content)
        @content = content
      end

      def compile
        "@output_buffer.safe_append='#{content}'.freeze;"
      end
    end
  end
end
