module Rbexy
  class Template
    attr_reader :source, :identifier

    Anonymous = Class.new(String)

    def initialize(source, identifier = Anonymous.new)
      @source = source
      @identifier = identifier
    end
  end
end
