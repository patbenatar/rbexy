module Rbexy
  class CacheComponent < Rbexy::Component
    def setup(key:)
      @key = key
    end

    def call
      @current_template = view_context.instance_variable_get(:@current_template)

      capture do
        cache @key, virtual_path: @current_template.virtual_path do
          @output_buffer << content
        end
      end
    end
  end
end
