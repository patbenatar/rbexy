class CachingController < ApplicationController
  def inline; end
  def component; end

  helper_method :outer_text_from_controller, :inner_text_from_controller

  def outer_text_from_controller
    "Outer text from controller"
  end

  def inner_text_from_controller
    "Inner text from controller"
  end
end
