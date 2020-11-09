RSpec.describe CustomProviderController, type: :controller do
  render_views

  it "allows a controller to override the component provider by implementing #rbexy_component_provider" do
    get :index

    expect(response.body)
      .to have_tag("h1", text: "Hello My Provider")
  end
end
