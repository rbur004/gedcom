require 'gedcom_base.rb'

#The Corparte_record is part of the HEAD records SOUR record.
#
#=HEADER:=
#  0 HEAD                                         {1:1}
#    1  SOUR <APPROVED_SYSTEM_ID>                 {1:1}
#      ...
#      n CORP <NAME_OF_BUSINESS>                  {0:1}
#        +1 <<ADDRESS_STRUCTURE>>                 {0:1}
#        +1 PHON <PHONE_NUMBER>                   {0:3} (defined in the Address structure)
#
#==NAME_OF_BUSINESS:=                             {Size=1:90}
#  Name of the business, corporation, or person that produced or commissioned the product.
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
class Corporate_record < GEDCOMBase
  attr_accessor :company_name, :phonenumber, :address_record
  attr_accessor :note_citation_record

  ClassTracker <<  :Corporate_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:print, "CORP", :company_name] ]
    @sub_level =  [  #level + 1
                    [:print, "PHON", :phonenumber],
                    [:walk,  nil,    :address_record],
                    [:walk, nil,    :note_citation_record],
                  ]
  end
end
