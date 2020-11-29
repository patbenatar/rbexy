module Rbexy
  module Nodes
    class Declaration < AbstractNode
      attr_reader :content

      def initialize(content)
        @content = content
      end

      def compile
        # TODO
        "\"#{Util.safe_string(content)}\".html_safe"
      end
    end
  end
end
