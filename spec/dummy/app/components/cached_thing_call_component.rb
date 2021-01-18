class CachedThingCallComponent < Rbexy::Component
  def call
    Thread.current[:cache_misses] += 1
    tag.h2 "Hello from #{name}"
  end

  def name
    "Updated thing"
  end
end
