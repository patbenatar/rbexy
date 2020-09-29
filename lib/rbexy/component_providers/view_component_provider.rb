module Rbexy
  module ComponentProviders
    class ViewComponentProvider
      def match?(name)
        find(name) != nil
      end

      def render(context, name, **attrs, &block)
        props = attrs.transform_keys { |k| ActiveSupport::Inflector.underscore(k.to_s).to_sym }
        find(name).new(**props).render_in(context, &block)
      end

      private

      def find(name)
        ActiveSupport::Inflector.constantize("#{name}Component")
      rescue NameError => e
        raise e unless e.message =~ /constant/
        nil
      end
    end
  end
end
