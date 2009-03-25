require 'gedcom_base.rb'

#The SOURCE_RECORD's DATA tag has an EVEN record, which differs from the 
#family or individual EVEN record type. It is a list of events that this
#source has data on, not the record of actual events.
#
#=SOURCE_RECORD:=
#  0 @<XREF:SOUR>@ SOUR                           {0:M}
#    +1 DATA {0:1}
#      +2 EVEN <EVENTS_RECORDED>                  {0:M} **This one**
#        +3 DATE <DATE_PERIOD>                    {0:1}
#        +3 PLAC <SOURCE_JURISDICTION_PLACE>      {0:1}
#    ...
#  I also recognise notes in this record, so I can handle user tags as notes.
#    +1 <<NOTE_STRUCTURE>>                        {0:M}
#
#==EVENTS_RECORDED:= {Size=1:90}
#  [<EVENT_ATTRIBUTE_TYPE> |
#  <EVENTS_RECORDED>, <EVENT_ATTRIBUTE_TYPE>]
#  An enumeration of the different kinds of events that were recorded in a particular source. Each
#  enumeration is separated by a comma. Such as a parish register of births, deaths, and marriages would
#  be BIRT, DEAT, MARR.
#
#==SOURCE_JURISDICTION_PLACE:= {Size=1:120}
#  <PLACE_VALUE>
#  The name of the lowest jurisdiction that encompasses all lower-level places named in this source. For
#  example, "Oneida, Idaho" would be used as a source jurisdiction place for events occurring in the
#  various towns within Oneida County. "Idaho" would be the source jurisdiction place if the events
#  recorded took place in other counties as well as Oneida County.
#
#==DATE_PERIOD:= {Size=7:35}
#  FROM <DATE> |
#  TO <DATE> |
#  FROM <DATE> TO <DATE>
#  
#  Where:
#    FROM = Indicates the beginning of a happening or state.
#    TO   = Indicates the ending of a happening or state.
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
class Events_list_record < GEDCOMBase
  attr_accessor :recorded_events, :date_period, :place_record
  attr_accessor :note_citation_record

  ClassTracker <<  :Events_list_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:print, "EVEN", :recorded_events] ]
    @sub_level =  [ #level + 1
                    [:print, "DATE", :date_period],
                    [:walk, nil,    :place_record],
                    [:walk, nil, :note_citation_record],
                  ]
  end  
end

