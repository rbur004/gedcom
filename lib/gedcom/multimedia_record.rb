require 'gedcom_base.rb'

#Internal representation of the GEDCOM OBJE record type
#GEDCOM has both inline OBJE records and references to level 0 OBJE records.
#both are stored here and referenced through a Multimedia_citation_record class.
#
#=MULTIMEDIA_RECORD:=
#  0 @XREF:OBJE@ OBJE                     {0:M}
#    +1 FORM <MULTIMEDIA_FORMAT>          {1:1}
#    +1 TITL <DESCRIPTIVE_TITLE>          {0:1}
#    +1 <<NOTE_STRUCTURE>>                {0:M}
#    +1 BLOB                              {1:1}
#      +2 CONT <ENCODED_MULTIMEDIA_LINE>  {1:M}
#    +1 OBJE @<XREF:OBJE>@                {0:1} (chain to continued object)
#    +1 REFN <USER_REFERENCE_NUMBER>      {0:M}
#      +2 TYPE <USER_REFERENCE_TYPE>      {0:1}
#    +1 RIN <AUTOMATED_RECORD_ID>         {0:1}
#    +1 <<CHANGE_DATE>>                   {0:1}
#
#  Large whole multimedia objects embedded in a GEDCOM file would break some systems. For this
#  purpose, large multimedia files should be divided into smaller multimedia records by using the
#  subordinate OBJE tag to chain to the next <MULTIMEDIA_RECORD> fragment. This will allow
#  GEDCOM records to be maintained below the 32K limit for use in systems with limited resources.
#
#  n OBJE                                 {1:1} is a reference to an external file, rather than inline.
#    +1 FORM <MULTIMEDIA_FORMAT>          {1:1}
#    +1 TITL <DESCRIPTIVE_TITLE>          {0:1}
#    +1 FILE <MULTIMEDIA_FILE_REFERENCE>  {1:1}
#    +1 <<NOTE_STRUCTURE>>                {0:M}
#
#  This second method allows the GEDCOM context to be connected to an external multimedia file.
#  GEDCOM defines this in the MULTIMEDIA_LINK definition, but I have put it into the Multimedia_record.
#  as the attributes are the same, except BLOB becomes FILE. A Multimedia_citation_record is also created
#  to make all references to Multimedia records consistent.
#
#  This process is only managed by GEDCOM in the sense that the appropriate file name is included in
#  the GEDCOM file in context, but the maintenance and transfer of the multimedia files are external to
#  GEDCOM. The parser can just treat this as a comment and doesn't check for the file being present.
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
class Multimedia_record < GEDCOMBase
  attr_accessor :multimedia_ref, :format, :title, :encoded_line_record, :next_multimedia_ref, :filename
  attr_accessor :refn_record, :automated_record_id, :note_citation_record, :change_date_record

  ClassTracker <<  :Multimedia_record
  
  def to_gedcom(level=0)
    
    if @multimedia_ref != nil 
      @this_level =  [ [:xref, "OBJE", :multimedia_ref]]
    else
      @this_level =  [ [:nodata, "OBJE", nil] ]
    end

    @sub_level =  [#level 1
                    [:print, "TITL",    :title ],
                    [:print, "FORM",    :format ],
                    [:walk, nil,    :encoded_line_record ],
                    [:xref, nil,     :next_multimedia_ref ],
                    [:print, "FILE",    :filename ],
                    [:walk, nil,    :note_citation_record ],
                    [:walk, nil,     :refn_record ],
                    [:print, "RIN",    :automated_record_id ],
                    [:walk, nil,    :change_date_record ],
                  ]
    
    super(level)
  end
end
