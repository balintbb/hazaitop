# -*- encoding : utf-8 -*-
class PToPRelationType < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    name     :string, :required, :name => true, :index => true
    weight   :float, :default => 1
    internal :boolean, :default => false
    visual   :boolean, :default => true
    litig    :boolean, :default => false
    label    :string
    parsed   :boolean, :default => false
    timestamps
  end

  def graph_label
    label.blank? ? name : label
  end

  belongs_to :pair, :class_name => "PToPRelationType"

  has_many :interpersonal_relations
  has_many :people       , :through => :interpersonal_relations#, :accessible => true

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

