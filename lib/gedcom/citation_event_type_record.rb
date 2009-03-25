require 'gedcom_base.rb'

#Source_citation_record has an EVEN tag. This is not an Event_record, but the event
#type that the source record records.
#
#=SOURCE_CITATION:= (within another record, referencing a SOURCE_RECORD)
#  -1 SOUR @<XREF:SOUR>@                         {1:1} (pointer to source record)
#    ...
#    n  EVEN <EVENT_TYPE_CITED_FROM>            {0:1}
#      +1 ROLE <ROLE_IN_EVENT>                  {0:1}
#    ...
#
#==EVENT_TYPE_CITED_FROM:=                      {SIZE=1:15}
#  <EVENT_ATTRIBUTE_TYPE>
#
#  A code that indicates the type of event which was responsible for the source entry being recorded. For
#  example, if the entry was created to record a birth of a child, then the type would be BIRT regardless
#  of the assertions made from that record, such as the mother's name or mother's birth date. This will
#  allow a prioritized best view choice and a determination of the certainty associated with the source
#  used in asserting the cited fact.
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
class Citation_event_type_record < GEDCOMBase
  attr_accessor :event_type, :role
  attr_accessor :note_citation_record

  ClassTracker <<  :Citation_event_type_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:print, "EVEN", :event_type ] ]
    @sub_level =  [ #level 1
                    [:print, "ROLE", :role],
                    [:walk, nil,    :note_citation_record ],
                  ]
  end
end

