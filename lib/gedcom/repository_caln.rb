require 'gedcom_base.rb'

#Internal representation of the GEDCOM CALN record type
#
#The attributes are all arrays. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in the CALN records.
class Repository_caln < GedComBase
  attr_accessor :media_type, :call_number
  attr_accessor :note_citation_record

  ClassTracker <<  :Repository_caln
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level =  [ [:print, "CALN", :call_number] ]  
    @sub_level =  [ #level + 1
                    [:print, "MEDI",  :media_type],
                    [:walk, nil,   :note_citation_record],
                  ]
  end 
end

