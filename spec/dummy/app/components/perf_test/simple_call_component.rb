class PerfTest::SimpleCallComponent < Rbexy::Component
  def call
    tag.h2 "Hello call component"
  end
end
