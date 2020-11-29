class CustomProviderController < ApplicationController
  def index; end

  private

  def rbexy_component_provider
    @rbexy_component_provider ||= MyProvider.new
  end

  class MyProvider
    def match?(name)
      true
    end

    def render(context, name, **attrs, &block)
      "<h1>Hello My Provider</h1>"
    end
  end
end
