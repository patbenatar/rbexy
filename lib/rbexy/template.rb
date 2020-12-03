module Rbexy
  class Template
    attr_reader :source, :identifier

    def initialize(source, identifier = nil)
      @source = source
      @identifier = identifier
    end
  end
end
