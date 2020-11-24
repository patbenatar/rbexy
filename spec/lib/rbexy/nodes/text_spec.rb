RSpec.describe Rbexy::Nodes::Text do
  describe "#precompile" do
    it "converts to raw" do
      result = Rbexy::Nodes::Text.new("Some text").precompile
      expect(result.length).to eq 1
      expect(result.first).to be_a Rbexy::Nodes::Raw
      expect(result.first.content).to eq "Some text"
    end
  end
end
