RSpec.describe ApplicationController, type: :controller do
  controller do; end
  let(:view_context) { controller.view_context }

  it "renders an rbx template"
  it "renders an rbx template that includes child components"
  it "exposes the component's methods to the rbx template"
  it "exposes the component's ivars to the rbx template"
  it "exposes children to the component"

  it "allows the component to implement #call instead of a template" do
    class MyCallComponent < Rbexy::Component
      def call
        link_to "Foo", "/foo/bar"
      end
    end

    result = MyCallComponent.new(view_context).render
    expect(result).to have_tag("a", with: { href: "/foo/bar" }, text: "Foo")
  end

  it "has good stack traces for template runtime errors"
  it "has good stack traces for child component template runtime errors"

  context "Context API" do
    it "allows parent to pass data to child via context"
    it "does not expose context to siblings"
  end

  it "does something cool" do
  end
end
