# -*- encoding : utf-8 -*-
class Person < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    first_name   :string #, :required
    last_name    :string #, :required
    name         :string
    street       :string
    city         :string
    zip_code     :string
    country      :string
    klink        :string
    born_at      :date
    mothers_name :string
    mothers_name_alternate :string # ha megtaláltuk, de nem biztos, h ő az, akkor ide tesszük complex-ből
    complexed_at :date
    interpersonal_relations_count :integer, :default => 0
    person_to_org_relations_count :integer, :default => 0
    search_result_count           :integer, :default => 0
    relations_counter             :integer, :default => 0
    relations_bit                 :boolean, :default => false
    complex_xml :text
    timestamps
    address :string
    cv :text
    link :string
    order_name :string, :index => true
  end

  default_scope  :order => 'order_name' 

  named_scope :info, lambda { |info_ids| info_ids.present? ? { :conditions => [ "people.information_source_id in (?)", info_ids ]} : {} }

  before_save do |r|
    r.normalize_name
    r.clean_name
    if r.name
      r.order_name = r.name
      (%w{id. ifj. dr. Dr. DR.} + ['ifj ', 'id ', 'dr ', 'Dr ', 'DR ', 'Prof dr.', 'Prof. dr. ', 'prof dr. ', 'prof. dr. ' , 'Prof. Dr. ', 'Prof Dr. ', 'prof. Dr ', 'Professzor Dr.'  ]).each do |pre|
        if r.name[0..pre.size-1] == pre
          r.order_name = r.name[pre.size..-1].strip + ' ' + pre
        end
      end
    end
=begin
    Person.update_counters r.id, :interpersonal_relations_count => -r.interpersonal_relations_count + (isize = r.interpersonal_relations.count)
    Person.update_counters r.id, :person_to_org_relations_count => -r.person_to_org_relations_count + (psize = r.person_to_org_relations.count)
    r.relations_counter = isize + psize
    r.relations_bit = true if r.relations_counter > 0
=end
    if r.zip_code.blank? and r.city.blank? and r.street.blank?
      r.address = " "
    else
      r.address = "#{r.zip_code} #{r.city}, #{r.street}" 
    end
  end

  belongs_to :selected_organization, :class_name => "Organization"

  validates_presence_of :information_source

  has_many :person_grade_assocs
  has_many :person_grades, :through => :person_grade_assocs, :accessible => true

  belongs_to :place_of_birth

  # ez az összes kapcsolat, azok is, amit a rendszer generált
  has_many :interpersonal_relations, :accessible => true
  has_many :people, :through => :interpersonal_relations, :source => :related_person

  # ezek csak a kézzel bevitt kapcsolatok
  has_many :personal_relations, :conditions => [ "internal = ?", false], :class_name => "InterpersonalRelation", :accessible => true

  # helperek a vizualicáziós részhez
  has_many :personal_non_litigation_relations, :conditions => [ "interpersonal_relations.visual = ?", true], :class_name => "InterpersonalRelation"
  has_many :personal_litigation_relations, :conditions => [ "interpersonal_relations.visual = ?", false], :class_name => "InterpersonalRelation"
  has_many :person_to_org_non_litigation_relations, :conditions => [ "person_to_org_relations.visual = ?", true], :class_name => "PersonToOrgRelation"
  has_many :person_to_org_litigation_relations, :conditions => [ "person_to_org_relations.visual = ?", false], :class_name => "PersonToOrgRelation"


  # helperek adminhoz
  has_many :manual_interpersonal_relations, :conditions => [ "interpersonal_relations.parsed = ?", false], :class_name => "InterpersonalRelation", :accessible => true
  has_many :manual_person_to_org_relations, :conditions => [ "person_to_org_relations.parsed = ?", false], :class_name => "PersonToOrgRelation", :accessible => true

  has_many :person_to_org_relations, :accessible => true, :order => "organization_id"

  has_many :organizations, :through => :person_to_org_relations

  belongs_to :information_source
  belongs_to :user, :creator => true

  has_many :person_histories

  belongs_to :merge_from, :class_name => "Person"
  
  def to_param
    "#{id}-#{name.to_textual_id}"
  end

  def address
    if zip_code.blank? and city.blank? and street.blank?
      " "
    else
      "#{zip_code} #{city}, #{street}"
    end
  end


  def self.merge into_this, this

#    this.person_grade_assocs.each      { |f| f.person_id = into_this.id; f.save(false) }
# we check whether the person_grade already associated with our into.this person
    this.person_grade_assocs.each      { |f|
    grade = PersonGradeAssoc.find_by_person_id_and_person_grade_id( into_this.id, f.person_grade_id)
    if !grade
        f.person_id = into_this.id; f.save(false)
    end
   }
    this.interpersonal_relations.each  { |f| f.person_id = into_this.id; f.save(false) }
    this.person_to_org_relations.each  { |f| f.person_id = into_this.id; f.save(false) }
    this.person_histories.each         { |f| f.person_id = into_this.id; f.save(false) }
    into_this.save(false)

#   this.person_grade_assocs.destroy_all
#   this.person_to_org_relations.destroy_all
#   this.interpersonal_relations.destroy_all
#   this.person_histories.destroy_all
    this.reload
#    this.destroy

  end
 

  def find_path a, target, ig
    @level = 0
    if a == target
       @this << [a]
       return
    end   
    afirstneighbours = Array.new
    #checkarr = Array.new
    #checkarr << a
    a.people.each do |p|
       #relation_type_id = InterpersonalRelation.find_by_person_id(a.id).find_by_related_person_id(p.id)_?.p_to_p_relation_type_id
       #relation_typ = InterpersonalRelation.find(:first, :conditions => ['person_id LIKE ? and related_person_id LIKE ?', a.id, p.id])
       #@relation_type_id = relation_typ.p_to_p_relation_type_id.to_s
       #@relation_type_id = InterpersonalRelation.find(:first, :conditions => ['person_id LIKE ? and related_person_id LIKE ?', a.id, p.id]).p_to_p_relation_type_id.to_s
       if checkable(a,p,ig)
       afirstneighbours << p
       #checkarr << p
       if p == target
          retarr = Array.new
          retarr << a
          retarr << p
          #@this << p
          @this << retarr
          @level = 1
          return
       end
       end
    end
    
    

    secind=0
    secondend = false
    asecondneighbours = Array.new
    afirstneighbours.each do |s|
      asecondneighbours << Array.new
      s.people.each do |sp|
        #if !checkarr.include?(sp)
        if checkable(s,sp,ig)
        #checkarr << sp
        asecondneighbours[secind] << sp
 
       if sp == target
           secondend = true
           retarr = Array.new
           retarr << a
           retarr << s
           retarr << sp
           @this << retarr   
        end
# checkable end
        end 
      end
      secind = secind + 1
      #end
    end
    if secondend == true
      return
    end
	
	counterm = 0
    @ret1 = 0
    @ret2 = 0
    firstind=0
    thirdind=0
    secondind = 0
    thirdend = false
    athirdneighbours = Array.new
    asecondneighbours.each do |s|
      athirdneighbours << Array.new
      s.each do |sp|
      athirdneighbours[firstind] << Array.new
      athirdneighbours[firstind][secondind] = Array.new
        sp.people.each do |st|
        #if !checkarr.include?(st)
=begin		
		counterm = counterm + 1
		  if counterm == 1000
		  @this << "nincs"
	        return
			end
=end
        if checkable(sp,st,ig)
        #checkarr << st
#=begin
          athirdneighbours[firstind][secondind] << st
          #athirdneighbours[0][0] << st
          if st == target
             @ret1 = athirdneighbours[firstind].size()
             @ret2 = secondind
             thirdend = true
             retarr = Array.new
             retarr << a
             retarr << afirstneighbours[firstind]
             retarr << asecondneighbours[firstind] [secondind]
             retarr << st
             @this << retarr   
          end
		  
#=end    
        #checkable end
        end
         #end 
         end
        secondind = secondind + 1
      end
      firstind = firstind + 1
    end
    if thirdend == true
      return
    end
    
    @this << "nincs"
  end



  def path_to b, c
    results = ""
    counter = 1
    @this = []
    find_path self, b, c
    if @this[0].to_s == "nincs"
      results = "Nincsen köztük négynél nem hosszab út!"
    else
      @this.each do |t|
         
         results << counter.to_s  
         counter = counter + 1
         results << ". út: "
         results <<  "<br/><br/>"
         t.each do |w| results << w.linked_name + "    " end
         #@this[0].each do |w| results << w.linked_name + "    " end
         results << "<br/><br/>"
    end
    results << " "
  #  results << @ret1.to_s + " "
 #   results << @ret2.to_s + " "
 #   results << c
 #  results << @cc
    end  
   end

  def checkable a, p, ig

      @cc = "nem sajto"
      if ig == 'ign'
	  rts = InterpersonalRelation.find(:all, :conditions => ['person_id LIKE ? and related_person_id LIKE ?', a.id, p.id]) 
         rts.each do |w|
           if w.p_to_p_relation_type_id != 5
             return true
           end
         end
         # ha csak sajtokapcsolatot talalunk
         return false
       end
       return true
  end

=begin
  def checkable a, p, ig

      @cc = "nem sajto"
      if ig == 'ign'
	  rtid = InterpersonalRelation.find(:first, :conditions => ['person_id LIKE ? and related_person_id LIKE ?', a.id, p.id]).p_to_p_relation_type_id
         # ha sajtokapcsolatot talalunk
         @cc = rtid.to_s
         if rtid == 5
             @cc = "sajto"
             return false
         end
       end
       return true
  end 
=end

  def linked_name
    "<a style='color: #6EA4B0' target='_blank' href='/people/#{id}'>#{name}</a>"
     #"naa"
    # css nem tom mi�rt nem muxik
  end

  def normalize_name
    if last_name
      self.name = last_name.to_s.strip + ' ' + first_name.to_s.strip
      if born_at and born_at.year == Time.now.year
        self.born_at = nil
      end
    else
      if name
        names = name.split(' ')
        self.last_name = names[0]
        self.first_name = names[1..-1].join(' ') if names[1]
      end
    end
  end

  def clean_name
    birosag = InformationSource.find_by_name("birosag.hu")
    if name and information_source_id == birosag.id
      puts name.inspect
      exclude = ["( dr.Szunyogh Valériával együtt)", "( együttesen )", "( elnök )", "( önállóan )", "(a kuratóriumi elnökkel együttesen)", "(alkalmazott)", "(együttesen)", "(elnök) önállóan", "(ketten együtt)", "(önálló)", "/ együttesen", "/ együttesen", "/ eln.tag", "/ Elnök kettö együt", "/ elnök önállóan", "/ elnökhelyettes", "/ ketten együtt", "/ kettő együtt", "/ önállóan", "/ pénztáros", "/ titkár", "/együtt", "/együttesen/ *! **!", "/Elnökh. kettö együtt", "/kettö e", "/önállóan", "/önállóan", "a kuratórium elnöke", "a kuratórium titkára", "alelnök", "alelnök", "alelnök (együttesen)", "alelnök (elején is)", "alelnök elnökkel együtt", "által képviselt tulajdonközösség", "az Ügyvezető Testület elnöke", "az Ügyvezető Testület tagja", "döntőbizottsági tag", "döntőbizottsági tag", "együtt", "együttesen", "eln./önáll.", "elnök", "elnök - igazgató", "elnök akadály esetén", "elnök önálló", "elnök önállóan", "elnökh.", "elnökhelyettes", "elnökkel együtt", "elnökségi tag", "értékesítési és marketing igazgató", "és egy társa", "és társai", "és társai", "forgalmi üzemmérnök - üzemigazgató helyettes", "főtitkár", "gazdasági főmunkatárs", "gazdasági vezérigazgató-helyettes", "igazgatósági", "igazgatósági tag", "IT elnök", "IT tag", "It.tag/másik tagga", "képviseleti joga a 16.Pk.61.042/2003/13. sz. végzés alapján szünetel", "ketten együtt", "kettő együtt", "közös", "közös képviselő", "közös képviselő és 4 társa", "közös törzsbetét képviselő", "kuratóriumi elnök", "kuratóriumi tag", "kuratóriumi titkár", "más munkavállaló", "munkavállaló", "önálló", "önállóan", "szállodaigazgató", "szervezési elnökhelyettes", "tag+másik 2 tag", "társelnök", "titkár", "ügyintéőz társelnök", "ügyvezető", "ügyvezető elnök", "üzletrész képv."]
      if !exclude.include?(name) # ha a név pont uganaz, mint a kiveendő, szöveg, akkor ne foglalkozzunk vele
        exclude.each do |w|
          if name.include?( w )
            s = name.split( w )
            self.name = s[0]
            self.name = s[1] if s[1] and s[1].size > s[0].size
            self.last_name = nil
            normalize_name
            PersonToOrgRelation.information_source_id_is(birosag.id).person_id_is(id).each do |rel|
              rel.role = w
              rel.save
            end  
          end
        end
      end
    end
  end

  # --- Permissions --- #
  def create_permitted?
    acting_user.administrator? || (acting_user.editor? && user.id == acting_user.id)
  end

  def update_permitted?
    acting_user.administrator? || acting_user.editor? || acting_user.supervisor?
  end

  def destroy_permitted?
    acting_user.administrator? || acting_user.supervisor? || acting_user.editor?
  end


  def view_permitted?(field)
    true
  end

end

