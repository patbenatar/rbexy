RSpec.describe CachingController, type: :request, retry: 5 do
  before(:each) { Thread.current[:cache_misses] = 0 }
  # after(:all) { Rails.cache.clear }

  describe "fragment caching using `<Rbexy.Cache />` component" do
    it "caches template fragments" do
      2.times { get "/caching/inline" }
      expect(Thread.current[:cache_misses]).to eq 1
    end
  end

  describe "fragments including template sub-components" do
    it "caches the fragment including the sub-component" do
      2.times { get "/caching/component" }
      expect(Thread.current[:cache_misses]).to eq 1
    end
  end

  describe "fragments including #call sub-components" do
    # let(:class_path) { Rails.root.join("app/components/cached_thing_call_component.rb") }
    # before(:each) { FileUtils.cp(class_path, "#{class_path}.bak") }
    # after(:each) { FileUtils.mv("#{class_path}.bak", class_path); wait_for_code_reload_timing_issue }

    it "caches the fragment including the sub-component" do
      2.times { get "/caching/call_component" }
      expect(Thread.current[:cache_misses]).to eq 1
    end

    # it "busts the cache if the sub-component's class source code changes" do
    #   get "/caching/call_component"
    #   expect(response.body).to have_tag("h2", text: "Hello from Cached thing")

    #   File.write(class_path, File.read(class_path).gsub("Cached thing", "Updated thing"))

    #   get "/caching/call_component"
    #   expect(response.body).to have_tag("h2", text: "Hello from Updated thing")

    #   expect(Thread.current[:cache_misses]).to eq 2
    # end
  end

  describe "fragment including Rails partial renders via `render` helper" do
    # let(:template_path) { Rails.root.join("app/views/caching/_partial_render_partial.rbx") }
    # before(:each) { FileUtils.cp(template_path, "#{template_path}.bak") }
    # after(:each) { FileUtils.mv("#{template_path}.bak", template_path); wait_for_code_reload_timing_issue }

    it "caches template fragments" do
      2.times { get "/caching/partial_render" }
      expect(Thread.current[:cache_misses]).to eq 1
    end

    # it "busts the cache if the partial changes" do
    #   get "/caching/partial_render"
    #   expect(response.body).to have_tag("h2", text: "Hello from Cached partial")

    #   File.write(template_path, File.read(template_path).gsub("Cached partial", "Updated partial"))

    #   get "/caching/partial_render"
    #   expect(response.body).to have_tag("h2", text: "Hello from Updated partial")

    #   expect(Thread.current[:cache_misses]).to eq 2
    # end
  end
end
