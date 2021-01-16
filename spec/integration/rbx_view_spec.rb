RSpec.describe RbxViewController, type: :controller do
  render_views

  it "renders rbx files in app/views/" do
    get :index

    expect(response.body).to have_tag("h1", text: "Hello from rbx view")
    expect(response.body).to have_tag("div > h2", text: "Subheading")
    expect(response.body).to have_tag("div > p", text: "Body copy")
  end

  it "renders rbx files that contain utf-8 characters" do
    get :utf8
    expect(response.body).to have_tag("p", text: "We’ll")
  end
end
