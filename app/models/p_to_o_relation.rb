class PToORelation < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields

  belongs_to :relation
  belongs_to :p_to_o_relation_type

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
