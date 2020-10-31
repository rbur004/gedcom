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
#
# GEDCOM 5.5.1 Draft adds (at same level as ADDR)
#  I have not included these in the Address_record, but include them in the parent
#  records that include ADDRESS_STRUCTURE. This is functionally equivalent, as they are not
#  sub-records of ADDR, but at the same level.
#
#  n EMAIL <ADDRESS_EMAIL>               {0:3}
#  n FAX <ADDRESS_FAX>                   {0:3}
#  n WWW <ADDRESS_WEB_PAGE>              {0:3}
#
#==ADDRESS_EMAIL:= {SIZE=5:120}
#  An electronic address that can be used for contact such as an email address.
#
#== ADDRESS_FAX:= {SIZE=5:60}
#  A FAX telephone number appropriate for sending data facsimiles.
#
#==ADDRESS_WEB_PAGE:= {SIZE=5:120}
#  The world wide web page address.
#
class Repository_record < GEDCOMBase
  attr_accessor :repository_ref, :repository_name, :phonenumber, :address_record,  :note_citation_record 
  attr_accessor :refn_record, :automated_record_id, :change_date_record
  attr_accessor :address_email, :address_fax, :address_web_page #GEDCOM 5.5.1 Draft

  ClassTracker <<  :Repository_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:xref, "REPO", :repository_ref]]
    @sub_level =  [#level 1
                    [:print, "NAME",    :repository_name ],
                    [:print, "PHON",    :phonenumber ],
                    [:print, "EMAIL", :address_email],
                    [:print, "WWW", :address_web_page],
                    [:print, "FAX", :address_fax],
                    [:walk, nil,    :address_record ],
                    [:walk, nil,    :note_citation_record ],
                    [:walk, nil,     :refn_record ],
                    [:print, "RIN",    :automated_record_id ],
                    [:walk, nil,    :change_date_record ],
                  ]
  end 
end

