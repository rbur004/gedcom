require 'gedcom_base.rb'

#Citation_data_record is DATA record in a Source_citation_record.
# 
#=SOURCE_CITATION:= (within another record, referencing a SOURCE_RECORD)
#  -1 SOUR @<XREF:SOUR>@                        {1:1} (pointer to source record)
#    ...
#    n DATA                                     {0:1}
#      +1 DATE <ENTRY_RECORDING_DATE>           {0:1}
#      +1 TEXT <TEXT_FROM_SOURCE>               {0:M}
#        +2 [ CONC | CONT ] <TEXT_FROM_SOURCE>  {0:M}
#    ...
#
#==ENTRY_RECORDING_DATE:=
#  <DATE_VALUE>
#
#  The date that this event data was entered into the original source document.
#
#==TEXT_FROM_SOURCE:=                           {Size=1:248}
#  <TEXT>
#
#  A verbatim copy of any description contained within the source. This indicates notes or text that are
#  actually contained in the source document, not the submitter's opinion about the source. This should
#  be, from the evidence point of view, "what the original record keeper said" as opposed to the
#  researcher's interpretation. The word TEXT, in this case, means from the text which appeared in the
#  source record including labels.
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
class Citation_data_record < GEDCOMBase
  attr_accessor :date_record, :text_record
  attr_accessor :note_citation_record

  ClassTracker <<  :Citation_data_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:print, "DATA", nil ] ]
    @sub_level =  [ #level 1
                    [:walk, nil, :date_record],
                    [:walk, nil, :text_record ],
                    [:walk, nil, :note_citation_record ],
                  ]
  end
end

