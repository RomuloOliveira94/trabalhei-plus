class HomeController < ApplicationController
  def show
    redirect_to overtimes_path if user_signed_in?
  end
end
