RSpec.describe Rbexy::Rails::RbxDependencyTracker do
  describe "#dependencies" do
    it "returns the paths to all sub-component templates for a given template" do
      redefine do
        Sub1Component = Class.new(Rbexy::Component)
        Sub2Component = Class.new(Rbexy::Component)
      end

      template = double(source: "<Sub1 /><Sub2 />")
      tracker = described_class.new("parent_template", template)

      result = tracker.dependencies
      expect(result).to include "sub1_component"
      expect(result).to include "sub2_component"
    end

    it "doesn't return multiple of the same template path" do
      redefine { Sub1Component = Class.new(Rbexy::Component) }

      template = double(source: "<Sub1 /><Sub1 />")
      tracker = described_class.new("parent_template", template)

      result = tracker.dependencies
      expect(result).to eq ["sub1_component"]
    end

    it "doesn't return template paths for template-less (#call) components" do
      redefine do
        Sub1Component = Class.new(Rbexy::Component) do
          def call; end
        end
        Sub2Component = Class.new(Rbexy::Component)
      end

      template = double(source: "<Sub1 /><Sub2 />")
      tracker = described_class.new("parent_template", template)

      result = tracker.dependencies
      expect(result).to eq ["sub2_component"]
    end
  end
end
