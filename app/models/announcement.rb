# -*- encoding : utf-8 -*-
class Announcement < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    start_time       :date
    end_time         :date
    content          :text
    labjegyezet      :string
    tipus            :string 
    tipusnev         :string 
    issued_at        :date
    ugyszam          :string
    eugyszam         :string
    birosag          :string
    felszamolo_neve  :string
    felszamolo_cime  :string
    felszamolo_cgjsz :string
    felszbizt1_nev   :string
    felszbizt1_cim   :string
    felszbizt1_irsz  :string
    felszbizt2_nev   :string
    felszbizt2_cim   :string
    felszbizt2_irsz  :string
    legal_at         :date
    submitted_at     :date
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

