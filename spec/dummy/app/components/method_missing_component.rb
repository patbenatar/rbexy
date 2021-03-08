class MethodMissingComponent < Rbexy::Component
  def method_relying_on_method_missing
    method_with_keywords(1, b: 2, c: 3).join(" ")
  end
end
