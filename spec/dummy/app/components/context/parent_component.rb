class Context::ParentComponent < Rbexy::Component
  def setup
    create_context(:thing, "value")
  end
end
