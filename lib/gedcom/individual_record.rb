require 'gedcom_base.rb'

class Individual_record < GedComBase
  attr_accessor :individual_ref, :restriction, :name_record, :event_record, :individual_attribute_record, :alias_ref
  attr_accessor :families_individuals, :individuals_individuals, :submitter_ref
  attr_accessor :source_citation_record, :multimedia_citation_record, :note_citation_record
  attr_accessor :registered_ref_id, :lds_ancestral_file_no, :refn_record, :automated_record_id, :change_date_record

  ClassTracker <<  :Individual_record
  
  def initialize(*a)
    super(*a)
    @this_level = [ [:xref, "INDI", :individual_ref] ]
    @sub_level =  [ #level 1
                    [:print, "RESN", :restriction],
                    [:walk, nil,  :name_record],
                    [:walk, nil, :individual_attribute_record],
                    [:walk, nil, :event_record],
                    [:walk, nil, :families_individuals],
                    [:walk, nil, :individuals_individuals],
                    [:xref, "ALIA", :alias_ref],
                    [:xref, "SUBM", :submitter_ref],
                    [:walk, nil,    :multimedia_citation_record ],
                    [:walk, nil,    :source_citation_record ],
                    [:walk, nil,    :note_citation_record ],
                    [:print, "RFN", :registered_ref_id],
                    [:print, "AFN", :lds_ancestral_file_no],
                    [:walk, nil, :refn_record ],
                    [:print, "RIN",  :automated_record_id ],
                    [:walk, nil,    :change_date_record],
                  ]
  end  
  
  def id
    #temporary 
    @individual_ref
  end
  
  def parents_family
    parents_family = []
    @families_individuals.each { |m| parents_family << m.parents_family_ref if m.relationship_type == "FAMC"}
    parent_family
  end
  
  def spouses
    spouses = []
    @families_individuals.each { |m| spouses << m.own_family if m.relationship_type == "FAMS"}
    spouses
  end
  
  def birth
    if @event_record
      @event_record.each { |e| if e.is_event('BIRT') then return e end }
    else
      nil
    end
  end
  
  def death
    if @event_record 
      @event_record.each { |e| if e.is_event('DEAT') then return e end }
    else
      nil
    end
  end
end
