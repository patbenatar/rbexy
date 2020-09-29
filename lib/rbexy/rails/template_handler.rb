module Rbexy
  module Rails
    class TemplateHandler
      def self.call(view_object, source)
        Rbexy.compile(source)
      end
    end
  end
end
