module Rbexy
  module Nodes
    class Text < Base
      attr_reader :content

      def initialize(content)
        @content = content
      end

      def precompile
        [Raw.new(content)]
      end

      def compile
        "\"#{Util.safe_string(content)}\""
      end
    end
  end
end
