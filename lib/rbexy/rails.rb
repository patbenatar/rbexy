module Rbexy
  autoload :Component, "rbexy/component"
  autoload :CacheComponent, "rbexy/cache_component"

  module Rails
    autoload :Engine, "rbexy/rails/engine"
    autoload :ControllerHelper, "rbexy/rails/controller_helper"
    autoload :ComponentTemplateResolver, "rbexy/rails/component_template_resolver"
    autoload :RbxDependencyTracker, "rbexy/rails/rbx_dependency_tracker"
  end
end
