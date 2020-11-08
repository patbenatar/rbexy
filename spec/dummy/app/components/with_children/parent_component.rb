class WithChildren::ParentComponent < Rbexy::Component
  # def call
  #   binding.pry
  #   super
  # end

  def content
    binding.pry
    super
  end
end
