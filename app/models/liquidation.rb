# -*- encoding : utf-8 -*-
class Liquidation < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    start_time    :date
    end_time      :date
    note          :text
    stays         :boolean, :default => false
    simple        :boolean, :default => false
    process_start :date
    process_end   :date
    type          enum_string( :csodeljaras, :felszamolas, :vegelszamolas)
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

