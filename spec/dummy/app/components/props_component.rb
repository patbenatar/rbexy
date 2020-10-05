class PropsComponent < Rbexy::Component
  def setup(my_prop:)
    @my_prop_after = "#{my_prop} after setup"
  end
end
