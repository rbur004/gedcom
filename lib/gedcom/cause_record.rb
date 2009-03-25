require 'gedcom_base.rb'

#Cause_record is part of Event_record, recording the cause of the event. They aren't
#often seen in GEDCOM files.
#
#=EVENT_DETAIL:=
#  ...
#  n CAUS <CAUSE_OF_EVENT>                   {0:1}
#  ...
#
#  I have added a Restriction notice, a Source_citation_record, and a NOTE. As long as
#  you don't use these fields, the GEDCOM output will be standard. Restriction notice 
#  tags, like NOTE and SOUR tags, should be part of every record type, but they aren't.
#
#    +1 RESN <RESTRICTION_NOTICE>             {0:1}
#    +1 <<SOURCE_CITATION>>                   {0:M}
#    +1 <<NOTE_STRUCTURE>>                    {0:M}
#
#==CAUSE_OF_EVENT:=                                               {Size=1:90}
#  Used in special cases to record the reasons which precipitated an event. Normally this will be used
#  subordinate to a death event to show cause of death, such as might be listed on a death certificate.
#
# 
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
class Cause_record   < GEDCOMBase
  attr_accessor :cause, :restriction, :source_citation_record
  attr_accessor :note_citation_record

  ClassTracker <<  :Cause_record

  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:print, "CAUS", :cause] ]
    @sub_level =  [ #level + 1
                    [:print, "RESN", :restriction],
                    [:walk, nil,  :source_citation_record],
                    [:walk, nil, :note_citation_record],
                  ]
  end
  
end
