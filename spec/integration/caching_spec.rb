RSpec.describe CachingController, type: :request do
  before(:each) do
    @cleanup = -> {}
    Rails.cache.clear
    Thread.current[:cache_misses] = 0
  end
  after(:each) { @cleanup.call }
  after(:all) { Rails.cache.clear }

  describe "fragment caching using `<Rbexy.Cache />` component" do
    it "caches template fragments" do
      2.times { get "/caching/inline" }
      expect(Thread.current[:cache_misses]).to eq 1
    end

    it "busts the cache if the template changes" do
      get "/caching/inline"
      expect(response.body).to have_tag("h2", text: "Hello outer cache")

      template_path = Rails.root.join("app/views/caching/inline.rbx")
      original_source = File.read(template_path)
      new_source = original_source.gsub("Hello outer cache", "Goodbye outer cache")
      @cleanup = -> { File.write(template_path, original_source) }
      File.write(template_path, new_source)

      get "/caching/inline"
      expect(response.body).to have_tag("h2", text: "Goodbye outer cache")

      expect(Thread.current[:cache_misses]).to eq 2
    end
  end

  describe "fragments including template sub-components" do
    it "caches the fragment including the sub-component" do
      2.times { get "/caching/component" }
      expect(Thread.current[:cache_misses]).to eq 1
    end

    it "busts the cache if the sub-component's template changes" do
      get "/caching/component"
      expect(response.body).to have_tag("h2", text: "Hello from Cached thing")

      template_path = Rails.root.join("app/components/cached_thing_component.rbx")
      original_source = File.read(template_path)
      new_source = original_source.gsub("Hello", "Goodbye")
      @cleanup = -> { File.write(template_path, original_source) }
      File.write(template_path, new_source)

      get "/caching/component"
      expect(response.body).to have_tag("h2", text: "Goodbye from Cached thing")

      expect(Thread.current[:cache_misses]).to eq 2
    end

    it "busts the cache if the sub-component's class source code changes" do
      get "/caching/component"
      expect(response.body).to have_tag("h2", text: "Hello from Cached thing")

      class_source_path = Rails.root.join("app/components/cached_thing_component.rb")
      original_source = File.read(class_source_path)
      new_source = original_source.gsub("Cached thing", "Updated thing")
      @cleanup = -> { File.write(class_source_path, original_source) }
      File.write(class_source_path, new_source)

      get "/caching/component"
      expect(response.body).to have_tag("h2", text: "Hello from Updated thing")

      expect(Thread.current[:cache_misses]).to eq 2
    end
  end

  describe "fragments including #call sub-components" do
    it "caches the fragment including the sub-component" do
      2.times { get "/caching/call_component" }
      expect(Thread.current[:cache_misses]).to eq 1
    end

    it "busts the cache if the sub-component's class source code changes" do
      get "/caching/call_component"
      expect(response.body).to have_tag("h2", text: "Hello from Cached thing")

      class_source_path = Rails.root.join("app/components/cached_thing_call_component.rb")
      original_source = File.read(class_source_path)
      new_source = original_source.gsub("Cached thing", "Updated thing")
      @cleanup = -> { File.write(class_source_path, original_source) }
      File.write(class_source_path, new_source)

      get "/caching/call_component"
      expect(response.body).to have_tag("h2", text: "Hello from Updated thing")

      expect(Thread.current[:cache_misses]).to eq 2
    end
  end

  describe "fragment including Rails partial renders via `render` helper" do
    it "caches template fragments" do
      2.times { get "/caching/partial_render" }
      expect(Thread.current[:cache_misses]).to eq 1
    end

    it "busts the cache if the partial changes" do
      get "/caching/partial_render"
      expect(response.body).to have_tag("h2", text: "Hello from Cached partial")

      template_path = Rails.root.join("app/views/caching/_partial_render_partial.rbx")
      original_source = File.read(template_path)
      new_source = original_source.gsub("Cached partial", "Updated partial")
      @cleanup = -> { File.write(template_path, original_source) }
      File.write(template_path, new_source)

      get "/caching/partial_render"
      expect(response.body).to have_tag("h2", text: "Hello from Updated partial")

      expect(Thread.current[:cache_misses]).to eq 2
    end
  end
end
