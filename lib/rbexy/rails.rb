module Rbexy
  autoload :Component, "rbexy/component"

  module Rails
    autoload :TemplateHandler, "rbexy/rails/template_handler"
    autoload :Engine, "rbexy/rails/engine"
  end
end
