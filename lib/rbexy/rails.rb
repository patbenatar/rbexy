module Rbexy
  autoload :Component, "rbexy/component"

  module Rails
    autoload :Engine, "rbexy/rails/engine"
    autoload :ControllerHelper, "rbexy/rails/controller_helper"
  end
end
