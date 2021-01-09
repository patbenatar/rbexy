RSpec.describe Rbexy::Rails::ComponentTemplateResolver do
  describe "#find_templates" do
    it "finds rbx templates"
    it "finds erb templates"
    it "appends a cachebuster comment to the template source, so changes to the class definition itself will bust fragment caches"

    context "not a component path" do
      it "returns an empty array, even if the given path would match a component"
    end

    context "no template file exists" do
      it "returns an empty array"

      context "component class is a #call component" do
        it "returns a template containing just the cachebuster comment"
      end
    end
  end
end
