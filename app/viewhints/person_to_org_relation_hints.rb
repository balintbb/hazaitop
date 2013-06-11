# -*- encoding : utf-8 -*-
class PersonToOrgRelationHints < Hobo::ViewHints

  field_help :no_end_time => "End time is not applicable if the relationship still exist and there is no information abount ending"

  # model_name "My Model"
  # field_names :field1 => "First Field", :field2 => "Second Field"
  # field_help :field1 => "Enter what you want in this field"
  # children :primary_collection1, :aside_collection1, :aside_collection2
  children :articles
end

