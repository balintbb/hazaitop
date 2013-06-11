# -*- encoding : utf-8 -*-
class Tender < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    name           :string
    project        :string
    op_name        :string
    amount         :integer, :limit => 8
    subsidy        :float
    currency       :string
    city           :string
    county         :string
    region         :string
    decided_at     :date
    decision_score :float
    unique_string  :text
    found :string
    source :string
    url :string
	# ZSOLT: kieg
	szerz_hatalyos  :date
	proj_leiras     :text
	proj_terv_kezd  :date
	proj_terv_bef   :date
	proj_teny_kezd  :date
	proj_teny_bef   :date
	# ZSOLT: kieg vége	
    timestamps
  end

  default_scope :order => "amount DESC"

  belongs_to :user

  belongs_to :information_source
  belongs_to :applicant, :class_name => "Organization"
  belongs_to :caller,    :class_name => "Organization"

  belongs_to :interorg_relation
  has_many :tender_to_contract_relations
  has_many :contracts, :through => :tender_to_contract_relations
  
  def to_param
    "#{id}-#{name.to_textual_id}"
  end


  def name 
    attributes["name"].blank? ? "<dokumentáció>" : attributes["name"]
  end

  after_save do |r|
    #r.interorg_relation.update_attribute :value, r.amount
  end

  # --- Permissions --- #

  def create_permitted?
    acting_user.administrator? || acting_user.supervisor?
  end

  def update_permitted?
    acting_user.administrator? || acting_user.supervisor?
  end

  def destroy_permitted?
    acting_user.administrator? || acting_user.supervisor?
  end

  def view_permitted?(field)
    true
  end

end

