module Rbexy
  module Rails
    class TemplateHandler
      def self.call(template, source)
        Rbexy.compile(source)
      end
    end
  end
end
