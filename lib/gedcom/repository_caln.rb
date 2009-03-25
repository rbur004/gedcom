require 'gedcom_base.rb'

#Internal representation of the GEDCOM CALN record type, a sub-record of Repository_citation_record.
#
#=SOURCE_CALL_NUMBER:=
#  -1 REPO @XREF:REPO@               {1:1} Parent record
#    ...
#    n CALN <SOURCE_CALL_NUMBER>   {0:M} ** CALN record **
#      +1 MEDI <SOURCE_MEDIA_TYPE>    {0:1}
#
#  The number used by a repository to identify the specific items in its collections.
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in the CALN records.
class Repository_caln < GEDCOMBase
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

