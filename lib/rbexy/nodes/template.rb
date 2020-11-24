module Rbexy
  module Nodes
    class Template < Base
      attr_reader :children

      def initialize(children)
        @children = children
      end

      def compile
        "#{children.map(&:compile).map { |c| "@output_buffer << rbexy_prep_output(#{c})"}.join(";")};@output_buffer"
      end
    end
  end
end
