module Rbexy
  module Nodes
    class AbstractAttr < AbstractNode
      attr_accessor :name, :value

      def initialize(name, value)
        @name = name
        @value = value
      end
    end
  end
end
