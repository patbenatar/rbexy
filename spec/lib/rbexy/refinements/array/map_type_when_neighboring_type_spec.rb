RSpec.describe Rbexy::Refinements::Array::MapTypeWhenNeighboringType do
  using Rbexy::Refinements::Array::MapTypeWhenNeighboringType

  it "yields the item for mapping if its type matches match_type and one of its neighbors matches neighbor_type" do
    original = ["welcome", 1, "hello", { foo: "bar" }, "world", 2, { baz: "bip" }, "!", "#"]
    result = original.map_type_when_neighboring_type(String, Hash) { |v| "#{v} mapped" }
    expect(result).to eq ["welcome", 1, "hello mapped", { foo: "bar" }, "world mapped", 2, { baz: "bip" }, "! mapped", "#"]
  end
end
