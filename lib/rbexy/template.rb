module Rbexy
  class Template
    attr_reader :source, :virtual_path

    def initialize(source)
      @source = source
      @virtual_path = nil
    end
  end
end
