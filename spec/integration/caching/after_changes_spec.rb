# NOTE: These specs are only meant to run as a part of bin/test,
# where before_changes_spec.rb has run first to warm the cache

RSpec.describe CachingController, type: :request, retry: 5 do
  before(:each) { Thread.current[:cache_misses] = 0 }
  after(:all) { Rails.cache.clear }

  describe "fragment caching using `<Rbexy.Cache />` component" do
    it "busts the cache when the template changes" do
      get "/caching/inline"
      expect(response.body).to have_tag("h2", text: "Goodbye outer cache")
      expect(Thread.current[:cache_misses]).to eq 1
    end
  end

  describe "fragments including template sub-components" do
    it "busts the cache when the sub-component's template changes" do
      get "/caching/component"
      expect(response.body).to have_tag("h2", text: "Goodbye from Cached thing")
      expect(Thread.current[:cache_misses]).to eq 1
    end

    it "busts the cache when the sub-component's class source code changes" do
      get "/caching/component_class"
      expect(response.body).to have_tag("h2", text: "Hello from Updated thing")
      expect(Thread.current[:cache_misses]).to eq 1
    end
  end

  describe "fragments including #call sub-components" do
    it "busts the cache when the sub-component's class source code changes" do
      get "/caching/call_component"
      expect(response.body).to have_tag("h2", text: "Hello from Updated thing")
      expect(Thread.current[:cache_misses]).to eq 1
    end
  end

  describe "fragment including Rails partial renders via `render` helper" do
    it "busts the cache when the partial changes" do
      get "/caching/partial_render"
      expect(response.body).to have_tag("h2", text: "Hello from Updated partial")
      expect(Thread.current[:cache_misses]).to eq 1
    end
  end
end
