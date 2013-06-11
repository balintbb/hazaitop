# -*- encoding : utf-8 -*-
class PersonToOrgRelation < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    start_time :date
    end_time   :date
    no_end_time :boolean, :default => false
    no_start_time :boolean, :default => false
    weight     :float,    :default => 1
    visual     :boolean, :default => true
    role   :string    # tisztség complexbol
    role2   :string    # tisztség complexbol névből kiparse-olva
    note   :text
    erased_at :date  # ha a bejegyzés törlés volt a cégbíróságon, akkkor ide a törlés dátuma kerül
    jelentos  :boolean, :default => false
    tobbsegi  :boolean, :default => false
    kozvetlen :boolean, :default => false
    szavazat_50_szazalek_felett  :boolean, :default => false
    szavazat_tobbsegi_befolyas   :boolean, :default => false
    szavazat_egyeduli_reszvenyes :boolean, :default => false
    parsed :boolean, :default => false
    timestamps
  end

  def name
    "#{person} és #{organization}"
  end

  default_scope :include => :organization, :order => :"organizations.name"
  named_scope :ordered, lambda { |order| { :include => order.to_sym, :order => (order.pluralize + '.name').to_sym } }
  named_scope :info, lambda { |info_ids| info_ids.present? ? { :conditions => [ "person_to_org_relations.information_source_id in (?)", info_ids ]} : {} }

  has_many :article_relations, :as => :relationable, :accessible => true
  has_many :articles, :through => :article_relations, :accessible => true

  belongs_to :p_to_o_relation_type
  belongs_to :o_to_p_relation_type
  belongs_to :organization, :counter_cache => true
  belongs_to :person, :counter_cache => true
  belongs_to :contract

  has_many :interpersonal_relations, :dependent => :destroy
  has_many :other_interpersonal_relations, :class_name => "InterpersonalRelation", :dependent => :destroy, :foreign_key => "other_person_to_org_relation_id"

  belongs_to :information_source

  has_many :litigation_relations, :as => :litigable, :dependent => :destroy
  has_many :litigations, :through => :litigation_relations, :accessible => true
#=begin
  validates_presence_of :p_to_o_relation_type
  # validates_presence_of :o_to_p_relation_type
  validate :litigation_related
  validate :source_present

  def source_present
    if information_source.blank? and articles.empty?
      errors.add("Information source", "must present.")
    end
  end


  def litigation_related
    unless litigations.blank?
      errors.add("Litigation allowed only if", "relation type has legal aspect.") unless p_to_o_relation_type.litig
    end
  end

  before_validation do |r|
    p_to_o_relation_type_id   = r.o_to_p_relation_type.pair_id if r.o_to_p_relation_type
    o_to_p_relation_type_id   = r.p_to_o_relation_type.pair_id if r.p_to_o_relation_type
    r.p_to_o_relation_type_id = p_to_o_relation_type_id        if p_to_o_relation_type_id
    r.o_to_p_relation_type_id = o_to_p_relation_type_id        if o_to_p_relation_type_id
  end

  before_create do |r|
    r.organization.try.increment! :relations_counter
    r.person.try.increment! :relations_counter
    true
  end
    
  before_save do |r|
    r.visual = r.p_to_o_relation_type.visual
    r.information_source_id = (r.info_id ? r.info_id : r.articles.first.try.information_source_id ) if r.information_source.blank?
    r.information_source_id = InformationSource.find_by_domain_name('ahalo.hu').id if r.information_source.blank?
    true
    # r.weight = r.information_source.weight * r.p_to_o_relation_type.weight
  end

  after_save do |r|
    r.match
    true
  end

  after_destroy do |r|
    r.organization.try.decrement! :relations_counter
    r.person.try.decrement! :relations_counter
    true
  end
#=end
  def match
    self.interpersonal_relations.try.destroy_all
    self.other_interpersonal_relations.try.destroy_all
    if person and organization # ha nem törlés történt
      if !(InterpersonalRelation.find_by_person_to_org_relation_id(id) or InterpersonalRelation.find_by_other_person_to_org_relation_id(id))
       # meg kell vizsgálnunk hogy van-e már, különben kétszer megy bele (a hobo?) az after_save-be TODO
        if no_start_time
          if no_end_time
            potential_relations = PersonToOrgRelation.find( :all, :conditions => [
            "organization_id = ?", organization_id ])
          else
            potential_relations = PersonToOrgRelation.find( :all, :conditions => [
            "organization_id = ? and ((no_start_time = ? and (end_time <= ? or no_end_time = ?)) or ((no_start_time = ?) and (start_time <= ?) and (end_time >= ? or no_end_time = ?))) and id != ?", organization_id, true, end_time, true, false, end_time, end_time, true, id ])
          end
        else
          if no_end_time
            potential_relations = PersonToOrgRelation.find( :all, :conditions => [
            "organization_id = ? and ((start_time <= ? and (end_time >= ? or no_end_time = ?)) or (start_time <= ? and no_end_time = ?)) and person_to_org_relations.id != ?", organization_id, start_time, start_time, true, Time.now.to_date, true, id ])
          else
            potential_relations = PersonToOrgRelation.find( :all, :conditions => [
            "organization_id = ? and ((start_time <= ? and (end_time >= ? or no_end_time = ?)) or (start_time <= ? and (end_time >= ? or no_end_time = ?))) and person_to_org_relations.id != ?", organization_id, start_time, start_time, true, end_time, end_time, true, id ])
          end
        end
        press_id = PToORelationType.find_by_name("sajtó").id
        if potential_relations and p_to_o_relation_type_id != press_id and p_to_o_relation_type_id !=5 
          potential_relations.each do |pot|
            unless pot.p_to_o_relation_type_id == press_id  # sajtós fetcheket nem birizgáljuk
              if person_id != pot.person_id # saját kapcsolatokat nem veszünk fel
                weight = (information_source.weight + pot.information_source.weight) / 2.0
                # nézzük meg, hogy a kalkulátorban rögzítve van-e a két kapcsolattipus (irányított!)
                #relation_type_id = InterpersonalRelationCalculator.find_by_p_to_o_relation_type_id(pot.p_to_o_relation_type_id)._?.p_to_p_relation_type_id
                relation_type_id = InterpersonalRelationCalculator.find_by_p_to_o_relation_type_id(pot.p_to_o_relation_type_id)._?.p_to_p_relation_type_id
                if !relation_type_id
                  # ha megegyezik a két kapcsolat, akkor default-oljunk, a p_to_p kapcsolattipusukra
                  if p_to_o_relation_type_id == pot.p_to_o_relation_type_id
                    relation_type_id = p_to_o_relation_type.p_to_p_relation_type_id
                  else
                    # ha nincs info, akkor csak azt rögzítjük, hogy közös intézménynél szerepelnek
                    relation_type_id = -1 #relation_type_id = PToPRelationType.find(:first, :conditions => {:name => "közös intézményi kapcsolat", :internal => true }).id
                  end
                end
                calculated_no_start_time = false
                if no_start_time and !pot.no_start_time
                  calculated_start_time = pot.start_time
                elsif pot.no_start_time and !no_start_time
                  calculated_start_time = start_time
                elsif no_start_time and pot.no_start_time
                  calculated_start_time = nil
                  calculated_no_start_time = true
                else
                  if start_time <= pot.start_time
                    calculated_start_time = pot.start_time
                  else
                    calculated_start_time = start_time
                  end
                end

                calculated_no_end_time = false
                if no_end_time and !pot.no_end_time
                  calculated_end_time = pot.end_time
                elsif pot.no_end_time and !no_end_time
                  calculated_end_time = end_time
                elsif no_end_time and pot.no_end_time
                  calculated_end_time = nil
                  calculated_no_end_time = true
                else
                  if end_time <= pot.end_time
                    calculated_end_time = end_time
                  else
                    calculated_end_time = pot.end_time
                  end
                end
if relation_type_id != -1
                info = InformationSource.find :first, :conditions => { :internal => true }
                info = InformationSource.create!(:internal => true, :weight => weight, :name => "system", :web => 'http://ahalo.hu' ) if !info
                interpersonal = InterpersonalRelation.new(:p_to_p_relation_type_id => relation_type_id,
                                                          :person_id => person_id,
                                                          :related_person_id => pot.person_id,
                                                          :information_source_id => info.id,
                                                          :person_to_org_relation_id => id,
                                                          :other_person_to_org_relation_id => pot.id,
                                                          :organization_id => organization_id,
                                                          :start_time => calculated_start_time,
                                                          :end_time => calculated_end_time,
                                                          :no_end_time => calculated_no_end_time,
                                                          :no_start_time => calculated_no_start_time,
                                                          :visual => p_to_o_relation_type.visual,
                                                          :internal => true)
                interpersonal.articles = articles
                interpersonal.litigations = self.litigations
                interpersonal.save
end
              end
            end
          end
        end
      end
    else # törlés történt
      self.destroy
    end
  end


  # --- Permissions --- #

  def create_permitted?
   acting_user.administrator? || acting_user.editor?
  end

  def update_permitted?
    acting_user.administrator? || acting_user.editor?
  end

  def destroy_permitted?
    acting_user.administrator? || acting_user.editor?
  end

  def view_permitted?(field)
    true
  end

end

