require 'gedcom_base.rb'

#Internal representation of the GEDCOM REPO record type
#This class is referenced through the Repository_citation_record class.
#
#=REPOSITORY_RECORD:=
#  0 @<XREF:REPO>@ REPO               {0:M}
#    +1 NAME <NAME_OF_REPOSITORY>     {0:1}
#    +1 <<ADDRESS_STRUCTURE>>         {0:1}
#    +1 <<NOTE_STRUCTURE>>            {0:M}
#    +1 REFN <USER_REFERENCE_NUMBER>  {0:M}
#      +2 TYPE <USER_REFERENCE_TYPE>  {0:1}
#    +1 RIN <AUTOMATED_RECORD_ID>     {0:1}
#    +1 <<CHANGE_DATE>>               {0:1}
#
#The attributes are all arrays for the +1 level tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in the REPO records.
class Repository_record < GEDCOMBase
  attr_accessor :repository_ref, :repository_name, :phonenumber, :address_record,  :note_citation_record 
  attr_accessor :refn_record, :automated_record_id, :change_date_record

  ClassTracker <<  :Repository_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:xref, "REPO", :repository_ref]]
    @sub_level =  [#level 1
                    [:print, "NAME",    :repository_name ],
                    [:print, "PHON",    :phonenumber ],
                    [:walk, nil,    :address_record ],
                    [:walk, nil,    :note_citation_record ],
                    [:walk, nil,     :refn_record ],
                    [:print, "RIN",    :automated_record_id ],
                    [:walk, nil,    :change_date_record ],
                  ]
  end 
end

