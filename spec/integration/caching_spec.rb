RSpec.describe CachingController, type: :request do
  before(:each) do
    Rails.cache.clear
    Thread.current[:cache_misses] = 0
  end
  after(:all) { Rails.cache.clear }

  def wait_for_code_reload_timing_issue
    # Hack to avoid intermittent test failures when we change the underlying source file while Rails is running.
    # Not ideal, but acceptable IMO because the actual use case we're testing here is that you've made source changes
    # and are re-deploying your application, which would result in the Rails server restarting. Since we don't want
    # that kind of overhead in the test, this little hack workaround for runtime code reloading makes it so we can
    # test that Rails does bust the cache based on source changes.
    sleep 0.5
  end

  describe "fragment caching using `<Rbexy.Cache />` component" do
    let(:template_path) { Rails.root.join("app/views/caching/inline.rbx") }
    before(:each) { FileUtils.cp(template_path, "#{template_path}.bak") }
    after(:each) { FileUtils.mv("#{template_path}.bak", template_path); wait_for_code_reload_timing_issue }

    it "caches template fragments" do
      2.times { get "/caching/inline" }
      expect(Thread.current[:cache_misses]).to eq 1
    end

    it "busts the cache if the template changes" do
      get "/caching/inline"
      expect(response.body).to have_tag("h2", text: "Hello outer cache")

      File.write(template_path, File.read(template_path).gsub("Hello outer cache", "Goodbye outer cache"))

      get "/caching/inline"
      expect(response.body).to have_tag("h2", text: "Goodbye outer cache")

      expect(Thread.current[:cache_misses]).to eq 2
    end
  end

  describe "fragments including template sub-components" do
    let(:template_path) { Rails.root.join("app/components/cached_thing_component.rbx") }
    let(:class_path) { Rails.root.join("app/components/cached_thing_component.rb") }
    before(:each) do
      FileUtils.cp(template_path, "#{template_path}.bak")
      FileUtils.cp(class_path, "#{class_path}.bak")
    end
    after(:each) do
      FileUtils.mv("#{template_path}.bak", template_path)
      FileUtils.mv("#{class_path}.bak", class_path)
      wait_for_code_reload_timing_issue
    end

    it "caches the fragment including the sub-component" do
      2.times { get "/caching/component" }
      expect(Thread.current[:cache_misses]).to eq 1
    end

    it "busts the cache if the sub-component's template changes" do
      get "/caching/component"
      expect(response.body).to have_tag("h2", text: "Hello from Cached thing")

      File.write(template_path, File.read(template_path).gsub("Hello", "Goodbye"))

      get "/caching/component"
      expect(response.body).to have_tag("h2", text: "Goodbye from Cached thing")

      expect(Thread.current[:cache_misses]).to eq 2
    end

    it "busts the cache if the sub-component's class source code changes" do
      get "/caching/component"
      expect(response.body).to have_tag("h2", text: "Hello from Cached thing")

      File.write(class_path, File.read(class_path).gsub("Cached thing", "Updated thing"))

      get "/caching/component"
      expect(response.body).to have_tag("h2", text: "Hello from Updated thing")

      expect(Thread.current[:cache_misses]).to eq 2
    end
  end

  describe "fragments including #call sub-components" do
    let(:class_path) { Rails.root.join("app/components/cached_thing_call_component.rb") }
    before(:each) { FileUtils.cp(class_path, "#{class_path}.bak") }
    after(:each) { FileUtils.mv("#{class_path}.bak", class_path); wait_for_code_reload_timing_issue }

    it "caches the fragment including the sub-component" do
      2.times { get "/caching/call_component" }
      expect(Thread.current[:cache_misses]).to eq 1
    end

    it "busts the cache if the sub-component's class source code changes" do
      get "/caching/call_component"
      expect(response.body).to have_tag("h2", text: "Hello from Cached thing")

      File.write(class_path, File.read(class_path).gsub("Cached thing", "Updated thing"))

      get "/caching/call_component"
      expect(response.body).to have_tag("h2", text: "Hello from Updated thing")

      expect(Thread.current[:cache_misses]).to eq 2
    end
  end

  describe "fragment including Rails partial renders via `render` helper" do
    let(:template_path) { Rails.root.join("app/views/caching/_partial_render_partial.rbx") }
    before(:each) { FileUtils.cp(template_path, "#{template_path}.bak") }
    after(:each) { FileUtils.mv("#{template_path}.bak", template_path); wait_for_code_reload_timing_issue }

    it "caches template fragments" do
      2.times { get "/caching/partial_render" }
      expect(Thread.current[:cache_misses]).to eq 1
    end

    it "busts the cache if the partial changes" do
      get "/caching/partial_render"
      expect(response.body).to have_tag("h2", text: "Hello from Cached partial")

      File.write(template_path, File.read(template_path).gsub("Cached partial", "Updated partial"))

      get "/caching/partial_render"
      expect(response.body).to have_tag("h2", text: "Hello from Updated partial")

      expect(Thread.current[:cache_misses]).to eq 2
    end
  end
end
