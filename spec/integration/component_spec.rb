RSpec.describe ApplicationController, type: :controller do
  render_views

  controller do; end
  let(:view_context) { controller.view_context }

  it "renders an rbx template" do
    expect(BasicTemplateComponent.new(view_context).render_in)
      .to have_tag("h1", text: "Hello basic template component")
  end

  it "renders an rbx template that contains utf8 characters" do
    expect(Utf8Component.new(view_context).render_in).to have_tag("p", text: "We’ll")
  end

  it "renders an rbx template that includes child components" do
    result = BasicParentComponent.new(view_context).render_in
    expect(result).to have_tag("h1", text: "Parent")
    expect(result).to have_tag("h1", text: "Hello basic template component")
  end

  it "exposes the component's methods to the rbx template" do
    expect(MethodComponent.new(view_context).render_in)
      .to have_tag("h1", text: "method value")
  end

  it "exposes the component's ivars to the rbx template" do
    expect(IvarComponent.new(view_context).render_in)
      .to have_tag("h1", text: "ivar value")
  end

  it "correctly uses methods from the context with keywords" do
    expect(MethodMissingComponent.new(view_context).render_in)
      .to have_tag("h1", text: "1 2 3")
  end

  it "passes props to #setup" do
    expect(PropsComponent.new(view_context, my_prop: "prop value").render_in)
      .to have_tag("h1", text: "prop value after setup")
  end

  it "exposes children to the component" do
    result = WithChildren::WrappingComponent.new(view_context).render_in
    expect(result).to have_tag("h1", text: "Here come the children...")
    expect(result).to have_tag("h1", text: "Text in a child")
  end

  it "allows the component to implement #call instead of a template" do
    class MyCallComponent < Rbexy::Component
      def call
        link_to "Foo", "/foo/bar"
      end
    end

    result = MyCallComponent.new(view_context).render_in
    expect(result).to have_tag("a", with: { href: "/foo/bar" }, text: "Foo")
  end

  it "has good stack traces for template runtime errors (doesn't include rbexy internal blocks and methods)" do
    expect { ErroringComponent.new(view_context).render_in }
      .to raise_error do |error|
        expect(error.backtrace[0]).to include "erroring_component.rbx:3"
        expect(error.backtrace[1]).to include "erroring_component.rbx:3:in `times'"
        expect(error.backtrace[2]).to include "component_spec.rb"
      end
  end

  it "has good stack traces for child component template runtime errors" do
    expect { WithChildren::ErroringWrappingComponent.new(view_context).render_in }
      .to raise_error do |error|
        expect(error.backtrace[0]).to include "erroring_child_component.rbx:2"
        expect(error.backtrace[1]).to include "erroring_wrapping_component.rbx:1"
      end
  end

  it "has good stack traces for errors that occur in the component class" do
    expect { ErroringInClassComponent.new(view_context).render_in }
      .to raise_error do |error|
        expect(error.backtrace[0]).to include "erroring_in_class_component.rb:3"
        expect(error.backtrace[1]).to include "erroring_in_class_component.rbx:2"
      end
  end

  context "Context API" do
    it "allows parent to pass data to child via context" do
      result = Context::WrappingComponent.new(view_context).render_in
      expect(result).to have_tag("h1", text: "value")
    end

    it "does not expose context to siblings" do
      expect { Context::WrappingWithSiblingComponent.new(view_context).render_in }
        .to raise_error(/no parent context `thing`/)
    end
  end

  context "atomic design folder structure (via config.template_paths option)" do
    it "allows components to exist in atomically organized dirs inside app/components/" do
      result = MoleculeWithAtomComponent.new(view_context).render_in
      expect(result).to have_tag("h1", text: "Hello molecule")
      expect(result).to have_tag("h1", text: "Hello atom")
    end

    context "namespaced atoms" do
      it "allows atomic components to be namespaced with dot notation" do
        result = NamespacedWrappingComponent.new(view_context).render_in
        expect(result).to have_tag("h1", text: "Child content")
      end
    end
  end
end
