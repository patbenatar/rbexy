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
        extensions = details[:handlers].join(",")

        # TODO: if we don't find a matching .rbx template, look for a .rb component class (this might
        # be a template-less #call component), and if so return an empty template with just the cachebuster comment.
        # Then update RbxDependencyTracker to not filter out #call components, and they should _just work_.
        # Verify that the matching component class is a #call_component? before doing this though.. as we should
        # fail a missing template error if its a template-less non-call component.

        Dir["#{templates_path}.*{#{extensions}}"].map do |template_path|
          source = File.binread(template_path)
          extension = File.extname(template_path)[1..-1]
          handler = ActionView::Template.handler_for_extension(extension)
          component_name = prefix.present? ? File.join(prefix, name) : name
          virtual_path = Rbexy::Component::TemplatePath.new(component_name)

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

      def component_class_cachebuster(component_name, template_format)
        component_class = find_component_class(component_name)
        return unless component_class

        source = File.binread(component_class.component_file_location)
        digest = ActiveSupport::Digest.hexdigest(source)

        comment_template = COMMENT_SYNTAX[template_format.to_sym] || COMMENT_SYNTAX[:html]
        comment = comment_template % digest
        "\n#{comment}"
      end

      def find_component_class(component_name)
        Rbexy::ComponentResolver.try_constantize { component_name.classify.constantize }
      end
    end
  end
end
