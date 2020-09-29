module Rbexy
  module ViewHelper
    def create_context(name, value)
      rbexy_context.last[name] = value
    end

    def use_context(name)
      index = rbexy_context.rindex { |c| c.has_key?(name) }
      index ?
        rbexy_context[index][name] :
        raise(ContextNotFound, "no parent context `#{name}`")
    end

    def rbexy_context
      @rbexy_context ||= [{}]
    end

    def rbexy_tag
      @rbexy_tag ||= Runtime.create_tag_builder(self)
    end
  end
end
