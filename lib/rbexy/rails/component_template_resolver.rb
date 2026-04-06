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

      def _find_all(name, prefix, partial, details, key, locals)
        cache = key ? @unbound_templates : Concurrent::Map.new

        cache.compute_if_absent(ActionView::TemplatePath.virtual(name, prefix, partial)) do
          find_templates(name, prefix, partial, details, locals)
        end.map { |t| t.bind_locals(locals) }
      end

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

      def build_template(source:, template_path:, extension:, virtual_path:)
        ActionView::UnboundTemplate.new(
          source,
          template_path,
          details: ActionView::TemplateDetails.new(nil, extension, extension, nil),
          virtual_path: virtual_path
        )
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
