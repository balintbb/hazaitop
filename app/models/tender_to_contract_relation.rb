class TenderToContractRelation < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    timestamps
  end

  def name
    "#{tender} és #{contract}"
  end

  belongs_to :tender
  belongs_to :contract

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

