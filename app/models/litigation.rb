# -*- encoding : utf-8 -*-
class Litigation < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    name       :string
    description  :text
    start_time :date
    end_time   :date
    timestamps
    search_result_count           :integer, :default => 0
  end

  default_scope  :order => 'name'

  has_many :litigation_relations
  belongs_to :information_source

  named_scope :info, lambda { |info_ids| info_ids.present? ? { :conditions => [ "litigations.information_source_id in (?)", info_ids ]} : {} }

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

