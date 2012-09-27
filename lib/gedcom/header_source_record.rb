require 'gedcom_base.rb'

#Internal representation of the GEDCOM SOUR record in a level 0 HEAD record.
#These SOUR records are not the same as level 0 SOUR records.
#
#=HEADER:=
#  0 HEAD                                 {1:1}
#    1 SOUR <APPROVED_SYSTEM_ID>          {1:1}
#      +1 VERS <VERSION_NUMBER>           {0:1}
#      +1 NAME <NAME_OF_PRODUCT>          {0:1}
#      +1 CORP <NAME_OF_BUSINESS>         {0:1}
#        +2 <<ADDRESS_STRUCTURE>>         {0:1}
#      +1 DATA <NAME_OF_SOURCE_DATA>      {0:1}
#        +2 DATE <PUBLICATION_DATE>       {0:1}
#        +2 COPR <COPYRIGHT_SOURCE_DATA>  {0:1}
#    ...
#
#  The SOURce system name identifies which system sent the data.
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
class Header_source_record < GEDCOMBase
  attr_accessor :approved_system_id, :version, :name, :corporate_record, :header_data_record
  attr_accessor :note_citation_record
  
  ClassTracker <<  :Header_source_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:print, "SOUR", :approved_system_id] ]
    @sub_level =  [ #level + 1
                    [:print, "VERS", :version],
                    [:print, "NAME", :name],
                    [:walk, nil, :corporate_record],
                    [:walk, nil, :header_data_record],
                    [:walk, nil, :note_citation_record],
                  ]
  end  
end
