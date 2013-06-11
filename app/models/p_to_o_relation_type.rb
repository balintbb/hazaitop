# -*- encoding : utf-8 -*-
class PToORelationType < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    name   :string, :required
    weight :float, :required, :default => 1
    visual :boolean, :default => true
    litig  :boolean, :default => false
    label  :string
    parsed   :boolean, :default => false
    timestamps
  end

  def graph_label
    label.blank? ? name : label
  end

  belongs_to :p_to_p_relation_type   # ha nincs definiálva a kalkulátorban, akkor erre default-olunk
# validates_presence_of :p_to_p_relation_type

  belongs_to :pair, :class_name => "OToPRelationType"

  has_many :relations, :through => :p_to_o_relations
  has_many :p_to_o_relations# , :accessible => true


  has_many :person_to_org_relations
  has_many :organizations, :through => :person_to_org_relations#, :accessible => true
  has_many :people       , :through => :person_to_org_relations#, :accessible => true

  after_create do |r|
    t = OToPRelationType.create( :name => r.name,
                            :weight => r.weight,
                            :visual => r.visual,
                            :litig => r.litig,
                            :mirror_of_id => r.id,
                            :p_to_p_relation_type_id => r.p_to_p_relation_type_id
                          )
    r.update_attribute :pair_id, t.id
  end

  after_save do |r|
    o_to_p = OToPRelationType.find( r.pair_id )
    o_to_p.update_attributes( :name => r.name,
                           :weight => r.weight,
                           :visual => r.visual,
                           :litig => r.litig,
                           :p_to_p_relation_type_id => r.p_to_p_relation_type_id
                         )

  end

  after_destroy do |r|
    OToPRelationType.find( r.id ).delete
  end

  # --- Permissions --- #

  def create_permitted?
    acting_user.administrator? || acting_user.supervisor?
  end

  def update_permitted?
    acting_user.administrator? || acting_user.supervisor?
  end

  def destroy_permitted?
    acting_user.administrator? || acting_user.supervisor?
  end

  def view_permitted?(field)
    true
  end

end

