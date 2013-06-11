# -*- encoding : utf-8 -*-
class Organization < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    name                          :string, :unique, :index => true
    alternate_name                :string # ha unique miatt nem menti le, akkor itt található, h mit nem engedett
    klink                         :string
    street                        :string
    city                          :string
    country                       :string
    zip_code                      :string
    phone                         :string
    fax                           :string
    email_address                 :string
    internet_address              :string
    trade_register_nr             :string
    tax_nr                        :string
    founded_at                    :date
    number_of_employees           :integer
    interorg_relations_count      :integer, :default => 0
    person_to_org_relations_count :integer, :default => 0
    financials_count              :integer, :default => 0
    relations_counter             :integer, :default => 0
    relations_bit                 :boolean, :default => false
    complexed_at                  :date
    ksh_number                    :string
    ksh_number_from               :date
    social_security_number        :string
    social_security_number_from   :date
    stock                         :integer, :limit => 8
    ceased_at                     :date
    no_ceased_at  :boolean, :default => true
    ceased_from                   :date # _from mezők complexből a hatályosság vagy a változás kezdetét jelölik
    kozhasznu                     :boolean
    kozhasznu_from                :date
    kiemelten_kozhasznu           :boolean
    kiemelten_kozhasznu_from      :date
    tea08                         :integer
    letesito_okirat_kelte         :date
    civil                         :boolean, :default => false
    description                   :string
    country_id_nr                 :string
    county_id_nr                  :string
    timestamps
    complex_xml :text
    search_result_count           :integer, :default => 0
    company :boolean, :default => false
    address :string, :index => true
  end

  belongs_to :merge_from, :class_name => "Organization"
  has_many :organizations, :accessible => true, :foreign_key => "merge_from_id"
  belongs_to :law_successor, :class_name => "Organization"   #TODO
  
  has_many :announcements
  has_many :liquidations

  named_scope :info, lambda { |info_ids| info_ids.present? ? { :conditions => [ "organizations.information_source_id in (?)", info_ids ]} : {} }
  
  default_scope :order => "name ASC"

  def self.merge into_this, this

    this.buyer_activity_rels.each     { |f| f.organization_id = into_this.id; f.save(false) }
    this.buyer_type_rels.each         { |f| f.organization_id = into_this.id; f.save(false) } 
#   this.activity_assocs.each         { |f| f.organization_id = into_this.id; f.save(false) }
    

    Contract.seller_is(this.id).each { |f|
	    f.seller_id = into_this.id
	    f.save
    }

    Contract.buyer_is(this.id).each { |f|
	    f.buyer_id = into_this.id
	    f.save
    }



    this.activity_assocs.each      { |f|
      activityass = ActivityAssoc.find_by_organization_id_and_activity_id( into_this.id, f.activity_id)
      if !activityass
        f.organization_id = into_this.id; f.save(false)
      end
    }
 
    this.interorg_relations.each      { |f| f.organization_id = into_this.id; f.save(false) }
    this.person_to_org_relations.each { |f| f.organization_id = into_this.id; f.save(false) }
    this.org_histories.each           { |f| f.organization_id = into_this.id; f.save(false) }
    into_this.save(false)



#   this.buyer_activity_rels.destroy_all
#   this.buyer_type_rels.destroy_all
#   this.activity_assocs_destroy_all
#   this.interorg_relations.destroy_all
#   this.person_to_org_relations.destroy_all
#   this.org_histories.destroy_all
    this.reload
#    this.destroy

  end


  has_many :buyer_activity_rels
  has_many :buyer_activities, :through => :buyer_activity_rels

  has_many :buyer_type_rels
  has_many :buyer_types, :through => :buyer_type_rels

  default_scope  :order => 'name'

  belongs_to :sector

  has_many :activity_assocs
  has_many :activities, :through => :activity_assocs, :accessible => true

#   has_many :organization_grade_assocs
#   has_many :org_grades, :through => :organization_grade_assocs, :accessible => true

  belongs_to :org_grade

  has_many :financials, :accessible => true
  has_one :recent_financial_year, :class_name => 'Financial', :order => 'year DESC'

  has_many :interorg_relations, :accessible => true
  has_many :person_to_org_relations, :accessible => true, :order => 'person_id'

  # helperek a vizualicáziós részhez
  has_many :person_to_org_non_litigation_relations, :conditions => [ "person_to_org_relations.visual = ?", true], :class_name => "PersonToOrgRelation"
  has_many :person_to_org_litigation_relations, :conditions => [ "person_to_org_litigation_relations.visual = ?", false], :class_name => "PersonToOrgRelation"
  has_many :interorg_non_litigation_relations, :conditions => [ "interorg_relations.visual = ?", true], :class_name => "InterorgRelation"
  has_many :interorg_litigation_relations, :conditions => [ "interorg_relations.visual = ?", false], :class_name => "InterorgRelation"

  # helperek adminhoz
  has_many :manual_person_to_org_relations, :conditions => [ "person_to_org_relations.parsed = ?", false ], :class_name => "PersonToOrgRelation", :accessible => true
  has_many :manual_interorg_relations,      :conditions => [ "interorg_relations.parsed = ?", false ], :class_name => "InterorgRelation", :accessible => true

  has_many :people,       :through => :person_to_org_relations

  # has_many :organizations, :through => :person_to_org_relations, :accessible => true
  # has_many :organizations, :through => :interorg_relations, :accessible => true, :source => :organization
  # has_many :related_organizations, :through => :interorg_relations, :accessible => true, :source => :related_organization

  belongs_to :information_source
  belongs_to :user, :creator => true

  validates_presence_of :name
  validates_presence_of :information_source
  validates_numericality_of :number_of_employees, :if => lambda { |r| r.number_of_employees }

  has_many :org_histories

  def to_param
    "#{id}-#{name.to_textual_id}"
  end

  before_validation do |r|
    r.name = r.name.try.gsub('"','').strip
  end

  before_save do |r|
    r.company = true if r.name.downcase.include?('rt')
    r.company = true if r.name.downcase.include?('kft')
    r.company = true if r.name.downcase.include?('bt')
    r.company = true if r.name.downcase.include?('llalat') # vállalat
    r.company = true if r.name.downcase.include?('rsas') # társaság
    #Organization.update_counters r.id, :interorg_relations_count => -r.interorg_relations_count + (isize = r.interorg_relations.count)
    #Organization.update_counters r.id, :person_to_org_relations_count => -r.person_to_org_relations_count + (psize = r.person_to_org_relations.count)
    #r.relations_counter = isize + psize
    #r.relations_counter = r.interorg_relations_count + r.person_to_org_relations_count
    #r.relations_bit = true if r.relations_counter > 0
    if r.zip_code.blank? and r.city.blank? and r.street.blank?
      r.address = " "
    else
      r.address = "#{r.zip_code} #{r.city}, #{r.street}" 
    end
  end

  # --- Permissions --- #
  def create_permitted?
    acting_user.administrator? || (acting_user.editor? && user.id == acting_user.id)
  end

  def update_permitted?
    acting_user.administrator? || acting_user.editor? || acting_user.supervisor?
  end

  def destroy_permitted?
    acting_user.administrator? || acting_user.supervisor? || acting_user.editor?
  end

  def view_permitted?(field)
    true
  end

end

