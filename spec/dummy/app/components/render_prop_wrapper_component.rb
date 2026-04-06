class RenderPropWrapperComponent < Rbexy::Component
  def setup(label:)
    @label = label
  end

  def render_label
    @label.call(class: "label-class", data: {action: "click"})
  end
end
