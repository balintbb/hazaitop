# -*- encoding : utf-8 -*-
class Contract < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    no_of_proposals :integer
    name :string
    description :text
    sum_value  :integer, :limit => 8
    original_sum_value :string
    s_vat_incl :boolean
    contracted_value :integer, :limit => 8
    c_vat_incl :boolean
    original_contracted_value :string
    estimated_value :integer, :limit => 8
    city :string
    e_vat_incl :boolean
    currency :string
    subject_and_qty :text
    number :string
    issued_at :date
    case_number :string
    place_of_performance :string
	source_url :string
    timestamps
  end

  default_scope  :order => 'contracted_value DESC'

  named_scope :info, lambda { |info_ids| info_ids.present? ? { :conditions => [ "information_source_id in (?)", info_ids ]} : {} }

  attr_reader :source_url

  has_many :contract_type_rels
  has_many :contract_types, :through => :contract_type_rels

  has_many :contract_frame_rels
  has_many :contract_frames, :through => :contract_frame_rels

  has_many :contract_cpv_rels
  has_many :cpvs, :through => :contract_cpv_rels
  
  has_many :tender_to_contract_relations
  has_many :tenders, :through => :tender_to_contract_relations

  belongs_to :buyer,  :class_name => "Organization"
  belongs_to :seller, :class_name => "Organization"

  belongs_to :buyer_person,  :class_name => "Person"
  belongs_to :seller_person, :class_name => "Person"

  
  belongs_to :notification

  has_many :interorg_relations, :dependent => :destroy
  has_many :person_to_org_relations, :dependent => :destroy

  def to_param
    "#{id}-#{name.to_textual_id}"
  end


  def name 
    attributes["name"].blank? ? "<dokumentáció>" : attributes["name"]
  end

  def source_url
    #"http://www.kozbeszerzes.hu/lid/ertesito/pid/0/ertesitoHirdetmenyProperties?objectID=Hirdetmeny.portal_#{case_number.gsub('/','_')}"
	#"http://www.kozbeszerzes.hu/adatbazis/mutat/hirdetmeny/portal_#{case_number.gsub('/','_')}" # ZSOLT: új link
	#attributes["source_url"]=="" ? "http://www.kozbeszerzes.hu/adatbazis/mutat/hirdetmeny/portal_#{case_number.gsub('/','_')}" : attributes["source_url"]
	attributes["source_url"].blank? ? "http://www.kozbeszerzes.hu/adatbazis/mutat/hirdetmeny/portal_#{case_number.gsub('/','_')}" : attributes["source_url"]
  end

  before_save do |r|
	i=InterorgRelation.create( ) { }
	k=PersonToOrgRelation.create(){}
  end
  
  after_save do |r|
    #i=InterorgRelation.find_or_create_by_contract_id( ) { |s| s.value = 999; s.organization_id=48279; s.related_organization_id=54599; s.information_source_id=5; s.o_to_o_relation_type_id=5}

	puts r.buyer_id
	puts r.seller_id
	puts r.buyer_person_id
	puts r.seller_person_id

	

	if r.buyer_id && r.seller_id
		r.person_to_org_relations.try.destroy_all
		i=InterorgRelation.find_or_create_by_contract_id(r.id) {
			|s| s.value = r.contracted_value, s.organization_id=r.buyer_id, s.related_organization_id=r.seller_id, s.information_source_id=4, s.o_to_o_relation_type_id=12, s.contract_id=r.id
		}
		r.interorg_relations.each do |w|
		  w.update_attribute :value, r.contracted_value
		 end
	else 
		if r.buyer_id && r.seller_person_id
			r.interorg_relations.try.destroy_all
			k=PersonToOrgRelation.find_or_create_by_contract_id(r.id){
				|s| s.organization_id = r.buyer_id, s.person_id=r.seller_person_id, s.information_source_id=4,s.o_to_p_relation_type_id=204, s.contract_id=r.id, s.p_to_o_relation_type_id = 44
			}
			r.person_to_org_relations.each do |w|
				w.update_attribute :organization_id, r.buyer_id
			end
			#k.save
		else 
			if r.buyer_person_id && r.seller_id
			r.interorg_relations.try.destroy_all
			k=PersonToOrgRelation.find_or_create_by_contract_id(r.id){
				|s| s.organization_id = r.seller_id, s.person_id=r.buyer_person_id, s.information_source_id=4,s.o_to_p_relation_type_id=204, s.contract_id=r.id, s.p_to_o_relation_type_id = 44
			}
			r.person_to_org_relations.each do |w|
				w.update_attribute :organization_id, r.seller_id
			end			
			#k.save
			end
		end	
	end
	  
end

  # --- Permissions --- #

  def create_permitted?
    acting_user.administrator?
  end

  def update_permitted?
    acting_user.administrator?
  end

  def destroy_permitted?
    acting_user.administrator?
  end

  def view_permitted?(field)
    true
  end

end

