# -*- encoding : utf-8 -*-
class LitigationsController < ApplicationController

  hobo_model_controller

  auto_actions :all


  caches_page :interpersonal_pagination, :expires_in => 10.minutes
  caches_page :interorg_pagination, :expires_in => 10.minutes
  caches_page :person_to_org_pagination, :expires_in => 10.minutes

  caches_page :show, :expires_in => 10.minutes
  caches_page :index, :expires_in => 10.minutes



  index_action :query do
    render :json => Litigation.name_contains(params[:term]).order_by(:name).limit(100).all(:select=>'id, name').map {|litigation|
      {:label => litigation.name, :id => litigation.id}
    }
  end

  index_action :interpersonal_pagination do
    @this = find_instance
    return unless @this
    @interpersonals = @this.interpersonal_relations.paginate(:per_page=>10, :page=>params[:page])
  end

  index_action :interorg_pagination do
    @this = find_instance
    return unless @this
    @interorgs = @this.interorg_relations.paginate(:per_page=>10, :page=>params[:page])
  end

  index_action :person_to_org_pagination do
    @this = find_instance
    return unless @this
    @person_to_orgs = @this.interorg_relations.paginate(:per_page=>10, :page=>params[:page])
  end

  def show
    @this = find_instance
  end
end

