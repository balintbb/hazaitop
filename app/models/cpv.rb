# -*- encoding : utf-8 -*-
class Cpv < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do    
	name :string    
	description :string
	proba :string
    timestamps
  end

  has_many :contract_cpv_rels
  has_many :contracts, :through => :contract_cpv_rels, :accessible => true

  def to_s
    "#{description} #{name}"
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

