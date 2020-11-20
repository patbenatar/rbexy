RSpec.describe ContextController, type: :controller do
  render_views

  it "allows the controller to add to the component context with create_context" do
    get :index
    expect(response.body).to have_tag("h1", text: "Hello context from controller")
  end
end
