class ErroringInClassComponent < Rbexy::Component
  def a_defined_method
    an_undefined_method
  end
end
