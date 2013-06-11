# -*- encoding : utf-8 -*-
class ArticleRelation < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields

  belongs_to :relationable, :polymorphic => true, :accessible => true
  belongs_to :article, :accessible => true


  belongs_to :person_to_org_relation,  :class_name => "PersonToOrgRelation",   :foreign_key => "relationable_id"
  belongs_to :interpersonal_relation,  :class_name => "InterpersonalRelation", :foreign_key => "relationable_id"
  belongs_to :interorg_relation,       :class_name => "InterorgRelation",      :foreign_key => "relationable_id"

  def name
    id.to_s
  end

  # --- Permissions --- #

  def create_permitted?
    acting_user.administrator? || acting_user.supervisor? || acting_user.editor?
  end

  def update_permitted?
    acting_user.administrator? || acting_user.supervisor? || acting_user.editor?
  end

  def destroy_permitted?
    acting_user.administrator? || acting_user.supervisor? || acting_user.editor?
  end

  def view_permitted?(field)
    true
  end

end


