RSpec.describe Rbexy::ComponentResolver do
  # use template.identifier, which is the abs path to the template in Rails
  describe "#component_class" do
    it "resolves strings to constants ending with Component" do
      subject = Rbexy::ComponentResolver.new
      redefine { ButtonComponent = Class.new }

      result = subject.component_class("Button", Rbexy::Template.new(""))
      expect(result).to eq ButtonComponent
    end

    it "is nil if no matching constant exists" do
      subject = Rbexy::ComponentResolver.new

      result = subject.component_class("SomeNonexistentThing", Rbexy::Template.new(""))
      expect(result).to eq nil
    end

    it "expands dot-notation to Ruby's :: namespace notation" do
      subject = Rbexy::ComponentResolver.new
      redefine do
        module Things
          ButtonComponent = Class.new
        end
      end

      result = subject.component_class("Things.Button", Rbexy::Template.new(""))
      expect(result).to eq Things::ButtonComponent
    end

    context "caching" do
      it "doesn't need to resolve the same name twice" do
        subject = Rbexy::ComponentResolver.new
        redefine { ButtonComponent = Class.new }

        expect(subject).to receive(:find!).and_call_original
        subject.component_class("Button", Rbexy::Template.new(""))

        expect(subject).not_to receive(:find!)
        subject.component_class("Button", Rbexy::Template.new(""))
      end
    end

    context "namespaces" do
      context "template path is within a given namespace" do
        it "first tries to resolve the component in the namespace" do
          subject = Rbexy::ComponentResolver.new
          redefine do
            module Things
              ButtonComponent = Class.new
            end
          end

          subject.component_namespaces = {
            File.join("path", "to") => "Things"
          }

          result = subject.component_class("Button", Rbexy::Template.new(""))
          expect(result).to eq Things::ButtonComponent
        end

        it "tries each matching namespace in order" do
          subject = Rbexy::ComponentResolver.new
          redefine do
            module Things1
            end

            module Things2
              ButtonComponent = Class.new
            end

            module Things3
              ButtonComponent = Class.new
            end

            module Things4
              ButtonComponent = Class.new
            end
          end

          subject.component_namespaces = {
            File.join("path", "to") => "Things1",
            File.join("path", "from") => "Things2",
            File.join("path", "to") => "Things3",
            File.join("path", "to") => "Things4"
          }

          result = subject.component_class("Button", Rbexy::Template.new(""))
          expect(result).to eq Things3::ButtonComponent
        end

        it "falls back to the root namespace if no given namespaces resolve" do
          subject = Rbexy::ComponentResolver.new
          template = Rbexy::Template.new("", File.join(""))

          redefine do
            ButtonComponent = Class.new

            module Things
            end
          end

          subject.component_namespaces = {
            File.join("path", "to") => "Things"
          }

          result = subject.component_class("Button", )
          expect(result).to eq ButtonComponent
        end
      end

      context "template path does not match a given namespace" do
        it "resolves in the root namespace"
      end
    end
  end
end
