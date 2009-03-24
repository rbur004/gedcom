require 'gedcom_base.rb'

class Cause_record   < GedComBase
  attr_accessor :cause, :restriction, :source_citation_record
  attr_accessor :note_citation_record

  ClassTracker <<  :Cause_record

  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:print, "CAUS", :cause] ]
    @sub_level =  [ #level + 1
                    [:print, "RESN", :restriction],
                    [:walk, nil,  :source_citation_record],
                    [:walk, nil, :note_citation_record],
                  ]
  end
  
end
