require 'gedcom_base.rb'

class Family_record < GedComBase
  attr_accessor :restriction #not standard at the event level, but we might want this in DB.
  attr_accessor :family_ref, :event_record, :husband_ref, :wife_ref, :child_ref, :number_children, :submitter_ref
  attr_accessor :source_citation_record, :multimedia_citation_record
  attr_accessor :note_citation_record, :refn_record, :automated_record_id, :change_date_record

  ClassTracker <<  :Family_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:xref, "FAM", :family_ref] ]
    @sub_level =  [ #level + 1
                    [:xref, "HUSB", :husband_ref],
                    [:xref, "WIFE", :wife_ref],
                    [:xref, "CHIL", :child_ref],
                    [:print, "NCHI", :number_children],
                    [:walk, nil, :event_record],
                    [:xref, "SUBM", :submitter_ref],
                    [:walk, nil,   :multimedia_citation_record],
                    [:walk, nil,  :source_citation_record],
                    [:walk, nil, :note_citation_record],
                    [:walk, nil, :refn_record],
                    [:print, "RIN", :automated_record_id],
                    [:walk, nil,  :change_date_record],
                  ]
  end  
  
  def id
    #temporary 
    @family_ref
  end
  
  def husband
    if @husband_ref != nil
      find(@husband_ref[0], @husband_ref[1])
    else
      nil
    end
  end
  
  def wife
    if @wife_ref != nil
      find(@wife_ref[0], @wife_ref[1])
    else
      nil
    end
  end
  
end
