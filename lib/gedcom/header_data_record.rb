require 'gedcom_base.rb'

class Header_data_record < GedComBase
  attr_accessor :data_source, :date, :copyright
  attr_accessor :note_citation_record

  ClassTracker <<  :Header_data_record
  
  def initialize(*a)
    super(*a)
    @this_level = [ [:print, "DATA", :data_source] ]
    @sub_level =  [ #level + 1
                    [:print, "DATE", :date],
                    [:print, "COPR", :copyright],
                    [:walk, nil,    :note_citation_record],
                  ]
  end  
end
