# -*- encoding : utf-8 -*-
class Article < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    name    :text
    summary :text
    internet_address :string, :required, :unique
    weblink :string
    processed_at :date
    issued_at    :date
    search_result_count           :integer, :default => 0
    original_internet_address :string
    original_source :string
    timestamps
    to_news :boolean
  end

#  def self.find_by_name x
#    find_by_title x
#  end

  default_scope :order => 'issued_at DESC'

#  named_scope :recent, lambda {|limit|  {:limit => limit} }, :conditions => ["to_news = ?", true]
  named_scope :recent, lambda {|limit|  {:limit => limit}}
  named_scope :tonews, :conditions => ["to_news = true"]
  
  belongs_to :information_source
  belongs_to :user

  has_many :article_relations

  has_many :person_to_org_relations,
           :through => :article_relations,
           :source => :person_to_org_relation,
           :conditions => "article_relations.relationable_type = 'PersonToOrgRelation'",
           :accessible => true

  has_many :interorg_relations,
           :through => :article_relations,
           :source => :interorg_relation,
           :conditions => [ "article_relations.relationable_type = 'InterorgRelation' and mirror = ?", false ],
           :accessible => true

  has_many :interpersonal_relations,
           :through => :article_relations,
           :source => :interpersonal_relation,
           :conditions => [ "article_relations.relationable_type = 'InterpersonalRelation' and mirror = ?", false ],
           :accessible => true

  before_save do |article|
    unless article.internet_address.blank?
       d = Domainatrix.parse(article.internet_address)
       domain_name = d.domain + '.' + d.public_suffix
       i = InformationSource.find_or_create_by_domain_name( domain_name ) { |r| r.name = r.domain_name = domain_name; r.weight = 1; r.web = 'http://' + d.host }
       article.information_source_id = i.id
       article.original_internet_address = article.internet_address if article.original_internet_address.blank?
    end
  end

  validate :begins_with_http_or_https

  def begins_with_http_or_https
    if !internet_address.blank?
      unless (internet_address[0..6] == 'http://' or internet_address[0..7] == 'https://')
        errors.add("Internet address", "must begin with 'http://' or 'https://' copy from browser please")
      end
    end
  end

  lifecycle do
    state :normal, :default => true
    state :processed

    transition :progress, { :normal => :processed },
      :available_to => "User", :if => "acting_user.editor? or acting_user.supervisor? or acting_user.administrator?",
      :params => [ :processed_at ]

  end

  def to_param
    "#{id}-#{name.to_textual_id}"
  end

  # --- Permissions --- #

  def create_permitted?
    acting_user.administrator? || acting_user.supervisor? || acting_user.editor?
  end

  def update_permitted?
    acting_user.administrator? || acting_user.supervisor? || acting_user.editor?
  end

  def destroy_permitted?
    acting_user.administrator? || acting_user.supervisor? || acting_user.editor?
  end

  def view_permitted?(field)
    true
  end

end


