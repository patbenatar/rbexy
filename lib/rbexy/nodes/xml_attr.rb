module Rbexy
  module Nodes
    class XmlAttr < Base
      attr_reader :name, :value

      def initialize(name, value)
        @name = name
        @value = value
      end

      def compile
        "\"#{name}\": #{value.compile}"
      end
    end
  end
end
