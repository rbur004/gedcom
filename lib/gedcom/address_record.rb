require 'gedcom_base.rb'

#Address_record a sub-record of HEAD, REPO, SUBM and all types of Event records.
#
#ADDRESS_STRUCTURE:=
#  n ADDR <ADDRESS_LINE>              {0:1}
#    +1 CONT <ADDRESS_LINE>           {0:M}
#    +1 ADR1 <ADDRESS_LINE1>          {0:1}
#    +1 ADR2 <ADDRESS_LINE2>          {0:1}
#    +1 CITY <ADDRESS_CITY>           {0:1}
#    +1 STAE <ADDRESS_STATE>          {0:1}
#    +1 POST <ADDRESS_POSTAL_CODE>    {0:1}
#    +1 CTRY <ADDRESS_COUNTRY>        {0:1}
#
#  I have not included the Phone number from Address_record, and include it in the parent
#  records that include ADDRESS_STRUCTURE. This is functionally equivalent, as PHON is not
#  a sub-record of ADDR, but at the same level.
#
#  n PHON <PHONE_NUMBER>              {0:3}
#
#==ADDRESS_CITY:= {Size=1:60}
#  The name of the city used in the address. Isolated for sorting or indexing.
#
#==ADDRESS_COUNTRY:= {Size=1:60}
#  The name of the country that pertains to the associated address. Isolated by some systems for sorting
#  or indexing. Used in most cases to facilitate automatic sorting of mail.
#
#==ADDRESS_LINE:= {Size=1:60}
#  Address information that, when combined with NAME and CONTinuation lines, meets requirements
#  for sending communications through the mail.
#
#==ADDRESS_LINE1:= {Size=1:60}
#  The first line of the address used for indexing. This corresponds to the ADDRESS_LINE value of the
#  ADDR line in the address structure.
#
#==ADDRESS_LINE2:= {Size=1:60}
#  The second line of the address used for indexing. This corresponds to the ADDRESS_LINE value of
#  the first CONT line subordinate to the ADDR tag in the address structure.
#
#==ADDRESS_POSTAL_CODE:= {Size=1:10}
#  The ZIP or postal code used by the various localities in handling of mail. Isolated for sorting or
#  indexing.
#
#==ADDRESS_STATE:= {Size=1:60}
#  The name of the state used in the address. Isolated for sorting or indexing.
#
#  The address structure should be formed as it would appear on a mailing label using the ADDR and
#  ADDR.CONT lines. These lines are required if an ADDRess is present. Optionally, additional
#  structure is provided for systems that have structured their addresses for indexing and sorting.
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
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

class Address_record < GEDCOMBase
  attr_accessor :address,  :address_line1, :address_line2, :city, :state, :post_code, :country, :address_type
  attr_accessor :note_citation_record
  
  ClassTracker <<  :Address_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:cont, "ADDR", :address] ]
    @sub_level =  [ #level + 1
                    [:print, "ADR1", :address_line1],
                    [:print, "ADR2", :address_line2],
                    [:print, "CITY", :city],
                    [:print, "STAE", :state],
                    [:print, "POST", :post_code],
                    [:print, "CTRY", :country],
                    [:print, "TYPE", :address_type], #non standard.
                    [:walk,  nil,   :note_citation_record],
                  ]
  end
                
end
