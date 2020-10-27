require "action_view"

module Rbexy
  module Rails
    class ComponentTemplateResolver < ActionView::FileSystemResolver
      def _find_all(name, prefix, partial, details, key, locals)
        find_templates(name, prefix, partial, details, locals)
      end

      def find_templates(name, prefix, partial, details, locals = [])
        return [] unless name.is_a? Rbexy::Component::TemplatePath

        templates_path = File.join(path, prefix, name)
        extensions = details[:handlers].join(",")

        Dir["#{templates_path}.*{#{extensions}}"].map do |template_path|
          source = ActionView::Template::Sources::File.new(template_path)
          handler = ActionView::Template.handler_for_extension(File.extname(template_path)[1..-1])

          ActionView::Template.new(source, template_path, handler, locals: [])
        end
      end
    end
  end
end
