class Context::SiblingComponent < Rbexy::Component
  def setup
    @thing = use_context(:thing)
  end
end
