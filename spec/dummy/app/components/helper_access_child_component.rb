class HelperAccessChildComponent < Rbexy::Component
  def formatted_list
    safe_join(["one", "two", "three"], ", ")
  end
end
