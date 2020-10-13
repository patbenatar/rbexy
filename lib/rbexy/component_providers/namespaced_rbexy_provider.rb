module Rbexy
  module ComponentProviders
    class NamespacedRbexyProvider < Rbexy::ComponentProviders::RbexyProvider
      attr_reader :namespaces

      def initialize(*namespaces)
        @namespaces = namespaces
      end

      def find(name)
        namespaces.each do |namespace|
          result = super("#{namespace}::#{name}")
          return result if result != nil
        end

        super
      end
    end
  end
end
