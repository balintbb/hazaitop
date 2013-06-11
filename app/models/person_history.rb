# -*- encoding : utf-8 -*-
class PersonHistory < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    parameters :text
    timestamps
  end

  belongs_to :user, :creator => true
  belongs_to :person

  # --- Permissions --- #

  def create_permitted?
    acting_user.administrator? || user_is?(acting_user)
  end

  def update_permitted?
    false 
  end

  def destroy_permitted?
    false
  end

  def view_permitted?(field)
    true
  end

end

