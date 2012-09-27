require 'gedcom_base.rb'

#Internal representation of the GEDCOM SUBN record type
#
#=SUBMISSION_RECORD:=
#  0 @XREF:SUBN@ SUBN                     {0:M}
#    +1 SUBM @XREF:SUBM@                  {0:1}
#    +1 FAMF <NAME_OF_FAMILY_FILE>        {0:1}
#    +1 TEMP <TEMPLE_CODE>                {0:1}
#    +1 ANCE <GENERATIONS_OF_ANCESTORS>   {0:1}
#    +1 DESC <GENERATIONS_OF_DESCENDANTS> {0:1}
#    +1 ORDI <ORDINANCE_PROCESS_FLAG>     {0:1}
#    +1 RIN <AUTOMATED_RECORD_ID>         {0:1}
#
#  I also recognise notes in this record, so I can handle user tags as notes.
#    +1 <<NOTE_STRUCTURE>>                {0:M}
#
#  The sending system uses a submission record to send instructions and information to the receiving
#  system. TempleReady processes submission records to determine which temple the cleared records
#  should be directed to. The submission record is also used for communication between Ancestral File
#  download requests and TempleReady. Each GEDCOM transmission file should have only one
#  submission record. Multiple submissions are handled by creating separate GEDCOM transmission
#
#The attributes are all arrays. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in the SUBN records.


class Submission_record < GEDCOMBase
  attr_accessor :submission_ref, :submitter_ref, :lds_family_file, :lds_temple_code
  attr_accessor :generations_of_ancestor, :generations_of_descendant, :automated_record_id
  attr_accessor :process_ordinates, :note_citation_record

  ClassTracker <<  :Submission_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:xref, "SUBN", :submission_ref] ]
    @sub_level =  [ #level + 1
                    [:xref, "SUBM", :submitter_ref],
                    [:print, "FAMF",    :lds_family_file ],
                    [:print, "TEMP",    :lds_temple_code ],
                    [:print, "ANCE",    :generations_of_ancestor ],
                    [:print, "DESC",    :generations_of_descendant ],
                    [:print, "ORDI",    :process_ordinates ],
                    [:print, "RIN",    :automated_record_id ],
                    [:walk, nil,    :note_citation_record ],
                  ]
  end   
end

