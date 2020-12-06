require "action_view"

module Rbexy
  module Rails
    class ComponentTemplateResolver < ActionView::FileSystemResolver
      VIRTUAL_ROOT = "rbexy_component".freeze

      # Rails 6 requires us to override `_find_all` in order to hook
      def _find_all(name, prefix, partial, details, key, locals)
        find_templates(name, prefix, partial, details, locals)
      end

      # Rails 5 only requires `find_templates` (which tbh is the proper way
      # to implement subclasses of ActionView::Resolver)
      def find_templates(name, prefix, partial, details, locals = [])
        return [] unless name.is_a? Rbexy::Component::TemplatePath

        templates_path = File.join(@path, prefix, name)
        extensions = details[:handlers].join(",")

        Dir["#{templates_path}.*{#{extensions}}"].map do |template_path|
          source = File.binread(template_path)
          handler = ActionView::Template.handler_for_extension(File.extname(template_path)[1..-1])
          virtual_path = File.join(VIRTUAL_ROOT, prefix, name)

          ActionView::Template.new(
            source,
            template_path,
            handler,
            locals: [],
            virtual_path: virtual_path
          )
        end
      end
    end
  end
end
