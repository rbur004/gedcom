require 'gedcom_base.rb'


#Change_date_record is part of many other records, recording the
#date and time that the parent record was last altered. It also
#allows for a comment to be added. Probably not that useful, as
#the standard only allows for one of these in a parent record. It
#would be more useful to have a history of changes using multiple
#Change_records. It would also help to have them in more records.
#
#=CHANGE_DATE:=
#  n CHAN                       {1:1}
#    +1 DATE <CHANGE_DATE>      {1:1}
#      +2 TIME <TIME_VALUE>     {0:1}
#    +1 <<NOTE_STRUCTURE>>      {0:M}
#
#  The change date is intended to only record the last change to a record. Some systems may want to
#  manage the change process with more detail, but it is sufficient for GEDCOM purposes to indicate
#  the last time that a record was modified.
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
class Change_date_record < GEDCOMBase
  attr_accessor :date_record, :note_citation_record

  ClassTracker <<  :Change_date_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [ :nodata, "CHAN", nil] ]
    @sub_level =  [ #level + 1
                    [:walk, nil, :date_record],
                    [:walk, nil, :note_citation_record]
                  ]
  end
end
