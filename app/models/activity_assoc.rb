# -*- encoding : utf-8 -*-
class ActivityAssoc < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields

  belongs_to :activity
  belongs_to :organization

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

