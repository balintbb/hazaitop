class DetailedSearch < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    query        :string
    address      :string
    subject      :string
    date_from    :date
    date_to      :date
    person       :boolean, :default => false
    organization :boolean, :default => false
    article      :boolean, :default => false
    litigation   :boolean, :default => false
    date_from_enable    :boolean, :default => false
    date_to_enable      :boolean, :default => false 
    amount_from  :integer
    amount_to    :integer
    contract     :boolean
    tender       :boolean
  end

  has_many :detailed_search_place_of_births
  has_many :place_of_births, :through => :detailed_search_place_of_births, :accessible => true
  has_many :detailed_search_activities
  has_many :activities, :through=>:detailed_search_activities, :accessible => true
  has_many :detailed_search_sectors
  has_many :sectors, :through => :detailed_search_sectors, :accessible => true
  has_many :detailed_search_cpvs
  has_many :cpvs, :through => :detailed_search_cpvs, :accessible => true

  has_many :detailed_search_relations, :accessible => true
  has_many :relations, :through => :detailed_search_relations, :accessible => true

  # --- Permissions --- #

  def create_permitted?
    true
  end

  def update_permitted?
    true
  end

  def destroy_permitted?
    true
  end

  def view_permitted?(field)
    true
  end

end
