require 'gedcom_base.rb'

class Citation_event_type_record < GedComBase
  attr_accessor :event_type, :role
  attr_accessor :note_citation_record

  ClassTracker <<  :Citation_event_type_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:print, "EVEN", :event_type ] ]
    @sub_level =  [ #level 1
                    [:print, "ROLE", :role],
                    [:walk, nil,    :note_citation_record ],
                  ]
  end
end

