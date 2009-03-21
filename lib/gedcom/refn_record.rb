require 'gedcom_base.rb'

class Refn_record < GedComBase
  attr_accessor :ref_type, :user_reference_number
  attr_accessor :note_citation_record

  ClassTracker <<  :Refn_record
  
  def initialize(*a)
    super(*a)
    @this_level =  [ [:print, "REFN", :user_reference_number] ]  
    @sub_level =  [ #level + 1
                    [:print, "TYPE", :ref_type],
                    [:walk, nil,  :note_citation_record],
                  ]
  end 
end

