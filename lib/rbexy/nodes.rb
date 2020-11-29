module Rbexy
  module Nodes
    autoload :Util, "rbexy/nodes/util"
    autoload :Base, "rbexy/nodes/base"
    autoload :Template, "rbexy/nodes/template"
    autoload :Raw, "rbexy/nodes/raw"
    autoload :Text, "rbexy/nodes/text"
    autoload :ExpressionGroup, "rbexy/nodes/expression_group"
    autoload :Expression, "rbexy/nodes/expression"
    autoload :XmlNode, "rbexy/nodes/xml_node"
    autoload :XmlAttr, "rbexy/nodes/xml_attr"
    autoload :SilentNewline, "rbexy/nodes/silent_newline"
    autoload :Declaration, "rbexy/nodes/declaration"
  end
end
