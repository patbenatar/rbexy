# NOTE: These specs are only meant to run as a part of bin/test,
# where this file warms the cache, and then after_changes_spec.rb
# runs next to test source changes against a warm cache.

RSpec.describe CachingController, type: :request, retry: 5 do
  before(:each) { Thread.current[:cache_misses] = 0 }
  before(:all) { Rails.cache.clear }

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

    it "caches the fragment including the sub-component (class changes)" do
      2.times { get "/caching/component_class" }
      expect(Thread.current[:cache_misses]).to eq 1
    end
  end

  describe "fragments including #call sub-components" do
    it "caches the fragment including the sub-component" do
      2.times { get "/caching/call_component" }
      expect(Thread.current[:cache_misses]).to eq 1
    end
  end

  describe "fragment including Rails partial renders via `render` helper" do
    it "caches template fragments" do
      2.times { get "/caching/partial_render" }
      expect(Thread.current[:cache_misses]).to eq 1
    end
  end
end
