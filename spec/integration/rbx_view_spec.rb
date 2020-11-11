RSpec.describe RbxViewController, type: :controller do
  render_views

  it "renders rbx files in app/views/" do
    get :index

    expect(response.body).to have_tag("h1", text: "Hello from rbx view")
    expect(response.body).to have_tag("div > h2", text: "Subheading")
    expect(response.body).to have_tag("div > p", text: "Body copy")
  end
end
