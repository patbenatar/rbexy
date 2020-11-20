class ContextController < ApplicationController
  def index
    create_context(:thing, "Hello context from controller")
  end
end
