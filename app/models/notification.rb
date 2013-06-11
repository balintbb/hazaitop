# -*- encoding : utf-8 -*-
class Notification < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    timestamps
    name :string
    issued_at :date
    processed :boolean, :default => false
    number :string
    contracted_value :integer, :limit => 8
  end

#  default_scope :order => "contracted_value DESC"
  
  has_many :contracts, :accessible => true, :dependent => :destroy
  has_many :interorg_relations

  def summarize_value
    self.contracted_value = contracts.*.contracted_value.sum
    self.save
  end


  def url
    "http://www.kozbeszerzes.hu/lid/ertesito/pid/0/ertesitoProperties?objectID=Lapszam.portal_#{number}"
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

