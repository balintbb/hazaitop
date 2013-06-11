# -*- encoding : utf-8 -*-
class NotificationsController < ApplicationController

  hobo_model_controller

  auto_actions :all

  autocomplete

  caches_page :show, :expires_in => 180.minutes
  caches_page :index, :expires_in => 180.minutes


end

