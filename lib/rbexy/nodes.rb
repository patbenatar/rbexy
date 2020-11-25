module Rbexy
  module Nodes
    autoload :Util, "rbexy/nodes/util"
    autoload :AbstractNode, "rbexy/nodes/abstract_node"
    autoload :Root, "rbexy/nodes/root"
    autoload :Raw, "rbexy/nodes/raw"
    autoload :Text, "rbexy/nodes/text"
    autoload :ExpressionGroup, "rbexy/nodes/expression_group"
    autoload :Expression, "rbexy/nodes/expression"
    autoload :XMLNode, "rbexy/nodes/xml_node"
    autoload :HTMLElement, "rbexy/nodes/html_element"
    autoload :Component, "rbexy/nodes/component"
    autoload :XMLAttr, "rbexy/nodes/xml_attr"
    autoload :HTMLAttr, "rbexy/nodes/html_attr"
    autoload :ComponentProp, "rbexy/nodes/component_prop"
    autoload :SilentNewline, "rbexy/nodes/silent_newline"
    autoload :Declaration, "rbexy/nodes/declaration"
  end
end
