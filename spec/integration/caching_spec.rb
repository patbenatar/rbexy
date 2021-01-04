RSpec.describe CachingController, type: :request do
  before(:each) { @cleanup = -> {} }
  after(:each) do
    @cleanup.call
    Rails.cache.clear
  end

  describe "fragment caching using `<Rbexy.Cache />` component" do
    it "caches template fragments" do
      expect(described_class).to receive(:heartbeat1).twice
      expect(described_class).to receive(:heartbeat2).once
      2.times { get "/caching/inline" }
    end

    it "busts the cache if the template changes" do
      expect(described_class).to receive(:heartbeat1).twice
      expect(described_class).to receive(:heartbeat2).twice

      get "/caching/inline"
      expect(response.body).to have_tag("h2", text: "Hello outer cache")

      template_path = Rails.root.join("app/views/caching/inline.rbx")
      original_source = File.read(template_path)
      new_source = original_source.gsub("Hello outer cache", "Goodbye outer cache")
      @cleanup = -> { File.write(template_path, original_source) }
      File.write(template_path, new_source)

      get "/caching/inline"
      expect(response.body).to have_tag("h2", text: "Goodbye outer cache")
    end
  end

  describe "fragments including sub-components" do
    it "caches the sub-component" do
      expect(CachedThingComponent).to receive(:heartbeat).once
      2.times { get "/caching/component" }
    end

    it "busts the cache if the sub-component's template changes" do
      expect(CachedThingComponent).to receive(:heartbeat).twice

      get "/caching/component"
      expect(response.body).to have_tag("h2", text: "Hello from Cached thing")

      template_path = Rails.root.join("app/components/cached_thing_component.rbx")
      original_source = File.read(template_path)
      new_source = original_source.gsub("Hello", "Goodbye")
      @cleanup = -> { File.write(template_path, original_source) }
      File.write(template_path, new_source)

      get "/caching/component"
      expect(response.body).to have_tag("h2", text: "Goodbye from Cached thing")
    end

    it "busts the cache if the sub-component's class source code changes", focus: true do
      expect(CachedThingComponent).to receive(:heartbeat).twice

      get "/caching/component"
      expect(response.body).to have_tag("h2", text: "Hello from Cached thing")

      class_source_path = Rails.root.join("app/components/cached_thing_component.rb")
      original_source = File.read(class_source_path)
      new_source = original_source.gsub("Cached thing", "Updated thing")
      @cleanup = -> { File.write(class_source_path, original_source) }
      File.write(class_source_path, new_source)

      get "/caching/component"
      expect(response.body).to have_tag("h2", text: "Hello from Updated thing")
    end
  end
end
