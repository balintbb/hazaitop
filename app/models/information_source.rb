# -*- encoding : utf-8 -*-
class InformationSource < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    name     :string, :required
    web      :string, :required
    weight   :float, :default => 1
    domain_name   :string
    internal :boolean, :default => false
    timestamps
  end

  has_many :recent_articles, :order => "updated_at DESC", :limit => 10, :class_name => "Article"

  before_save do |record|
    unless record.web.blank?
      d = Domainatrix.parse(record.web)
      record.domain_name = d.domain + '.' + d.public_suffix
    end
  end

  # --- Permissions --- #

  def create_permitted?
    acting_user.administrator? || acting_user.supervisor? || acting_user.editor?
  end

  def update_permitted?
    acting_user.administrator? || acting_user.supervisor? || acting_user.editor?
  end

  def destroy_permitted?
    acting_user.administrator? || acting_user.supervisor?
  end

  def view_permitted?(field)
    true
  end

end

