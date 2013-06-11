# -*- encoding : utf-8 -*-
class ContractsController < ApplicationController

  hobo_model_controller

  auto_actions :all

  caches_page :show,  :expires_in => 10.minutes
  caches_page :index, :expires_in => 10.minutes

  
  
  def show
	 @this = find_instance  
  end

end

