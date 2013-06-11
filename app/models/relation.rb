class Relation < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
#    name :string
  end

#  set_default_order :name
  has_many :o_to_o_relations
  has_many :p_to_p_relations
  has_many :p_to_o_relations

  has_many :o_to_o_relation_types, :through => :p_to_o_relations, :source => :p_to_o_relation_type, :accessible => true
  has_many :p_to_p_relation_types, :through => :p_to_p_relations, :source => :p_to_p_relation_type, :accessible => true
  has_many :p_to_o_relation_types, :through => :o_to_o_relations, :source => :o_to_o_relation_type, :accessible => true

  has_many :detailed_searches, :through => :detailed_search_relations
  has_many :detailed_search_relations

  # --- Permissions --- #

  def create_permitted?
    true 
  end

  def update_permitted?
    true 
  end

  def destroy_permitted?
    true 
  end

  def view_permitted?(field)
    true
  end

end
