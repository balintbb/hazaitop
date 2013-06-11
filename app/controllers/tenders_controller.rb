# -*- encoding : utf-8 -*-
class TendersController < ApplicationController

  hobo_model_controller

  auto_actions :all

  caches_page :index, :expires_in => 180.minutes
  caches_page :show, :expires_in => 10.minutes

end

