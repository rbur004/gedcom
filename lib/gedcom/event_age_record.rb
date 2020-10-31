require 'gedcom_base.rb'

#HUSB and WIFE tags can have an AGE record associated with them.
#
#=FAM_RECORD:=
#  0 @<XREF:FAM>@ FAM                     {0:M}
#    1 <<FAMILY_EVENT_STRUCTURE>>         {0:M}
#      n HUSB                             {0:1}
#        +1 AGE <AGE_AT_EVENT>            {1:1} ****
#      n WIFE                             {0:1}
#        +1 AGE <AGE_AT_EVENT>            {1:1} ****
#    ...
#
#  I also recognise notes in this record, so I can handle user tags as notes.
#        +1 <<NOTE_STRUCTURE>>            {0:M}
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
class Event_age_record < GEDCOMBase
  attr_accessor :relation, :age
  attr_accessor :note_citation_record

  ClassTracker <<  :Event_age_record
  
  def to_gedcom(level=0)
    @this_level = [ [:nodata, @relation[0], nil] ] #dynamic, so need to define after initialize method.
    @sub_level =  [ #level + 1
                    [:print, "AGE",  :age],
                    [:walk, nil,  :note_citation_record]
                  ]
    super(level)
  end
end

