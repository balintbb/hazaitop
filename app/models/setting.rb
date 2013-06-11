# -*- encoding : utf-8 -*-
class Setting < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    timestamps
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
    acting_user.administrator? || acting_user.supervisor? || acting_user.editor?
  end

end

