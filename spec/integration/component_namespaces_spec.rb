RSpec.describe ApplicationController, type: :controller do
  render_views

  controller do; end
  let(:view_context) { controller.view_context }

  before do
    Rbexy.configuration.element_resolver.component_namespaces = {
      Rails.root.join("app", "components", "auto_namespacing") => %w[AutoNamespacing]
    }
  end

  after { Rbexy.configuration.element_resolver.component_namespaces = {} }

  it "resolves component names in the configured namespace matching the template's location" do
    expect(AutoNamespacing::WrappingComponent.new(view_context).render)
      .to have_tag("h1", text: "Hello auto-namespaced component")
  end
end
