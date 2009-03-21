require 'gedcom_base.rb'

class Gedcom_record < GedComBase
  attr_accessor :version, :encoding_format
  attr_accessor :note_citation_record

  ClassTracker <<  :Gedcom_record
  
  def initialize(*a)
    super(*a)
    @this_level = [ [:nodata, "GEDC", nil] ]
    @sub_level =  [ #level + 1
                    [ :print, "VERS", :version],
                    [ :print, "FORM", :encoding_format],
                    [ :walk, nil,  :note_citation_record],
                  ]
  end  
end
