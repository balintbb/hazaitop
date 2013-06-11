# -*- encoding : utf-8 -*-
class Financial < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    year                :integer
    start_time :date
    end_time :date
    szorzo              :integer, :limit => 8
    penznem             :string
    balance_sheet_total :integer, :limit => 8
    turnover            :integer, :limit => 8 
    a_eredm             :integer, :limit => 8 
    aktiv_el            :integer, :limit => 8 
    eszk                :integer, :limit => 8 
    celtart             :integer, :limit => 8 
    netto               :integer, :limit => 8
    forgo               :integer, :limit => 8
    kotelez             :integer, :limit => 8
    m_eredm             :integer, :limit => 8
    passziv_el          :integer, :limit => 8
    toke                :integer, :limit => 8
    u_eredm             :integer, :limit => 8
    labj                :text
    timestamps
  end

  belongs_to :organization, :counter_cache => true

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

