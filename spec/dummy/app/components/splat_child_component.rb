class SplatChildComponent < Rbexy::Component
  def setup(to: "#")
    @to = to
  end

  def extra_attrs
    {class: ["child-link", "active"], data: {test: "value"}}
  end
end
