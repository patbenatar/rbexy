class Context::ChildComponent < Rbexy::Component
  def setup
    @thing = use_context(:thing)
  end
end
