require 'gedcom_base.rb'

#Internal representation of the GEDCOM DATA in a SOUR record in a level 0 HEAD record type
#This is not the same record type as DATA tags in level 0 SOUR record.
#
#=HEADER:=
#  n HEAD                                             {1:1}
#    +1 SOUR <APPROVED_SYSTEM_ID>                     {1:1}
#      ...
#      +2 DATA <NAME_OF_SOURCE_DATA>                  {0:1}
#        +3 DATE <PUBLICATION_DATE>                   {0:1}
#        +3 COPR <COPYRIGHT_SOURCE_DATA>              {0:1}
#      ...
#   ...
#==NAME_OF_SOURCE_DATA:= {Size=1:90}
#  The name of the electronic data source that was used to obtain the data in this transmission. For
#  example, the data may have been obtained from a CD-ROM disc that was named "U.S. 1880
#  CENSUS CD-ROM vol. 13."
#
#==PUBLICATION_DATE:= {Size=10:11}
#  <DATE_EXACT>:= <DAY> <MONTH> <YEAR_GREG> {Size=10:11}
#  The date this source was published or created.
#
#==COPYRIGHT_SOURCE_DATA:= {Size=1:90}
#  A copyright statement required by the owner of data from which this information was down- loaded.
#  For example, when a GEDCOM down-load is requested from the Ancestral File, this would be the
#  copyright statement to indicate that the data came from a copyrighted source.
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
class Header_data_record < GEDCOMBase
  attr_accessor :data_source, :date, :copyright_record
  attr_accessor :note_citation_record

  ClassTracker <<  :Header_data_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:print, "DATA", :data_source] ]
    @sub_level =  [ #level + 1
                    [:print, "DATE", :date],
                    #[:print, "COPR", :copyright], #GEDCOM5.5
                    [:walk, nil, :copyright_record], #GEDCOM5.5.1 "COPR"
                    [:walk, nil,    :note_citation_record],
                  ]
  end  
  
  def copyright
    copyright_record != nil ? copyright_record.first.copyright : nil
  end
      
end
