require 'gedcom_base.rb'

#Internal representation of a reference to the GEDCOM REPO citation record type
#The actual REPO record is stored in the Repository_record class.
#
#=SOURCE_REPOSITORY_CITATION:=
#
#  n REPO @XREF:REPO@               {1:1}
#    +1 <<NOTE_STRUCTURE>>          {0:M}
#    +1 CALN <SOURCE_CALL_NUMBER>   {0:M}
#      +2 MEDI <SOURCE_MEDIA_TYPE>  {0:1}
#
#  This structure is used within a source record to point to a name and address record of the holder of the
#  source document. Formal and informal repository name and addresses are stored in the
#  REPOSITORY_RECORD. Informal repositories include owner's of an unpublished work or of a rare
#  published source, or a keeper of personal collections. An example would be the owner of a family Bible
#  containing unpublished family genealogical entries. More formal repositories, such as the Family History
#  Library, should show a call number of the source at that repository. The call number of that source
#  should be recorded using a subordinate CALN tag. Systems which do not structure a repository name
#  and address interface should store the information about where the source record is stored in the
#  <<NOTE_STRUCTURE>> of this structure.
#
#The attributes are all arrays for the +1 level tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in the REPO records.
#
class Repository_citation_record < GEDCOMBase
  attr_accessor :repository_ref, :note_citation_record, :repository_caln

  ClassTracker <<  :Repository_citation_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level =  [ [:xref, "REPO", :repository_ref] ] 
    @sub_level =  [ #level + 1
                    [:walk, nil, :repository_caln],
                    [:walk, nil, :note_citation_record],
                  ]
  end 
end

