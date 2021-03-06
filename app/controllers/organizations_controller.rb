# -*- encoding : utf-8 -*-
class OrganizationsController < ApplicationController

  hobo_model_controller

  
   include Hobofix
   
  auto_actions :all #, :except => [:new, :create, :edit, :update ] 

  autocomplete

  caches_page :show,  :expires_in => 10.minutes
  caches_page :index, :expires_in => 10.minutes

  caches_page :person_to_org_pagination, :expires_in => 20.minutes
  caches_page :interorg_pagination, :expires_in => 20.minutes
  caches_page :financial_pagination, :expires_in => 20.minutes
  caches_page :list, :expires_in => 20.minutes

  def create
    add_new_entities
    if flash[:errors].present?
      redirect_to new_organization_path and return 
    else
      hobo_create
    end
  end

  def update
    render :text => "access denied" unless current_user.administrator? or current_user.editor? or current_user.supervisor?
    add_new_entities    
    params[:organization][:manual_person_to_org_relations].each_pair do |k,v| 
      if v[:person]
        params[:organization][:manual_person_to_org_relations][k][:person_id] = v[:person].split('(ID:')[1].chop if v[:person]
      else
        params[:organization][:manual_person_to_org_relations].delete k
      end
      params[:organization][:manual_person_to_org_relations][k].delete :person
    end if params[:organization][:manual_person_to_org_relations].present?
    params[:organization][:manual_interorg_relations].each_pair do |k,v| 
      if v[:related_organization]
        params[:organization][:manual_interorg_relations][k][:related_organization_id] = v[:related_organization].split('(ID:')[1].chop if v[:related_organization]
      else
        params[:organization][:manual_interorg_relations].delete k
      end
      params[:organization][:manual_interorg_relations][k].delete :related_organization
    end if  params[:organization][:manual_interorg_relations].present?
    redirect_to edit_organization_path(params[:id]) and return if flash[:errors].present?
    @organization = find_instance
    hobo_update
    if @organization.valid?
      OrgHistory.create( :user_id => current_user.id, :organization_id => @organization.id, :parameters => params.inspect ) 
    end
  rescue => e
    logger.info e.backtrace.join("\n")
    logger.info "**************** update org error happened ***********************"
    logger.info e.inspect
  end

  def add_new_entities
    return true
    info_source = InformationSource.find_or_create_by_name('ahalo.hu') do |r| r.name = 'ahalo.hu'; r.web = 'http://ahalo.hu' end

    if !params[:organization][:person_to_org_relations].blank?
      params[:organization][:person_to_org_relations].each do |k,p|
        if p[:person].blank?
          flash[:errors] = 'related entity cannot be blank'
        elsif !Person.find_by_name(p[:person])
          first_name = p[:person].split(' ')
          last_name = first_name.shift
          first_name = first_name.join(' ')
          Person.create( :first_name => first_name,
                         :last_name => last_name, 
                         :user_id => current_user.id,
                         :information_source_id => p[:information_source_id].blank? ? info_source.id : p[:information_source_id]
                       )
        end
        if !p[:article_relations].blank?
          p[:article_relations].each do |k,a|
            next if k.to_i == -1
            if a[:article].blank? or !Article.find_by_name( a[:article] )
              if flash[:errors].present?
                flash[:errors] << "\nArticle does not exist for #{p[:person]} with name #{a[:article]}"
              else
                flash[:errors] = "Article does not exist for #{p[:person]} with name #{a[:article]}"
              end
            end
          end
        end
      end
    end
    if !params[:organization][:interorg_relations].blank?
      params[:organization][:interorg_relations].each do |k,o|
        if o[:related_organization].blank?
          flash[:errors] = 'related entity cannot be blank'
        elsif !Organization.find_by_name(o[:related_organization])
          Organization.create(:name => o[:related_organization], 
                              :user_id => current_user.id,
                              :information_source_id => o[:information_source_id].blank? ? info_source.id : o[:information_source_id]
                             )
        end
        if !o[:article_relations].blank?
          o[:article_relations].each do |k,a|
            next if k.to_i == -1
            if a[:article].blank? or !Article.find_by_name( a[:article] )
              if flash[:errors].present?
                flash[:errors] << "\nArticle does not exist for #{o[:related_organization]} with name #{a[:article]}"
              else
                flash[:errors] = "Article does not exist for #{o[:related_organization]} with name #{a[:article]}"
              end
            end
          end
        end
      end
    end
  end

  def first_page
    redirect_to "/organizations/#{params[:id]}?sort=#{params[:sort]}"
  end

  index_action :financial_pagination do
	params[:page] ||= 1
	@org_sort = params[:sort] || "year"
    @this = find_instance
    return unless @this
    #@financials = @this.financials.paginate(:per_page=>20, :page=>params[:page])
	@financials = Financial.apply_scopes(:order_by => parse_sort_param(@org_sort), :organization_id_is => @this.id).paginate(:per_page=>20, :page=>params[:page])
  end  
  
  index_action :interorg_pagination do
    params[:page] ||= 1
    @org_sort = params[:sort] || "related_organization"
    @this = find_instance
    return unless @this
	case @org_sort
	when 'value','currency','vat_incl' then
		@interorgs = InterorgRelation.apply_scopes(:order_by => @org_sort, :organization_id_is => @this.id).paginate(:per_page=>20, :page=>params[:page])
	when 'related_organization' then
		@interorgs = InterorgRelation.apply_scopes(:organization_id_is => @this.id).paginate(:per_page=>20, :page=>params[:page], :joins => "inner join organizations on interorg_relations.related_organization_id = organizations.id", :order => "organizations.name ASC")
	when 'o_to_o_relation_type' then
		@interorgs = InterorgRelation.apply_scopes(:organization_id_is => @this.id).paginate(:per_page=>20, :page=>params[:page], :joins => "inner join o_to_o_relation_types on interorg_relations.o_to_o_relation_type_id = o_to_o_relation_types.id", :order => "o_to_o_relation_types.name ASC")
	when 'contract' then
		@interorgs = InterorgRelation.apply_scopes(:organization_id_is => @this.id).paginate(:per_page=>20, :page=>params[:page], :joins => "left outer join contracts on interorg_relations.contract_id = contracts.id", :order => "contracts.description ASC")
	when 'tender' then
		@interorgs = InterorgRelation.apply_scopes(:organization_id_is => @this.id).paginate(:per_page=>20, :page=>params[:page], :joins => "left outer join tenders on interorg_relations.tender_id = tenders.id", :order => "tenders.project ASC")
	when 'information_source' then
		@interorgs = InterorgRelation.apply_scopes(:organization_id_is => @this.id).paginate(:per_page=>20, :page=>params[:page], :joins => "inner join information_sources on interorg_relations.information_source_id = information_sources.id", :order => "information_sources.name ASC")
	end
  end
  
  
  index_action :person_to_org_pagination do
    params[:page] ||= 1
    @org_sort = params[:sort] || "person"
    @this = find_instance
    return unless @this
    if @org_sort[-4..-1] == 'time' # ha időre rendeznek és nem kapcsolótáblára
      @person_to_orgs = PersonToOrgRelation.apply_scopes(:order_by =>  @org_sort, :organization_id_is => @this.id).paginate(:per_page=>20, :page=>params[:page])
    else
      @person_to_orgs = PersonToOrgRelation.ordered(@org_sort).apply_scopes(:organization_id_is => @this.id).paginate(:per_page=>20, :page=>params[:page])
    end
  end
  
  index_action :list do
    params[:page] ||= 1
    @org_sort = params[:sort] || "name"
    #@this = find_instance
    #return unless @this  
	case @org_sort
	when "name","updated_at","relations_counter", "address", "founded_at"  then 
		@organizations = Organization.relations_counter_is_not(0).apply_scopes(:order_by => parse_sort_param(@org_sort)).paginate(:per_page=>20, :page=>params[:page])
	when "information_source" then 
		@organizations = Organization.relations_counter_is_not(0).paginate(:per_page=>20, :page=>params[:page], :joins => "inner join information_sources on organizations.information_source_id = information_sources.id", :order => "information_sources.name ASC")		
	end  
  
  end
 


  
=begin  
    index_action :interpersonal_pagination do
    params[:page] ||= 1
    @people_sort = params[:sort] || "related_person"
    @this = find_instance
    return unless @this
    if @people_sort[-4..-1] == 'time' # ha időre rendeznek és nem kapcsolótáblára
      @interpersons = InterpersonalRelation.apply_scopes(:order_by =>  @people_sort, :person_id_is => @this.id).paginate(:per_page=>10, :page=>params[:page])
    else
      @interpersons = InterpersonalRelation.ordered(@people_sort).apply_scopes(:person_id_is => @this.id).paginate(:per_page=>10, :page=>params[:page])
    end
  end
=end

=begin  
  index_action :interorg_pagination do
    params[:page] ||= 1
    first_page and return unless params[:page]
    @this = find_instance
    return unless @this
    @interorgs = @this.interorg_relations.paginate(:per_page=>12, :page=>params[:page])
  end
=end


  def index
    @this = Organization.relations_counter_is_not(0).order_by(:name)
    respond_to do |format| 
      format.html  { hobo_index( @this, :per_page => 20, :include => :information_source ) }
      format.xml   { render( :xml  => @this ) and return }
      format.json  { render( :json => @this ) and return }
    end
  end

  def show
  
  
    @this               = find_instance  
	
  
	@chart_text=""
  

    @cdata = []
    @sort = params[:sort]
    params[:sort] ||= "related_person"
    @this = find_instance

    if InterorgRelation.field_specs[params[:sort].to_sym]
      sorter = params[:sort]
    else
      sorter = "related_organization"
    end
=begin	
    if sorter[-4..-1] == 'time' # ha időre rendeznek és nem kapcsolótáblára
      @orgs = InterorgRelation.apply_scopes(:order_by => sorter, :organization_id_is => @this.id).paginate(:per_page=>5, :page=>params[:page])
    else
      @orgs = InterorgRelation.ordered(sorter).apply_scopes(:organization_id_is => @this.id).paginate(:per_page=>6, :page=>params[:page])
    end
=end	
	
	@interorgs = InterorgRelation.apply_scopes(:organization_id_is => @this.id).paginate(:per_page=>20, :page=>params[:page], :joins => "inner join organizations on interorg_relations.related_organization_id = organizations.id", :order => "organizations.name ASC")
    
	if PersonToOrgRelation.field_specs[params[:sort].to_sym]		
      sorter = params[:sort]
    else		
      sorter = "person"
    end
	
    if sorter[-4..-1] == 'time' # ha időre rendeznek és nem kapcsolótáblára		
      @people = PersonToOrgRelation.apply_scopes(:order_by => sorter, :organization_id_is => @this.id).paginate(:per_page=>10, :page=>params[:page])
    else
      @people = PersonToOrgRelation.apply_scopes(:organization_id_is => @this.id).order_by(sorter).paginate(:per_page=>10, :page=>params[:page])
	  #@people = PersonToOrgRelation.paginate(:per_page=>200, :page=>params[:page])      
    end
	
	#@people = PersonToOrgRelation.apply_scopes(:organization_id_is => @this.id).order_by("person").paginate(:per_page=>8, :page=>params[:page])
	
	
	@s1="[";
	@s2="[";
	first1=true
	first2=true
	@sum_tr_val1=0
	@sum_tr_val2=0
	@d_min1=nil
	@d_max1=nil
	@d_min2=nil
	@d_max2=nil
	@this.interorg_relations.value_is_not(0).limit(20).each do |rel|
		if  rel.o_to_o_relation_type_id == 11 and rel.currency == "HUF"
			@d_min1=rel.issued_at if first1
			@d_max1=rel.issued_at if first1

			@d_min1=rel.issued_at if @d_min1>rel.issued_at
			@d_max1=rel.issued_at if @d_max1<rel.issued_at

			@s1+="," unless first1
			first1=false
			@s1+="{"
			@s1+="\"y\":"+rel.value.to_s+","
			@s1+="\"name\":\""+rel.related_organization.name.scan(/./)[0..42].join('')+'...'+"\""
			@s1+="}"
			@sum_tr_val1+=+rel.value
			#{"y":43460626,"name":"Taksony Nagyk\u00f6zs\u00e9g \u00d6nkorm\u00e1nyzata..."}
			#@cdata << { :name =>  (rel.related_organization.name.scan(/./)[0..42].join('')+'...'), :y => rel.value}
		end
		if  rel.o_to_o_relation_type_id == 12 and rel.currency == "HUF"
			@d_min2=rel.issued_at if first2
			@d_max2=rel.issued_at if first2

			@d_min2=rel.issued_at if @d_min2>rel.issued_at
			@d_max2=rel.issued_at if @d_max2<rel.issued_at

			@s2+="," unless first2
			first2=false
			@s2+="{"
			@s2+="\"y\":"+rel.value.to_s+","
			@s2+="\"name\":\""+rel.related_organization.name.scan(/./)[0..42].join('')+'...'+"\""
			@s2+="}"
			@sum_tr_val2+=+rel.value
			#{"y":43460626,"name":"Taksony Nagyk\u00f6zs\u00e9g \u00d6nkorm\u00e1nyzata..."}
			#@cdata << { :name =>  (rel.related_organization.name.scan(/./)[0..42].join('')+'...'), :y => rel.value}
		end		
	end
	@s1+="]"
	@s2+="]"
	@s1=nil if first1
	@s2=nil if first2
    respond_to do |format| 
      format.html  { 
        hobo_show @this 
        @h = LazyHighCharts::HighChart.new('pie') do |f|
          f.options[:chart][:defaultSeriesType] = "pie"
          f.options[:title][:text] = "Top tranzakciók"
           f.options[:subtitle][:text] = "sub"
          f.series(:data=> @cdata)
        end
      }

      format.xml   { render( :xml  => { "data" =>  @this, "interorg_relations"  => @this.interorg_relations, "person_to_org_relations" => @this.person_to_org_relations } ) }
      format.json  { render( :json => { "data"=>  @this,  "interorg_relations"  => @this.interorg_relations, "person_to_org_relations" => @this.person_to_org_relations } ) }
    end
  end

  index_action :query do
    render :json => Organization.name_contains(params[:term]).order_by(:name).limit(40).all(:select=>'id, name').map {|org|
      {:label => "#{org.name} (ID:#{org.id})", :id => org.id}
    }
  end




  show_action :merge do
    merge_into = find_instance
    to_merge = Organization.find_by_id(params[:organization][:merge_from][:organization].split('(ID:')[1].chop)
    if !to_merge
      flash.now[:error] = "Ez a merge már megtörtént!"
    else
      if merge_into.id == to_merge.id
        flash.now[:error] = "Nem lehet szervezetet önmagával egyesíteni!"
      else
        merged = Organization.merge merge_into, to_merge
        OrgHistory.create( :user_id => current_user.id, :organization_id => merge_into.id, :parameters => "#{params.inspect}, #{merged}") 
        flash.now[:notice] = "#{to_merge.name} kapcsolatai sikeresen hozzáadva!"
      end
    end
    hobo_show merge_into
    render :show
  end
end

