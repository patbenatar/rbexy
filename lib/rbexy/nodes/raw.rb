module Rbexy
  module Nodes
    class Raw < AbstractNode
      attr_reader :content, :template

      OUTPUT = "@output_buffer.safe_concat('%s'.freeze);"
      EXPR_STRING = "'%s'.html_safe.freeze"

      def initialize(content, template: OUTPUT)
        @content = content
        @template = template
      end

      def compile
        template % content
      end

      def merge(other_raw)
        content << other_raw.content
      end
    end
  end
end
