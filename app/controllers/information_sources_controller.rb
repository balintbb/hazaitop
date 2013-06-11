# -*- encoding : utf-8 -*-
class InformationSourcesController < ApplicationController

  hobo_model_controller

  auto_actions :all

  def show
    @this = find_instance
    respond_to do |format| 
      format.html  { hobo_show @this }
      format.xml   { render(:xml => @this) }
      format.json  { render(:json=> @this) }
    end
  end


end

