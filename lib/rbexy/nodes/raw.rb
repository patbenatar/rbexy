module Rbexy
  module Nodes
    class Raw < Base
      attr_reader :content

      def initialize(content)
        @content = content
      end

      def compile
        # TODO
      end
    end
  end
end
