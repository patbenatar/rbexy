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

      def merge(other_raw)
        content << other_raw.content
      end
    end
  end
end
