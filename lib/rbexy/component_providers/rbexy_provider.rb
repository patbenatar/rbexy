# NICKTODO: should this be default??

module Rbexy
  module ComponentProviders
    class RbexyProvider
      def match?(name)
        name =~ /^[A-Z]/ && find(name) != nil
      end

      def render(context, name, **attrs, &block)
        props = attrs.transform_keys { |k| ActiveSupport::Inflector.underscore(k.to_s).to_sym }
        find(name).new(context, **props).render(&block)
      end

      private

      def find(name)
        ActiveSupport::Inflector.constantize("#{name}Component")
      rescue NameError => e
        raise e unless e.message =~ /wrong constant name/ || e.message =~ /uninitialized constant/
        nil
      end
    end
  end
end
