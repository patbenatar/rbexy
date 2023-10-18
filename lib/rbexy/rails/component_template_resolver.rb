require "active_support/digest"

module Rbexy
  module Rails
    class ComponentTemplateResolver < ActionView::FileSystemResolver
      COMMENT_SYNTAX = {
        rbx: "# %s",
        erb: "<%%# %s %%>",
        haml: "-# %s",
        slim: "/ %s"
      }

      # Rails 6 and 7 require us to override `_find_all` in order to hook
      if ActionView.version >= Gem::Version.new("7.0.0")
        # Rails 7 implements caching internally to _find_all
        def _find_all(name, prefix, partial, details, key, locals)
          cache = key ? @unbound_templates : Concurrent::Map.new

          cache.compute_if_absent(ActionView::TemplatePath.virtual(name, prefix, partial)) do
            find_templates(name, prefix, partial, details, locals)
          end
        end
      else
        # Rails 6 implements caching at the call-site (find_all)
        def _find_all(name, prefix, partial, details, key, locals)
          find_templates(name, prefix, partial, details, locals)
        end
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

          build_template(
            source: "#{source}#{component_class_cachebuster(component_name, extension)}",
            template_path: template_path,
            extension: extension.to_sym,
            virtual_path: virtual_path
          )
        end
      end

      def find_call_component_cachebuster_templates(templates_path, component_name, virtual_path)
        component_class = find_component_class(component_name)
        return [] unless component_class && component_class.call_component?

        [
          build_template(
            source: cachebuster_digest_as_comment(component_class.component_file_location, :rbx),
            template_path: "#{templates_path}.rbexycall",
            extension: :rbx,
            virtual_path: virtual_path
          )
        ]
      end

      if ActionView.version >= Gem::Version.new("7.0.0")
        def build_template(source:, template_path:, extension:, virtual_path:)
          ActionView::UnboundTemplate.new(
            source,
            template_path,
            details: ActionView::TemplateDetails.new(nil, extension, extension, nil),
            virtual_path: virtual_path
          ).bind_locals([])
        end
      else
        def build_template(source:, template_path:, extension:, virtual_path:)
          ActionView::UnboundTemplate.new(
            source,
            template_path,
            ActionView::Template.handler_for_extension(extension),
            format: extension.to_sym,
            virtual_path: virtual_path
          ).bind_locals([])
        end
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
        comment_template = COMMENT_SYNTAX[format.to_sym]
        return "" unless comment_template

        source = File.binread(filename)
        digest = ActiveSupport::Digest.hexdigest(source)

        "\n#{comment_template % digest}"
      end
    end
  end
end
