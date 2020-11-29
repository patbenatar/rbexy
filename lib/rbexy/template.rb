module Rbexy
  class Template
    attr_reader :source, :identifier

    def initialize(source)
      @source = source
      @identifier = nil
    end
  end
end
