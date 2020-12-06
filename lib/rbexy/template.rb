module Rbexy
  class Template
    attr_reader :source, :identifier

    Anonymous = Class.new(String).new.freeze

    def initialize(source, identifier = Anonymous)
      @source = source
      @identifier = identifier
    end
  end
end
