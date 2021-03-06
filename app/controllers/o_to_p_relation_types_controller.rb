# -*- encoding : utf-8 -*-
class OToPRelationTypesController < ApplicationController

  hobo_model_controller

  auto_actions :all

  caches_page :show, :expires_in => 10.minutes
  caches_page :index, :expires_in => 10.minutes


  def show
    @this = find_instance
    respond_to do |format| 
      format.html  { hobo_show @this }
      format.xml   { render(:xml => @this) }
      format.json  { render(:json=> @this) }
    end
  end


end

