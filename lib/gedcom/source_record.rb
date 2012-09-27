require 'gedcom_base.rb'

#Internal representation of the GEDCOM SOUR record type
#Both inline and references to Level 0 Source_records are referenced via the Source_citation_record class.
#
#SOURCE_RECORD:=
#  0 @<XREF:SOUR>@ SOUR                           {0:M}
#    +1 DATA {0:1}
#      +2 EVEN <EVENTS_RECORDED>                  {0:M}
#        +3 DATE <DATE_PERIOD>                    {0:1}
#        +3 PLAC <SOURCE_JURISDICTION_PLACE>      {0:1}
#      +2 AGNC <RESPONSIBLE_AGENCY>               {0:1}
#      +2 <<NOTE_STRUCTURE>>                      {0:M}
#    +1 AUTH <SOURCE_ORIGINATOR>                  {0:1}
#      +2 [CONT|CONC] <SOURCE_ORIGINATOR>         {0:M}
#    +1 TITL <SOURCE_DESCRIPTIVE_TITLE>           {0:1}
#      +2 [CONT|CONC] <SOURCE_DESCRIPTIVE_TITLE>  {0:M}
#    +1 ABBR <SOURCE_FILED_BY_ENTRY>              {0:1}
#    +1 PUBL <SOURCE_PUBLICATION_FACTS>           {0:1}
#      +2 [CONT|CONC] <SOURCE_PUBLICATION_FACTS>  {0:M}
#    +1 TEXT <TEXT_FROM_SOURCE>                   {0:1}
#      +2 [CONT|CONC] <TEXT_FROM_SOURCE>          {0:M}
#    +1 <<SOURCE_REPOSITORY_CITATION>>            {0:1}
#    +1 <<MULTIMEDIA_LINK>>                       {0:M}
#    +1 <<NOTE_STRUCTURE>>                        {0:M}
#    +1 REFN <USER_REFERENCE_NUMBER>              {0:M}
#      +2 TYPE <USER_REFERENCE_TYPE>              {0:1}
#    +1 RIN <AUTOMATED_RECORD_ID>                 {0:1}
#    +1 <<CHANGE_DATE>>                           {0:1}
#
#  Source records are used to provide a bibliographic description of the source cited. (See the
#  <<SOURCE_CITATION>> structure, page 32, which contains the pointer to this source record.)#
#
#Systems not using level 0 source records, inline SOUR records combining SOURCE_RECORDS with SOURCE_CITATIONs.
#We create both a Source_record object and a Source_citation_record object, as if the transmission had used both.
#  n SOUR <SOURCE_DESCRIPTION>                    {1:1}
#    +1 [ CONC | CONT ] <SOURCE_DESCRIPTION>      {0:M}
#    +1 TEXT <TEXT_FROM_SOURCE>                   {0:M}
#    +2 [CONC | CONT ] <TEXT_FROM_SOURCE>         {0:M}
#    +1 <<NOTE_STRUCTURE>>                        {0:M}
#
#The attributes are all arrays representing the +1 level of the SOURCE_RECORD. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in the SOUR records.
#
class Source_record < GEDCOMBase
  attr_accessor :source_ref, :short_title, :title, :author,  :source_scope_record,  :publication_details
  attr_accessor :repository_citation_record, :text_record, :note_citation_record, :multimedia_citation_record
  attr_accessor :refn_record, :automated_record_id, :change_date_record

  ClassTracker <<  :Source_record
  
  #to_gedcom sets up the state engine arrays @this_level and @sub_level, which drive the parent class to_gedcom method generating GEDCOM output.
  #There are two types of SOUR record, inline and reference, so this is done dynamically in to_gedcom rather than the initialize method.
  #Probably should be two classes, rather than this conditional.
  def to_gedcom(level=0)
    if @source_ref != nil
      @this_level = [ [:xref, "SOUR", :source_ref] ]
      @sub_level =  [ #level + 1
                      [:print, "ABBR", :short_title],
                      [:cont, "TITL", :title],
                      [:cont, "AUTH", :author],
                      [:cont, "PUBL", :publication_details],
                      [:walk, nil,  :repository_citation_record],
                      [:walk, nil, :text_record],
                      [:walk, nil, :multimedia_citation_record],
                      [:walk, nil, :source_scope_record],
                      [:walk, nil, :note_citation_record],
                      [:walk, nil, :refn_record],
                      [:print, "RIN", :automated_record_id],
                      [:walk,  nil, :change_date_record],
                    ]
    else
      @this_level = [ [:cont, "SOUR", :title] ]
      @sub_level =  [ #level + 1
                      [:walk, nil, :text_record],
                      [:walk, nil, :note_citation_record] ,
                    ] 
    end
    super(level)
  end
end

