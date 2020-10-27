module Rbexy
  autoload :Component, "rbexy/component"

  module Rails
    autoload :Engine, "rbexy/rails/engine"
    autoload :ControllerHelper, "rbexy/rails/controller_helper"
    autoload :ComponentTemplateResolver, "rbexy/rails/component_template_resolver"
  end
end
