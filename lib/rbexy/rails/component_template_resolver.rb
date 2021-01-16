require "active_support/digest"

module Rbexy
  module Rails
    class ComponentTemplateResolver < ActionView::FileSystemResolver
      COMMENT_SYNTAX = {
        rbx: "# %s",
        erb: "<%# %s %>",
        html: "<!-- %s -->"
      }

      # Rails 6 requires us to override `_find_all` in order to hook
      def _find_all(name, prefix, partial, details, key, locals)
        find_templates(name, prefix, partial, details, locals)
      end

      # Rails 5 only requires `find_templates` (which tbh is the proper way
      # to implement subclasses of ActionView::Resolver)
      def find_templates(name, prefix, partial, details, locals = [])
        return [] unless name.is_a? Rbexy::Component::TemplatePath

        templates_path = File.join(@path, prefix, name)
        component_name = prefix.present? ? File.join(prefix, name) : name
        virtual_path = Rbexy::Component::TemplatePath.new(component_name)

        extensions = details[:handlers].join(",")
        templates = find_rbx_templates(templates_path, extensions, component_name, virtual_path)

        if templates.none?
          templates = find_call_component_cachebuster_templates(templates_path, component_name, virtual_path)
        end

        templates
      end

      def find_rbx_templates(templates_path, extensions, component_name, virtual_path)
        Dir["#{templates_path}.*{#{extensions}}"].map do |template_path|
          source = File.binread(template_path)
          extension = File.extname(template_path)[1..-1]
          handler = ActionView::Template.handler_for_extension(extension)

          ActionView::Template.new(
            "#{source}#{component_class_cachebuster(component_name, extension)}",
            template_path,
            handler,
            format: extension.to_sym,
            locals: [],
            virtual_path: virtual_path
          )
        end
      end

      def find_call_component_cachebuster_templates(templates_path, component_name, virtual_path)
        component_class = find_component_class(component_name)
        return [] unless component_class && component_class.call_component?

        [
          ActionView::Template.new(
            cachebuster_digest_as_comment(component_class.component_file_location, :rbx),
            "#{templates_path}.rbexycall",
            ActionView::Template.handler_for_extension(:rbx),
            format: :rbx,
            locals: [],
            virtual_path: virtual_path
          )
        ]
      end

      def component_class_cachebuster(component_name, template_format)
        component_class = find_component_class(component_name)
        return unless component_class

        cachebuster_digest_as_comment(component_class.component_file_location, template_format)
      end

      def find_component_class(component_name)
        Rbexy::ComponentResolver.try_constantize { component_name.classify.constantize }
      end

      def cachebuster_digest_as_comment(filename, format)
        source = File.binread(filename)
        digest = ActiveSupport::Digest.hexdigest(source)

        comment_template = COMMENT_SYNTAX[format.to_sym] || COMMENT_SYNTAX[:html]
        comment = comment_template % digest
        "\n#{comment}"
      end
    end
  end
end
