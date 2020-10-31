require 'gedcom_base.rb'

#Internal representation of the GEDCOM NOTE record type
#Both inline and level 0 NOTEs are stored here and both are referenced through the Note_citation_record class. 
#NOTES are also used to store user defined tags, so can appear in places the GEDCOM standard doesn't specify NOTEs.
#
#=NOTE_RECORD:=
#  0 @<XREF:NOTE>@ NOTE <SUBMITTER_TEXT>    {0:M}
#    +1 [ CONC | CONT] <SUBMITTER_TEXT>     {0:M}
#    +1 <<SOURCE_CITATION>>                 {0:M}
#    +1 REFN <USER_REFERENCE_NUMBER>        {0:M}
#      +2 TYPE <USER_REFERENCE_TYPE>        {0:1}
#    +1 RIN <AUTOMATED_RECORD_ID>           {0:1}
#    +1 <<CHANGE_DATE>>                     {0:1}
#
#  I also recognise notes in this record, so I can handle user tags as notes.
#    +1 <<NOTE_STRUCTURE>>                  {0:M}
#
#=NOTE_STRUCTURE:= (The inline NOTE, defined in NOTE_STRUCTURE is also stored here)
#    n NOTE [SUBMITTER_TEXT> | <NULL>] {1:1} p.51
#      +1 [ CONC | CONT ] <SUBMITTER_TEXT> {0:M}
#      +1 <<SOURCE_CITATION>> {0:M}
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in the NOTE records.
class Note_record < GEDCOMBase
  attr_accessor :note_ref, :note, :source_citation_record
  attr_accessor :restriction, :refn_record, :automated_record_id, :change_date_record
  attr_accessor :note_citation_record
  
  ClassTracker <<  :Note_record
  
  def to_gedcom(level=0)
    if @note_ref != nil
      @this_level = [ [:xref, "NOTE", :note_ref] ]
      @sub_level =  [ #level + 1
                      [:conc, "CONC", :note],
                      [:print, "RESN", :restriction ],
                      [:walk, nil,    :source_citation_record ],
                      [:walk, nil,    :note_citation_record ],
                      [:walk, nil, :refn_record ],
                      [:print, "RIN",  :automated_record_id ],
                      [:walk, nil,    :change_date_record],
                    ] 
    else
      @this_level = [ [:cont, "NOTE", :note] ]
      @sub_level =  [ #level + 1
                      [:print, "RESN", :restriction ],
                      [:walk, nil,    :source_citation_record ],
                      [:walk, nil,    :note_citation_record ],
                      [:walk, nil, :refn_record ],
                      [:print, "RIN",  :automated_record_id ],
                      [:walk, nil,    :change_date_record],
                    ]
    end
    super(level)
  end
end

