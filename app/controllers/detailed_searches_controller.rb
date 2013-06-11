class DetailedSearchesController < ApplicationController

  hobo_model_controller

  auto_actions :index, :create

  caches_page :create, :expires_in => 10.minutes
  caches_page :new, :expires_in => 10.minutes
  caches_page :index, :expires_in => 10.minutes


  def create
    index
    render :action => :index
  end

	def index

		@detailed_search = DetailedSearch.new params[:detailed_search]

		@detailed_search.query   ||= params[:query] ||= ""
		@detailed_search.address ||= params[:address] ||= ""
		@detailed_search.subject ||= params[:subject] ||= ""

		@detailed_search.query = "" if @detailed_search.query == "Keresés"

		 if @detailed_search.query.blank?     and @detailed_search.address.blank?   and @detailed_search.subject.blank? and @detailed_search.date_from.blank? and
			@detailed_search.date_to.blank?   and @detailed_search.person == true and @detailed_search.organization == true and @detailed_search.article      == true and
			@detailed_search.litigation   == true and @detailed_search.contract.blank?    and @detailed_search.tender.blank?      and @detailed_search.relations.blank?   and
			@detailed_search.amount_from.blank? and @detailed_search.amount_to.blank? 
			
				@empty_search = true  
		else
				@empty_search = false
		end

		# ha ajaxos lapozás van
		if params[:block] and !@empty_search
			if params[:block]=='tender'
				@tenders = get_tenders
				render "paginate_tender" and return
			elsif params[:block]=='contract'
				@contracts = get_contracts
				render "paginate_contract" and return
			elsif params[:block]=='person'
				@people = get_people
				render "paginate_person" and return
			elsif params[:block]=='org'
				@organizations = get_organizations
				render "paginate_organization" and return
			elsif params[:block]=='article'
				@articles = get_articles
				render "paginate_article" and return
			elsif params[:block]=='litigation'
				@litigations = get_litigations
				render "paginate_litigation" and return
			end
		else
			if !@empty_search
			# ha tranzakció be van jelölve akkor csak ott keresünk
				if @detailed_search.contract? or @detailed_search.tender?
					if @detailed_search.contract?
						@contracts   = get_contracts
					end
					if @detailed_search.tender?
						@tenders     = get_tenders
					end
			# nem kerestek dátumra
				elsif !@detailed_search.date_from_enable && !@detailed_search.date_to_enable
#					@organizations = @detailed_search.organization? ? Organization.search(@detailed_search.query, :name).search(@detailed_search.address, :address).paginate(build_paginate_params_for(:organization)) : Organization.limit(0)
					if @detailed_search.organization
						#@organizations = Organization.search(@detailed_search.query, :name).search(@detailed_search.address, :address)						
						#@organizations = @organizations.paginate(build_pag_params_organizations)
						#@organization_search_count = @organizations.total_entries
						@organizations = get_organizations
					else
						@organizations = Organization.limit(0)
					end

#					@people = @detailed_search.person? ? Person.search(@detailed_search.query, :name).search(@detailed_search.address, :address).paginate(build_paginate_params_for(:person)) : Person.limit(0) 
					if @detailed_search.person 
						#@people = Person.search(@detailed_search.query, :name).search(@detailed_search.address, :address)
						#@people_search_count=@people.count
						#@people = @people.paginate(build_pag_params_people)
						@people = get_people
						#@people_search_count=@people.total_entries
					else
						@people = Person.limit(0)
					end
 
#					@litigations   = @detailed_search.litigation? ? Litigation.search(@detailed_search.query, :name).paginate(:per_page=>10, :page=>params[:page]) : Litigation.limit(0)
					if @detailed_search.litigation
						@litigations = Litigation.search(@detailed_search.query, :name)						
						@litigations = @litigations.paginate(:per_page=>10, :page=>params[:page])
						@litigation_search_count = @litigations.total_entries
					else
						@litigations = Litigation.limit(0)
					end
				
#					@articles      = @detailed_search.article?  ? Article.search(@detailed_search.query, :name).paginate(:per_page=>10, :page=>params[:page]) : Article.limit(0) 
					if @detailed_search.article
						@articles = Article.search(@detailed_search.query, :name)						
						@articles = @articles.paginate(:per_page=>10, :page=>params[:page])
						@article_search_count = @articles.total_entries
					else
						@articles =Article.limit(0) 
					end
		  
		  # valamire rákerestek
				else
					@people = @detailed_search.person? ? get_people : Person.limit(0)
					@organizations = @detailed_search.organization? ? get_organizations : Organization.limit(0)
					@litigations = @detailed_search.litigation? ? get_litigations : Litigation.limit(0)
					# article esetén nem figyeljük a dátum keresést
					@articles = @detailed_search.article? ? get_articles : Article.limit(0)
				end
				# statok:
=begin
				r = Person.find(@people.try.first.try.id) if @people.try.first
				r.try.increment! :search_result_count
				r = Organization.find(@organizations.try.first.try.id) if @organizations.try.first
				r.try.increment! :search_result_count
				r = Litigation.find(@litigations.try.first.try.id) if @litigations.try.first
				r.try.increment! :search_result_count
				r = Article.find(@articles.try.first.try.id) if @articles.try.first
				r.try.increment! :search_result_count
				r  = InterorgRelation.find(@contracts.try.first.try.interorg_relations.try.first.try.id) if @contracts.try.first.try.interorg_relations.try.first
				r.try.increment! :search_result_count
				r  = InterorgRelation.find(@tenders.try.first.try.interorg_relation.try.id) if @tenders.try.first.try.interorg_relation
				r.try.increment! :search_result_count
=end
			end
		end		
	end

private


	def get_tenders
		tender_conditions = []
		tender_conditions << ["tenders.amount != ?", 0]
		tender_conditions << ["tenders.amount >= ?", @detailed_search.amount_from] if @detailed_search.amount_from.present?
		tender_conditions << ["tenders.amount <= ?", @detailed_search.amount_to] if @detailed_search.amount_to.present?
		tender_conditions << ["tenders.decided_at >= ?", @detailed_search.date_from] if @detailed_search.date_from.present?
		tender_conditions << ["tenders.decided_at <= ?", @detailed_search.date_to] if @detailed_search.date_to.present?
		cond = ""
		par = []
		tender_conditions.each_with_index do |e, i|
		  cond << (i>0 ? " and #{e[0]}" : e[0])
		  par << e[1]
		end
		builded_tender_conditions = [cond] + par
		@tmpte = Tender.search(@detailed_search.query, :name).search(@detailed_search.address, :city).search(@detailed_search.subject, :project)
		@tmpte = @tmpte.paginate(:conditions=>builded_tender_conditions, :per_page=>10, :page=>params[:page])
		@tender_search_count = @tmpte.total_entries
		@tmpte
	end

	def get_contracts
		contract_conditions = []
		contract_conditions << ["contracts.contracted_value != ?", 0]
		contract_conditions << ["contracts.contracted_value >= ?", @detailed_search.amount_from] if @detailed_search.amount_from.present?
		contract_conditions << ["contracts.contracted_value <= ?", @detailed_search.amount_to] if @detailed_search.amount_to.present?
		contract_conditions << ["contracts.issued_at >= ?", @detailed_search.date_from] if @detailed_search.date_from.present?
		contract_conditions << ["contracts.issued_at <= ?", @detailed_search.date_to] if @detailed_search.date_to.present?
		contract_conditions << ["(contract_cpv_rels.cpv_id in (?))", @detailed_search.cpvs.*.id] if @detailed_search.cpvs.present?
		cond = ""
		par = []
		contract_conditions.each_with_index do |e, i|
		  cond << (i>0 ? " and #{e[0]}" : e[0])
		  par << e[1]
		end
		builded_contract_conditions = [cond] + par

		@tmpco = Contract.search(@detailed_search.query, :name).search(@detailed_search.address, :place_of_performance).search(@detailed_search.subject, :subject_and_qty)		
		@tmpco.paginate(:select=>"distinct contracts.* ", :joins=>"left outer join contract_cpv_rels on contract_cpv_rels.contract_id = contracts.id ",:conditions=>builded_contract_conditions, :per_page=>10, :page=>params[:page])
		@contract_search_count = @tmpco.total_entries
		tmpco
	end
	
	# note used, see get_contracts and get_tenders (comment #2)
	def get_transactions
		transaction_conditions = []
		transaction_conditions << ["interorg_relations.value != ?", 0]
		transaction_conditions << ["interorg_relations.value >= ?", @detailed_search.amount_from] if @detailed_search.amount_from.present?
		transaction_conditions << ["interorg_relations.value <= ?", @detailed_search.amount_to] if @detailed_search.amount_to.present?
		transaction_conditions << ["interorg_relations.issued_at >= ?", @detailed_search.date_from] if @detailed_search.date_from.present?
		transaction_conditions << ["interorg_relations.issued_at <= ?", @detailed_search.date_to] if @detailed_search.date_to.present?
		cond = ""
		par = []
		transaction_conditions.flatten.each_with_index do |e, i|
			if i.even?
				cond << (i>0 ? " and #{e}" : e)
			else
				par << e
			end
		end
		builded_transaction_conditions = [cond] + par
		@tmptr=InterorgRelation.search(@detailed_search.query, :name).search(@detailed_search.address, :address)
		@tmptr=@tmptr.paginate(:include=>[:contract, :tender, :organization, :related_organization],
                              :conditions=>builded_transaction_conditions, 
                              :per_page=>10, 
                              :page=>params[:page])
		@transactions_search_count = @tmptr.total_entries
		@tmptr
  end
	def build_pag_params_people
		pag_params = {:select=>" distinct people.* ", :per_page=>10, :page=>params[:page], :conditions=>{}, :joins=>""}

		if @detailed_search.date_from or @detailed_search.date_to
			pag_params[:joins] += "left outer join interpersonal_relations on interpersonal_relations.person_id=people.id "
			pag_params[:joins] += "left outer join person_to_org_relations on person_to_org_relations.person_id=people.id "
		end
		
		person_conditions = [ "(people.relations_bit = ?)" ]
		person_pars = [ true ]
		
		if !@detailed_search.query.blank?
			person_conditions << "people.name like ?"
			person_pars << "%"+@detailed_search.query+"%"
		end
		
		if !@detailed_search.address.blank?
			person_conditions << "people.address like ?"
			person_pars << @detailed_search.address
		end		
		
		if @detailed_search.date_from_enable
			person_conditions << "(person_to_org_relations.start_time >= ? or interpersonal_relations.start_time >= ?)"
			person_pars << @detailed_search.date_from
			person_pars << @detailed_search.date_from
		end
		if @detailed_search.date_to_enable
			person_conditions << "(person_to_org_relations.end_time <= ? or interpersonal_relations.end_time <= ?)"
			person_pars << @detailed_search.date_to
			person_pars << @detailed_search.date_to
		end

		if @detailed_search.relations.present?
			if @detailed_search.relations.first.p_to_o_relations.present?
				person_conditions << "(p_to_o_relations.p_to_o_relation_type_id in (?))"
				person_pars << @detailed_search.relations.first.p_to_o_relations.*.id
			end
			if @detailed_search.relations.first.p_to_p_relations.present?
				person_conditions << "(p_to_p_relations.p_to_p_relation_type_id in (?))"
				person_pars << @detailed_search.relations.first.p_to_p_relations.*.id
			end
		end

			
		cond = ""
		person_conditions.flatten.each_with_index do |e, i|
			cond << (i>0 ? " and #{e}" : e)
		end
		builded_person_conditions = [cond] + person_pars	
		pag_params[:conditions]	= builded_person_conditions
		pag_params
	end  
	
 	def get_people	  
		#@tmppe = Person.search(@detailed_search.query, :name).search(@detailed_search.address, :address)
		@tmppe = Person.paginate( build_pag_params_people )
		@people_search_count=@tmppe.total_entries
		#@people_search_count=100
		@tmppe
	end
  
	def build_pag_params_organizations
		pag_params = {:select=>" distinct organizations.* ", :per_page=>10, :page=>params[:page], :conditions=>{}, :joins=>""}
		
		if @detailed_search.date_from or @detailed_search.date_to
			pag_params[:joins] += "left outer join interorg_relations on interorg_relations.organization_id = organizations.id "
			pag_params[:joins] += "left outer join person_to_org_relations on person_to_org_relations.organization_id = organizations.id "
		end
		
		if @detailed_search.activities.present?
			pag_params[:joins] += "left outer join activity_assocs on activity_assocs.organization_id=organizations.id "
		end
		
		organization_conditions = [ "(organizations.relations_bit = ?)"  ]
		org_pars = [ true ]

		if !@detailed_search.query.blank?
			organization_conditions << "organizations.name like ?"
			org_pars << "%"+@detailed_search.query+"%"
		end
		
		if !@detailed_search.address.blank?
			organization_conditions << "organizations.address like ?"
			org_pars << @detailed_search.address
		end				
		
		if @detailed_search.date_from_enable
			organization_conditions << "person_to_org_relations.start_time >= ? and interorg_relations.issued_at >=?"
			org_pars << @detailed_search.date_from
			org_pars << @detailed_search.date_from
		end

		if @detailed_search.date_to_enable
			organization_conditions << "person_to_org_relations.end_time <= ? and interorg_relations.isseud_at <=?"
			org_pars << @detailed_search.date_to
			org_pars << @detailed_search.date_to
		end

		if @detailed_search.sectors.present?
			organization_conditions << "(organizations.sector_id in (?))"
			org_pars << @detailed_search.sectors.*.id
		end

		if @detailed_search.activities.present?
			organization_conditions << "(activity_assocs.activity_id in (?))"
			org_pars << @detailed_search.activities.*.id
		end

		if @detailed_search.relations.present?
			if @detailed_search.relations.first.p_to_o_relation_types.present?
				organization_conditions << "(p_to_o_relations.p_to_o_relation_type_id in (?))"
				org_pars << @detailed_search.relations.first.p_to_o_relation_types.*.id
			end
			if @detailed_search.relations.first.o_to_o_relation_types.present?
				organization_conditions << "(o_to_o_relations.o_to_o_relation_type_id in (?))"
				org_pars << @detailed_search.relations.first.o_to_o_relation_types.*.id
			end
		end

		cond = ""
		organization_conditions.flatten.each_with_index do |e, i|
			cond << (i>0 ? " and #{e}" : e)
		end
		
		builded_organization_conditions = [cond] + org_pars
		pag_params[:conditions]	= builded_organization_conditions
		pag_params
	end
	
	def get_organizations
		#@tmporg = Organization.search(@detailed_search.query, :name).search(@detailed_search.address, :address)		
		@tmporg = Organization.paginate(build_pag_params_organizations)
		@organization_search_count = @tmporg.total_entries
		@tmporg
	end
	def get_litigations
		litigation_conditions = []
		lit_pars = []

		if @detailed_search.date_from.present?
			litigation_conditions << "start_time >= ?"
			lit_pars << @detailed_search.date_from
		end
		if @detailed_search.date_to.present?
			litigation_conditions << "end_time <= ?"
			lit_pars << @detailed_search.date_to
		end

		cond = ""
		litigation_conditions.flatten.each_with_index do |e, i|
			cond << (i>0 ? " and #{e}" : e)
		end
		builded_litigation_conditions = [cond] + org_pars
		@tmpli=Litigation.search(@detailed_search.query, :name)
		@tmpli=@tmpli.paginate(:conditions=>builded_litigation_conditions,
			:per_page=>10,                           
			:page=>params[:page])
		@litigation_search_count = @tmpli.total_entries
		@tmpli
  end
	def get_articles
    if !@detailed_search.query.empty?
      @tmpar = Article.search(@detailed_search.query, :name).search(@detailed_search.query, :address)
	  @tmpar = @tmpar.paginate(:per_page=>10, :page=>params[:page])
	  @article_search_count = @tmpar.total_entries	  
	  @tmpar
    else
      Article.limit(0)
    end
  end
end
