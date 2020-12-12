RSpec.describe Rbexy::Refinements::Array::FindMap do
  using Rbexy::Refinements::Array::FindMap

  it "returns the mapped value of the first truthy result from the block" do
    result = [1, 2, 3, 4].find_map do |value|
      if value == 1
        false
      elsif value == 2
        nil
      elsif value == 3
        "found it"
      end
    end

    expect(result).to eq "found it"
  end

  it "short-circuits as soon as it finds a truthy result" do
    evaluator = double()

    expect(evaluator).to receive(:test_value) do |value|
      if value == 1
        false
      elsif value == 2
        "found it"
      elsif value == 3
        false
      end
    end.exactly(2).times

    result = [1, 2, 3, 4].find_map { |v| evaluator.test_value(v) }

    expect(result).to eq "found it"
  end
end
