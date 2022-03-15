class PerfTest::CallComponent < Rbexy::Component
  def call
    tag.div "Hello world"
  end
end
