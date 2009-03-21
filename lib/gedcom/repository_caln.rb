require 'gedcom_base.rb'

class Repository_caln < GedComBase
  attr_accessor :media_type, :call_number
  attr_accessor :note_citation_record

  ClassTracker <<  :Repository_caln
  
  def initialize(*a)
    super(*a)
    @this_level =  [ [:print, "CALN", :call_number] ]  
    @sub_level =  [ #level + 1
                    [:print, "MEDI",  :media_type],
                    [:walk, nil,   :note_citation_record],
                  ]
  end 
end

