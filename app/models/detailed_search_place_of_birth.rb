class DetailedSearchPlaceOfBirth < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields {}

  belongs_to :place_of_birth
  belongs_to :detailed_search

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
