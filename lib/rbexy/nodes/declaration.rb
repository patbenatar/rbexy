module Rbexy
  module Nodes
    class Declaration < Base
      attr_reader :content

      def initialize(content)
        @content = content
      end

      def compile
        "\"#{Util.safe_string(content)}\".html_safe"
      end
    end
  end
end
