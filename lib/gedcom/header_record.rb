require 'gedcom_base.rb'

#Internal representation of the GEDCOM level 0 HEAD record type
#
#=HEADER:=
#  n HEAD                                          {1:1}
#    +1 SOUR <APPROVED_SYSTEM_ID>                  {1:1}
#      +2 VERS <VERSION_NUMBER>                    {0:1}
#      +2 NAME <NAME_OF_PRODUCT>                   {0:1}
#      +2 CORP <NAME_OF_BUSINESS>                  {0:1}
#        +3 <<ADDRESS_STRUCTURE>>                  {0:1}
#      +2 DATA <NAME_OF_SOURCE_DATA>               {0:1}
#        +3 DATE <PUBLICATION_DATE>                {0:1}
#        +3 COPR <COPYRIGHT_SOURCE_DATA>           {0:1}
#   +1 DEST <RECEIVING_SYSTEM_NAME>                {0:1} (See NOTE below)
#   +1 DATE <TRANSMISSION_DATE>                    {0:1}
#     +2 TIME <TIME_VALUE>                         {0:1}
#   +1 SUBM @XREF:SUBM@                            {1:1}
#   +1 SUBN @XREF:SUBN@                            {0:1}
#   +1 FILE <FILE_NAME>                            {0:1}
#   +1 COPR <COPYRIGHT_GEDCOM_FILE>                {0:1}
#   +1 GEDC                                        {1:1}
#     +2 VERS <VERSION_NUMBER>                     {1:1}
#     +2 FORM <GEDCOM_FORM>                        {1:1}
#   +1 CHAR <CHARACTER_SET>                        {1:1}
#     +2 VERS <VERSION_NUMBER>                     {0:1}
#   +1 LANG <LANGUAGE_OF_TEXT>                     {0:1}
#   +1 PLAC                                        {0:1}
#     +2 FORM <PLACE_HIERARCHY>                    {1:1}
#   +1 NOTE <GEDCOM_CONTENT_DESCRIPTION>           {0:1}
#     +2 [CONT|CONC] <GEDCOM_CONTENT_DESCRIPTION>  {0:M}
#  NOTE::
#    Submissions to the Family History Department for Ancestral File submission or for clearing temple ordinances must use a
#    DESTination of ANSTFILE or TempleReady.
#
#  The header structure provides information about the entire transmission. The SOURce system name
#  identifies which system sent the data. The DESTination system name identifies the intended receiving
#  system.
#
#  Additional GEDCOM standards will be produced in the future to reflect GEDCOM expansion and
#  maturity. This requires the reading program to make sure it can read the GEDC.VERS and the
#  GEDC.FORM values to insure proper readability. The CHAR tag is required. All character codes
#  greater than 0x7F must be converted to ANSEL.
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
class Header_record < GEDCOMBase
  attr_accessor :header_source_record, :destination, :date_record, :submitter_ref, :submission_ref
  attr_accessor :file_name, :copyright, :gedcom_record, :character_set_record, :language_id
  attr_accessor :place_record, :note_citation_record
  
  ClassTracker <<  :Header_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:nodata, "HEAD", nil] ]
    @sub_level =  [ #level + 1
                    [:walk, nil,:header_source_record],
                    [:print, "DEST", :destination],
                    [:walk, nil, :date_record], 
                    [:xref, "SUBM", :submitter_ref], 
                    [:xref, "SUBN", :submission_ref],
                    [:print, "FILE", :file_name], 
                    [:print, "COPR", :copyright], 
                    [:walk, nil, :gedcom_record],  
                    [:walk, nil, :character_set_record], 
                    [:print, "LANG", :language_id], 
                    [:walk, nil, :place_record], 
                    [:walk, nil, :note_citation_record],
                  ]
  end 
  
end
