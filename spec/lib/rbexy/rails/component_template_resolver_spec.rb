RSpec.describe Rbexy::Rails::ComponentTemplateResolver do
  describe "#find_templates" do
    context "rbx" do
      it "returns the rbx template matching the given component path" do
        subject = described_class.new(Rails.root.join("app/components"))
        template_path = Rbexy::Component::TemplatePath.new("template_component")
        result = subject.find_templates(template_path, "template_resolution", false, { handlers: [:rbx] })

        expect(result.length).to eq 1
        template = result.first
        expect(template).to be_a ActionView::Template
        expect(template.identifier).to eq Rails.root.join("app/components/template_resolution/template_component.rbx").to_s
        expect(template.source).to include "<h1>Hello template component</h1>"
      end

      it "appends a cachebuster comment to the template source, so changes to the class definition itself will bust fragment caches" do
        subject = described_class.new(Rails.root.join("app/components"))
        template_path = Rbexy::Component::TemplatePath.new("template_component")
        result = subject.find_templates(template_path, "template_resolution", false, { handlers: [:rbx] })

        component_source = File.binread(Rails.root.join("app/components/template_resolution/template_component.rb"))
        component_digest = ActiveSupport::Digest.hexdigest(component_source)

        template = result.first
        expect(template.source).to match /\# #{component_digest}\z/
      end
    end

    context "not a component path" do
      it "returns an empty array, even if the given path would match a component" do
        subject = described_class.new(Rails.root.join("app/components"))
        result = subject.find_templates("template_component", "template_resolution", false, { handlers: [:rbx] })

        expect(result.length).to eq 0
      end
    end

    context "no template file exists" do
      it "returns an empty array" do
        subject = described_class.new(Rails.root.join("app/components"))
        template_path = Rbexy::Component::TemplatePath.new("missing_template_component")
        result = subject.find_templates(template_path, "template_resolution", false, { handlers: [:rbx] })

        expect(result).to be_empty
      end

      context "component class is a #call component" do
        it "returns a template containing just the cachebuster comment (for DependencyTracker's use)" do
          subject = described_class.new(Rails.root.join("app/components"))
          template_path = Rbexy::Component::TemplatePath.new("call_component")
          result = subject.find_templates(template_path, "template_resolution", false, { handlers: [:rbx] })

          component_source = File.binread(Rails.root.join("app/components/template_resolution/call_component.rb"))
          component_digest = ActiveSupport::Digest.hexdigest(component_source)

          expect(result.length).to eq 1
          template = result.first
          expect(template).to be_a ActionView::Template
          expect(template.identifier).to eq Rails.root.join("app/components/template_resolution/call_component.rbexycall").to_s
          expect(template.source).to eq "\n# #{component_digest}"
        end
      end
    end

    context "component is a subclass of another component" do
      it "returns the parent's template if the subclass doesn't implement its own" do

      end

      it "recursively climbs the class hierarchy until it finds a template"

      it "returns an empty array if no parents provide a template"

      # TODO: stuff about call components
    end
  end
end
