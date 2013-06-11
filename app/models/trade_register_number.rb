# -*- encoding : utf-8 -*-
class TradeRegisterNumber < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    start_time    :date
    end_time      :date
    nr            :string
    note          :text
    timestamps
  end

  belongs_to :organization


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

