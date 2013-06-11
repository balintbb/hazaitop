# -*- encoding : utf-8 -*-
class SiteSearchController < ApplicationController

  hobo_controller

#  caches_page :index,     :expires_in => 90.minutes
#  caches_page :node_show, :expires_in => 90.minutes

  def generate_node(source, source_type)
    node = {}
    no_data = 'Nincs adat'
    node[:id] = "#{source_type}#{source.id}"
    if source_type == 'p'
      node[:shape] = 'CIRCLE'
      node[:bornAt] = source.born_at ? source.born_at.to_s : no_data
      node[:mothersName] = source.mothers_name.present? ? source.mothers_name : no_data
    elsif source_type == 'o'
      node[:shape] = 'RECTANGLE'
      node[:foundedAt] = source.founded_at ? source.founded_at.to_s : no_data
      node[:address] = source.city.present? || source.street.present? ? "#{source.city} #{source.street}".strip : no_data
      if source.recent_financial_year
        node[:year] = source.recent_financial_year.year
        node[:turnover] = source.recent_financial_year.turnover
        node[:balance] = source.recent_financial_year.balance_sheet_total
      else
        node[:year] = no_data
        node[:turnover] = no_data
        node[:balance] = no_data
      end
    elsif source_type == 'l'
      node[:shape] = 'DIAMOND'
      node[:startTime] = source.start_time ? source.start_time.to_s : no_data
      node[:endTime] = source.end_time ? source.end_time.to_s : no_data
    end
    node[:informationSource] = source.information_source
    node[:label] = source.name.gsub(', ', "\n").gsub(' ', "\n").gsub("'", "\\'")
    @network[:nodes] << node
  end

  def generate_edge(source, source_type, relation, target, target_type=nil)
    edge = {}
    no_data = 'Nincs adat'
    if target_type
      target_id = target
    else 
      target_type = if target.kind_of?(Organization) 
                      'o'
                    elsif target.kind_of?(Person)
                      'p'
                    elsif target.kind_of?(Litigation)
                      'l'
                    end
      target_id = target.id
    end
    edge[:weight] = 1 # relation.weight
    if target_type == source_type && target_type == 'o'
      edge[:id] = "o_to_o#{relation.id}"
      edge[:alternateId] = "o_to_o#{relation.interorg_relation_id}"
      edge[:label] = relation.o_to_o_relation_type.name
      edge[:relationTypeId] = "o_to_o#{relation.o_to_o_relation_type_id}"
      edge[:org] = source.name
      # mivel csak akkor rajzolunk ki edge-t ha a target megtalálható az oldalon ezért már betöltöttük őket
      edge[:relatedOrg] = @organizations.select {|r| r.id == relation.related_organization_id}.first.name
      edge[:issuedAt] = relation.issued_at.present? ? relation.issued_at : no_data
      edge[:source] = relation.information_source.name
      edge[:value] = relation.value.present? ? relation.value : no_data
      edge[:contractOrTender] = relation.contract_id && "contract" || relation.tender_id && "tender"
      contract_or_tender = relation.contract_id && relation.contract || relation.tender_id && relation.tender
      edge[:contractName] = contract_or_tender && contract_or_tender.name || no_data
      edge[:contractId] = contract_or_tender && contract_or_tender.id
    elsif target_type == source_type && target_type == 'p'
      edge[:id] = "p_to_p#{relation.id}"
      edge[:alternateId] = "p_to_p#{relation.interpersonal_relation_id}"
      edge[:label] = relation.p_to_p_relation_type.name
      edge[:relationTypeId] = "p_to_p#{relation.p_to_p_relation_type_id}"
      edge[:person] = source.name
      # mivel csak akkor rajzolunk ki edge-t ha a target megtalálható az oldalon ezért már betöltöttük őket
      edge[:relatedPerson] = @persons.select {|r| r.id == relation.related_person_id}.first.name
      edge[:startTime] = relation.start_time.present? ? relation.start_time : no_data
      edge[:endTime] = relation.end_time.present? ? relation.end_time : no_data
      edge[:source] = relation.information_source.name
    elsif source_type == 'o' && target_type == 'p'
      edge[:id] = "o_to_p#{relation.id}"
      edge[:alternateId] = "p_to_o#{relation.id}"
      edge[:label] = relation.p_to_o_relation_type.pair.name
      edge[:relationTypeId] = "o_to_p#{relation.p_to_o_relation_type.pair_id}"
      # mivel csak akkor rajzolunk ki edge-t ha a target megtalálható az oldalon ezért már betöltöttük őket
      edge[:person] = @persons.select {|r| r.id == relation.person_id}.first.name
      edge[:org] = source.name
      edge[:startTime] = relation.start_time.present? ? relation.start_time : no_data
      edge[:endTime] = relation.end_time.present? ? relation.end_time : no_data
      edge[:source] = relation.information_source.name
    elsif source_type == 'p' && target_type == 'o' 
      edge[:id] = "p_to_o#{relation.id}"
      edge[:alternateId] = "o_to_p#{relation.id}"
      edge[:label] = relation.p_to_o_relation_type.name
      edge[:relationTypeId] = "p_to_o#{relation.p_to_o_relation_type_id}"
      edge[:person] = source.name
      # mivel csak akkor rajzolunk ki edge-t ha a target megtalálható az oldalon ezért már betöltöttük őket
      edge[:org] = @organizations.select {|r| r.id == relation.organization_id}.first.name
      edge[:startTime] = relation.start_time.present? ? relation.start_time : no_data
      edge[:endTime] = relation.end_time.present? ? relation.end_time : no_data
      edge[:source] = relation.information_source.name || no_data
    elsif source_type == 'o' && target_type == 'l' 
      if relation.try.p_to_o_relation_type.pair._?.name
        edge[:id] = "o_to_p#{relation.id}"
        edge[:label] = relation.p_to_o_relation_type.pair.name
        edge[:relationTypeId] = "o_to_p#{relation.p_to_o_relation_type.pair_id}"
        edge[:org] = relation.organization.name
      elsif relation.try.p_to_o_relation_type._?.name
        edge[:id] = "p_to_o#{relation.id}"
        edge[:label] = relation.p_to_o_relation_type.name
        edge[:relationTypeId] = "p_to_o#{relation.p_to_o_relation_type.id}"
        edge[:org] = relation.organization.name
      elsif relation.try.o_to_o_relation_type._?.name
        edge[:id] = "o_to_o#{relation.id}"
        edge[:label] = relation.o_to_o_relation_type.name
        edge[:relationTypeId] = "o_to_o#{relation.o_to_o_relation_type.id}"
        edge[:org] = relation.organization.name
      end
      edge[:litigation] = target.name
      edge[:startTime] = relation.start_time.present? ? relation.start_time : no_data
      edge[:endTime] = relation.end_time.present? ? relation.end_time : no_data
      edge[:source] = relation.information_source.name
    elsif source_type == 'p' && target_type == 'l' 
      if relation.try.p_to_o_relation_type._?.name
        edge[:id] = "p_to_o#{relation.id}"
        edge[:label] = relation.p_to_o_relation_type.name
        edge[:relationTypeId] = "p_to_o#{relation.p_to_o_relation_type.id}"
      elsif relation.try.p_to_o_relation_type.pair._?.name
        edge[:id] = "o_to_p#{relation.id}"
        edge[:label] = relation.p_to_o_relation_type.pair.name
        edge[:relationTypeId] = "o_to_p#{relation.p_to_o_relation_type.pair_id}"
      elsif relation.try.p_to_p_relation_type._?.name
        edge[:id] = "p_to_p#{relation.id}"
        edge[:label] = relation.p_to_p_relation_type.name
        edge[:relationTypeId] = "p_to_p#{relation.p_to_p_relation_type.id}"
      end
      edge[:litigation] = target.name
      edge[:startTime] = relation.start_time.present? ? relation.start_time : no_data
      edge[:endTime] = relation.end_time.present? ? relation.end_time : no_data
      edge[:source] = relation.information_source.name
    end
    edge[:sourceId] = "#{source_type}#{source.id}"
    edge[:targetId] = "#{target_type}#{target_id}"
    @network[:edges] << edge
  end

  def generate_litigation_relations_for_litigations
    # @litigation_relations változóban lévő per kapcsolatokhoz megkeressük a pereket és végigmegyünk rajtuk 
    Litigation.info(@info).find(LitigationRelation.for_relations(@litigation_relations).*.litigation_id).each do |litigation|
      # perenként megnézzük milyen node-ok tartoznak hozzá és milyen per-relation-párok vannak
      generate_litigation_relations_for_litigation(litigation)
    end
  end
  

  def generate_litigation_relations_for_litigation(litigation)
    nodes_in_litigation = {:relation_pair => [], :nodes => []}
    # végig megyünk a perhez tartozó kapcsolatokon
    litigation.litigation_relations.all(:include=>:litigable).*.litigable.each do |litigable|
      # attól függően hogy a kapcsolat interpersonal, interorg vagy person_to_org 
      # elmentjük a kapcsolatban résztvevőket és a kapcsolatot
      if litigable.respond_to?(:person) && 
         litigable.respond_to?(:related_person) && 
         litigable.person.present? && 
         litigable.related_person.present?
        nodes_in_litigation[:relation_pair] << {litigable => [litigable.person, litigable.related_person]}
        nodes_in_litigation[:nodes] << [litigable.person, litigable.related_person] 
      elsif litigable.respond_to?(:organization) && 
            litigable.respond_to?(:related_organization) && 
            litigable.organization.present? && 
            litigable.related_organization.present?
        nodes_in_litigation[:relation_pair] << {litigable => [litigable.organization, litigable.related_organization]}
        nodes_in_litigation[:nodes] << [litigable.organization, litigable.related_organization]
      elsif litigable.respond_to?(:organization) && 
            litigable.respond_to?(:person) && 
            litigable.organization.present? && 
            litigable.person.present?
        nodes_in_litigation[:relation_pair] << {litigable => [litigable.organization, litigable.person]}
        nodes_in_litigation[:nodes] << [litigable.organization, litigable.person]
      end
      nodes_in_litigation[:nodes] = nodes_in_litigation[:nodes].flatten.uniq
      nodes_in_litigation[:relation_pair].flatten!
      # kigeneráljuk a peres kapcsolatot (vmint a perben résztvevő egyéb node-okat)
      # ha az aktuálisan vizsgált node a) résztvevője a pernek b) ő maga egy per
      if nodes_in_litigation[:nodes].include?(@this) || @this.kind_of?(Litigation)
        # kigeneráljuk a pert ha még nem látszik
        unless @litigations.include? litigation
          generate_node(litigation, 'l') 
          @litigations << litigation
        end
        # végig megyünk a perhez tartozó kapcsolat párokon
        nodes_in_litigation[:relation_pair].each do |relation_pair|
          # végig megyünk az adott kapcsolat párhoz tartozó node-okon
          relation_pair.values.flatten.each do |node|
            node_type = node.kind_of?(Person) ? 'p' : 'o'
            # ha még nem látszik az oldalon akkor kigeneráljuk a node-ot
            unless @non_litigation_nodes.include? node
              generate_node(node, node_type) 
              @non_litigation_nodes << node
            end
            # kigeneráljuk a kapcsolatát a perhez
            generate_edge(node, node_type, relation_pair.keys.first, litigation)
          end
        end
      # egyébként megnézzük hogy a perhez tartozó node-ok közül hány látható az oldalon,
      # ez a látható nem litigation node-ok (azaz person és org) és a perben résztvevő node-ok metszete
      # ha ez nagyobb mint egy akkor kigeneráljuk a peres kapcsolatot
      elsif (@non_litigation_nodes & nodes_in_litigation[:nodes]).length > 1
        # ha több mint egy látszik akkor kigenerájuk az aktuálisan vizsgált pert ha még nem látszik az oldalon
        unless @litigations.include? litigation
          generate_node(litigation, 'l') 
          @litigations << litigation
        end
        # végig megyünk a perhez tartozó kapcsolat párokon
        nodes_in_litigation[:relation_pair].each do |relation_pair|
          # végig megyünk az adott kapcsolat párhoz tartozó node-okon
          relation_pair.values.flatten.each do |node|
            # ha látszik az oldalon akkor kigeneráljuk a kapcsolatát a perhez
            if @non_litigation_nodes.include? node
              node_type = node.kind_of?(Person) ? 'p' : 'o'
              generate_edge(node, node_type, relation_pair.keys.first, litigation)
            end
          end
        end
      end
    end
  end

  def generate_node_edges_for_visible_non_litigation_nodes
    # az éppen kiválasztott node-on kívül az összes kliens oldalon betöltött 
    # vmint az új node-okon végigmegyünk és kigeneráljuk a kapcsolataikat
    @non_litigation_nodes.each do |node|
      if !(node.kind_of?(Person) && params[:type] == 'p' && node.id == @id ||
         node.kind_of?(Organization) && params[:type] == 'o' && node.id == @id)
        generate_node_edges_for_node(node)
      end
    end
  end

  def generate_node_edges_for_node(node)
    if node.kind_of?(Person)
      # adott személy azon személyes kapcsolatai, amelyeknél a kapcsolódó személy megtalálható a kirajzolandó hálón
      node.personal_non_litigation_relations.all(:include=>[:information_source, :p_to_p_relation_type], 
                                                 :conditions=>{:related_person_id=>@persons.*.id}).each do |personal_relation|
        generate_edge(node, 'p', personal_relation, personal_relation.related_person_id, 'p')
      end
      # adott személy azon szervezeti kapcsolatai, amelyeknél a kapcsolódó szervezet megtalálható a kirajzolandó hálón
      node.person_to_org_non_litigation_relations.all(:include=>[:information_source, :p_to_o_relation_type],
                                                      :conditions=>{:organization_id=>@organizations.*.id}).each do |org_relation|
        generate_edge(node, 'p', org_relation, org_relation.organization_id, 'o')
      end
    elsif node.kind_of?(Organization)
      # adott szervezet azon személyes kapcsolatai, amelyeknél a kapcsolódó személy megtalálható a kirajzolandó hálón
      node.person_to_org_non_litigation_relations.all(:include=>[:information_source, :p_to_o_relation_type], 
                                                      :conditions=>{:person_id=>@persons.*.id}).each do |personal_relation|
        generate_edge(node, 'o', personal_relation, personal_relation.person_id, 'p')
      end
      # adott szervezet azon szervezeti kapcsolatai, amelyeknél a kapcsolódó szervezet megtalálható a kirajzolandó hálón
      node.interorg_non_litigation_relations.all(:include=>[:information_source, :o_to_o_relation_type],
                                                 :conditions=>{:related_organization_id=>@organizations.*.id}).each do |org_relation|
        generate_edge(node, 'o', org_relation, org_relation.related_organization_id, 'o')
      end
    end
  end

  def generate_network
    # ha person kapcsolatait fedik fel
    if params[:type] == 'p'
      @this = resource = Person.find(params[:id])
      @explored_node = resource
      @persons << resource unless @persons.include? resource
      
      # személyes kapcsolatok
      resource.personal_non_litigation_relations.all(:include=>{:related_person=>:information_source}).each do |personal_relation|
        next if !@info.empty? and !@info.include? personal_relation.information_source_id
        # ha még nem látható az oldalon akkor kigeneráljuk a személyt
        unless @persons.include? personal_relation.related_person
          @persons << personal_relation.related_person
          generate_node(personal_relation.related_person, 'p')
        end
      end
      
      # intézményes kapcsolatok  
      resource.person_to_org_non_litigation_relations.all(:include=>{:organization=>[:information_source, :recent_financial_year]}).each do |org_relation|
        next if !@info.empty? and !@info.include? org_relation.information_source_id
        # ha még nem látható az oldalon akkor kigeneráljuk az intézményt
        unless @organizations.include? org_relation.organization
          @organizations << org_relation.organization
          generate_node(org_relation.organization, 'o')
        end
      end
      
      # személyes peres kapcsolatok
      @litigation_relations += InterpersonalRelation.info(@info).person_is(resource).not_visual
      # intézményes peres kapcsolatok
      @litigation_relations += PersonToOrgRelation.info(@info).person_is(resource).not_visual

      @non_litigation_nodes = @persons + @organizations

      # litigation kapcsolatok kigenerálása
      generate_litigation_relations_for_litigations
      generate_node(resource, params[:type])
    # ha organization kapcsolatait fedik fel
    elsif params[:type] == 'o'
      @this = Organization.find(params[:id])
      set_network_for_organization(@this)
    # ha litigation kapcsolatait fedik fel
    elsif params[:type] == 'l'
      @this = resource = Litigation.find(params[:id])
      @explored_node = resource
      @litigations << resource
      @non_litigation_nodes = @persons + @organizations
      generate_litigation_relations_for_litigation(resource)
      generate_node(resource, params[:type])
    # ha transaction kapcsolatait fedik fel  
    elsif params[:type] == 't'
      @explored_node = interorg_relation = InterorgRelation.find(params[:id])
      if @explored_node.o_to_o_relation_type==KOZBESZ_NYERTES && !@explored_node.mirror || @explored_node.o_to_o_relation_type==PALYAZO && @explored_node.mirror 
        @this = interorg_relation.organization
        @target = interorg_relation.related_organization
      else
        @this = interorg_relation.related_organization
        @target = interorg_relation.organization
        @explored_node = interorg_relation.interorg_relation
      end
      if interorg_relation
        set_network_for_organization(@this)
      end
    end
    # person és organization node-ok közötti kapcsolatok kigenerálása
    generate_node_edges_for_visible_non_litigation_nodes
  end

  def set_network_for_organization(resource)
    @organizations << resource unless @organizations.include? resource

    # személyes kapcsolatok
    resource.person_to_org_non_litigation_relations.all(:include=>{:person=>:information_source}).each do |personal_relation|
      next if !@info.empty? and !@info.include? personal_relation.information_source_id
      # ha még nem látható az oldalon akkor kigeneráljuk a személyt
      unless @persons.include? personal_relation.person
        @persons << personal_relation.person
        generate_node(personal_relation.person, 'p')
      end
    end

    # intézményes kapcsolatok  
    resource.interorg_non_litigation_relations.all(:include=>{:related_organization=>[:information_source, :recent_financial_year]}).each do |org_relation|
      next if !@info.empty? and !@info.include? org_relation.information_source_id
      # ha még nem látható az oldalon akkor kigeneráljuk az intézményt
      unless @organizations.include? org_relation.related_organization
        @organizations << org_relation.related_organization
        generate_node(org_relation.related_organization, 'o')
      end
    end

    # személyes peres kapcsolatok
    @litigation_relations += PersonToOrgRelation.info(@info).organization_is(resource).not_visual
    # intézményes peres kapcsolatok
    @litigation_relations += InterorgRelation.info(@info).organization_is(resource).not_visual

    @non_litigation_nodes += @persons 
    @non_litigation_nodes += @organizations

    # litigation kapcsolatok kigenerálása
    generate_litigation_relations_for_litigations
    generate_node(resource, 'o')
  end

  def node_show
    @this = case params[:type]
              when 'p' then Person
              when 'o' then Organization
              else Litigation
            end.find(params[:id])
  end



  def index
    redirect_to '/' and return if params[:id].to_i == 1 
    # amig rossz adat van a rsz ben TODO: autocomplete
    @info = []
    if params[:information_source]
      @info =  params[:information_source][:id].map do |i| i.match(/[0-9]+/).to_s.to_i end
    end
    if params[:id] && params[:type]
      @id = params[:id].to_i
      @network = {:nodes=>[], :edges=>[]}
      @litigation_relations = []
      @persons = []
      @organizations = []
      @litigations = []
      @non_litigation_nodes = []
      # ajax request
      # ilyenkor figyeljük hogy milyen node-ok vannak már az oldalon, és az új kigenerálandó node-ok között milyen kapcsolatok vannak
      if request.xhr?
        person_ids = []
        organization_ids = []
        litigation_ids = []
        if params[:nodes]
          params[:nodes][0..-2].split(',').each do |node|
            match = node.match /(.*?)(\d+)$/
            person_ids << match[2] if match[1] == 'p'
            organization_ids << match[2] if match[1] == 'o'
            litigation_ids << match[2] if match[1] == 'l'
          end
          @persons = Array(Person.find_by_id(person_ids)).flatten
          @organizations = Array(Organization.find_by_id(organization_ids)).flatten
          @litigations = Array(Litigation.find_by_id(litigation_ids)).flatten
        end
        generate_network
        render :json => @network
      # ha egy másik oldalról érkezve egy konkrét adott node kapcsolatait akarják felfeldni
      else
        generate_network
      end
    end
  rescue ActiveRecord::RecordNotFound
    render :nothing => true
  end
end

