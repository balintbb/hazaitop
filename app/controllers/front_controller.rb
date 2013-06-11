# -*- encoding : utf-8 -*-
class FrontController < ApplicationController

  hobo_model_controller

  caches_page :index, :expires_in => 4.minutes
  caches_page :impressum, :expires_in => 90.minutes
  caches_page :about, :expires_in => 90.minutes
  caches_page :how_it_works, :expires_in => 90.minutes
  caches_page :contact, :expires_in => 90.minutes
  caches_page :development, :expires_in => 90.minutes
  caches_page :person_pagination, :expires_in => 4.minutes
  caches_page :org_pagination, :expires_in => 4.minutes
  caches_page :trans_pagination, :expires_in => 4.minutes

  def index
    @people        = Person.order_by(:person_to_org_relations_count, 'desc').paginate(:per_page=>10, :page=>params[:page])
    @organizations = Organization.order_by(:person_to_org_relations_count, 'desc').paginate(:per_page=>10, :page=>params[:page])
    @transactions  = InterorgRelation.order_by(:value, 'desc').not_mirror.value_is_not('').paginate(:per_page=>10, :page=>params[:page])    
  end

  index_action :person_pagination do
      @people = Person.apply_scopes(:order_by => parse_sort_param(:person_to_org_relations_count, :interpersonal_relations_count, :updated_at, :search_result_count, :selected_organization, :information_source)).paginate(:per_page=>10, :page=>params[:page])
  end

  index_action :org_pagination do
    @organizations = Organization.apply_scopes(:order_by => parse_sort_param(:person_to_org_relations_count, :interorg_relations_count, :updated_at, :search_result_count, :address, :information_source)).paginate(:per_page=>10, :page=>params[:page])
  end

  index_action :trans_pagination do
    @transactions = InterorgRelation.value_is_not('').not_mirror.apply_scopes(:order_by=> parse_sort_param(:value, :issued_at, :name, :search_result_count , :organization, :o_to_o_relation_type, :related_organization, :information_source)).paginate(:per_page=>10, :include=>[:organization, :related_organization, :o_to_o_relation_type, {:o_to_o_relation_type => :pair}], :page=>params[:page])
  end

  def how_it_works; end
  def about; end
  def contact; end
  def impressum; end
  def development; end

  def summary ; end

  def api ; end

  def search               
    query = params[:query] || ""
    # főoldalről érkező ajaxos keresés
    if request.xhr?
      @organizations = Organization.search(query, :name).paginate(:per_page=>10, :page=>params[:page])
      @people        = Person.search(query, :name).paginate(:per_page=>10, :page=>params[:page])
      @litigations   = Litigation.search(query, :name).paginate(:per_page=>10, :page=>params[:page])
      @articles      = Article.search(query, :name).paginate(:per_page=>10, :page=>params[:page])
      @contracts     = Contract.search(query, :name).paginate(:per_page=>10, :page=>params[:page])
      @tenders       = Tender.search(query, :name).paginate(:per_page=>10, :page=>params[:page])
      render_tags(@organizations+@people+@litigations+@articles+@contracts+@tenders, :search_card, :for_type => true) 
    end
  end
end
