# -*- encoding : utf-8 -*-
class ArticlesController < ApplicationController

  hobo_model_controller

  auto_actions :all

  autocomplete

  caches_page :show,  :expires_in => 10.minutes
  caches_page :index, :expires_in => 10.minutes


  def new
    fill_drop_down
    hobo_new
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
    @person_to_orgs = @this.person_to_org_relations.paginate(:per_page=>10, :page=>params[:page])
  end

  def edit
    @this = find_instance
    fill_drop_down
  end

  def show
    @this = find_instance
    @interpersonal_relations = @this.interpersonal_relations.paginate(:per_page=>10, :page=>params[:page])
    @interorg_relations = @this.interorg_relations.paginate(:per_page=>10, :page=>params[:page])
    @person_to_org_relations = @this.person_to_org_relations.paginate(:per_page=>10, :page=>params[:page])

    respond_to do |format|
      format.html  { hobo_show @this }
      format.xml   { render(:xml => @this) }
      format.json  { render(:json=> @this) }
    end
  end


end


