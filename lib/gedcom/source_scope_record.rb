require 'gedcom_base.rb'

class Source_scope_record < GedComBase
  attr_accessor :events_list_record, :agency, :note_citation_record

  ClassTracker <<  :Source_scope_record
  
  def initialize(*a)
    super(*a)
    @this_level = [[:nodata, "DATA", nil]]
    @sub_level =  [ #level + 1
                    [:walk, nil, :events_list_record],
                    [:print, "AGNC",:agency],
                    [:walk, nil, :note_citation_record],
                  ]
  end 
end

