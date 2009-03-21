require 'gedcom_base.rb'

class Events_list_record < GedComBase
  attr_accessor :recorded_events, :date_period, :place_record
  attr_accessor :note_citation_record

  ClassTracker <<  :Events_list_record
  
  def initialize(*a)
    super(*a)
    @this_level = [ [:print, "EVEN", :recorded_events] ]
    @sub_level =  [ #level + 1
                    [:print, "DATE", :date_period],
                    [:walk, nil,    :place_record],
                    [:walk, nil, :note_citation_record],
                  ]
  end  
end

