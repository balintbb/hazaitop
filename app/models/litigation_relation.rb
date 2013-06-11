# -*- encoding : utf-8 -*-
class LitigationRelation < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    timestamps
  end

  belongs_to :litigable, :polymorphic => true
  belongs_to :litigation

  named_scope :for_relations, lambda {|relations|
    conditions = ''
    Array(relations).each do |relation|
      if conditions.present?
        conditions << " or litigable_type='#{relation.class}' and litigable_id=#{relation.id}" 
      else
        conditions = "litigable_type='#{relation.class}' and litigable_id=#{relation.id}"
      end
    end
    {:conditions=>conditions}
  }
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

