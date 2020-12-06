# TODO: write a Rails integration test too, to ensure it works with ActionView::Template not just Rbexy::Template

RSpec.describe Rbexy::ComponentResolver do
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

    context "namespaces" do
      context "template path is within a given namespace" do
        it "first tries to resolve the component in the namespace" do
          subject = Rbexy::ComponentResolver.new
          template = Rbexy::Template.new("", File.join("path", "to", "the", "file.rbx"))

          redefine do
            module Things
              ButtonComponent = Class.new
            end
          end

          subject.component_namespaces = {
            File.join("path", "to") => %w[Things]
          }

          result = subject.component_class("Button", template)
          expect(result).to eq Things::ButtonComponent
        end

        it "tries each matching namespace in order" do
          subject = Rbexy::ComponentResolver.new
          template = Rbexy::Template.new("", File.join("path", "to", "the", "file.rbx"))

          redefine do
            module Things1; end
            Things2.send(:remove_const, :ButtonComponent) if Things1.constants.include?(:ButtonComponent)

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
            File.join("path", "from") => %w[Things2],
            File.join("path") => %w[Things1],
            File.join("path", "to") => %w[Things3 Things4]
          }

          result = subject.component_class("Button", template)
          expect(result).to eq Things3::ButtonComponent
        end

        it "falls back to the root namespace if no given namespaces resolve" do
          subject = Rbexy::ComponentResolver.new
          template = Rbexy::Template.new("", File.join("path", "to", "the", "file.rbx"))

          redefine do
            ButtonComponent = Class.new

            module Things; end
            Things.send(:remove_const, :ButtonComponent) if Things.constants.include?(:ButtonComponent)
          end

          subject.component_namespaces = {
            File.join("path", "to") => %w[Things]
          }

          result = subject.component_class("Button", template)
          expect(result).to eq ButtonComponent
        end
      end

      context "template path does not match a given namespace" do
        it "resolves in the root namespace" do
          subject = Rbexy::ComponentResolver.new
          template = Rbexy::Template.new("", File.join("path", "from", "the", "file.rbx"))

          redefine do
            ButtonComponent = Class.new

            module Things
              ButtonComponent = Class.new
            end
          end

          subject.component_namespaces = {
            File.join("path", "to") => %w[Things]
          }

          result = subject.component_class("Button", template)
          expect(result).to eq ButtonComponent
        end
      end
    end
  end
end
