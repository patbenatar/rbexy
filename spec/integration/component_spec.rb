RSpec.describe ApplicationController, type: :controller do
  controller do; end
  let(:view_context) { controller.view_context }

  it "renders an rbx template" do
    expect(BasicTemplateComponent.new(view_context).render)
      .to have_tag("h1", text: "Hello basic template component")
  end

  it "renders an rbx template that includes child components" do
    result = BasicParentComponent.new(view_context).render
    expect(result).to have_tag("h1", text: "Parent")
    expect(result).to have_tag("h1", text: "Hello basic template component")
  end

  it "exposes the component's methods to the rbx template" do
    expect(MethodComponent.new(view_context).render)
      .to have_tag("h1", text: "method value")
  end

  it "exposes the component's ivars to the rbx template" do
    expect(IvarComponent.new(view_context).render)
      .to have_tag("h1", text: "ivar value")
  end

  it "passes props to #setup" do
    expect(PropsComponent.new(view_context, my_prop: "prop value").render)
      .to have_tag("h1", text: "prop value after setup")
  end

  it "exposes children to the component" do
    result = WithChildren::WrappingComponent.new(view_context).render
    expect(result).to have_tag("h1", text: "Here come the children...")
    expect(result).to have_tag("h1", text: "Text in a child")
  end

  it "allows the component to implement #call instead of a template" do
    class MyCallComponent < Rbexy::Component
      def call
        link_to "Foo", "/foo/bar"
      end
    end

    result = MyCallComponent.new(view_context).render
    expect(result).to have_tag("a", with: { href: "/foo/bar" }, text: "Foo")
  end

  it "has good stack traces for template runtime errors" do
    expect { ErroringComponent.new(view_context).render }
      .to raise_error do |error|
        first_template_line = error.backtrace.find { |l| l.include?("erroring_component.rbx") }
        expect(first_template_line).to include "erroring_component.rbx:2"
      end
  end

  it "has good stack traces for child component template runtime errors" do
    expect { WithChildren::ErroringWrappingComponent.new(view_context).render }
      .to raise_error do |error|
        first_template_line = error.backtrace.find { |l| l.include?("erroring_parent_component.rbx") }
        expect(first_template_line).to include "erroring_parent_component.rbx:2"
      end
  end

  context "Context API" do
    it "allows parent to pass data to child via context" do
      result = Context::WrappingComponent.new(view_context).render
      expect(result).to have_tag("h1", text: "value")
    end

    it "does not expose context to siblings" do
      expect { Context::WrappingWithSiblingComponent.new(view_context).render }
        .to raise_error(/no parent context `thing`/)
    end
  end

  context "template_prefixes option" do
    before do
      @old_prefixes = Rbexy.configuration.template_prefixes
      Rbexy.configuration.template_prefixes.concat %w(atoms molecules organisms)
    end

    after { Rbexy.configuration.template_prefixes = @old_prefixes }

    it "allows components to exist in prefix dirs inside app/components/" do
      result = MoleculeWithAtomComponent.new(view_context).render
      expect(result).to have_tag("h1", text: "Hello molecule")
      expect(result).to have_tag("h1", text: "Hello atom")
    end

    context "namespaced atoms" do
      it "allows components in atoms/ to be namespaced with dot notation", focus: true do
        result = NamespacedWrappingComponent.new(view_context).render
        expect(result).to have_tag("h1", text: "Child content")
      end
    end
  end
end
