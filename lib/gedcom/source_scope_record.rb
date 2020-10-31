require 'gedcom_base.rb'

#Internal representation of the GEDCOM DATA record type, a record type under the GEDCOM Level 0 SOUR record type
#
#=SOURCE_RECORD:= 
#  0 @<XREF:SOUR>@ SOUR                       {0:M}
#    +1 DATA                                  {0:1}
#      +2 EVEN <EVENTS_RECORDED>              {0:M}
#        +3 DATE <DATE_PERIOD>                {0:1}
#        +3 PLAC <SOURCE_JURISDICTION_PLACE>  {0:1}
#      +2 AGNC <RESPONSIBLE_AGENCY>           {0:1}
#      +2 <<NOTE_STRUCTURE>>                  {0:M}
#    ...
#
#The attributes are all arrays. 
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in the SOUR.DATA records.

class Source_scope_record < GEDCOMBase
  attr_accessor :events_list_record, :agency, :note_citation_record

  ClassTracker <<  :Source_scope_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
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

