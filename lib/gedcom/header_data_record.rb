require 'gedcom_base.rb'

#Internal representation of the GEDCOM DATA in a SOUR record in a level 0 HEAD record type
#This is not the same record type as DATA tags in level 0 SOUR record.
#
#The attributes are all arrays. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in the REFN records.
class Header_data_record < GedComBase
  attr_accessor :data_source, :date, :copyright
  attr_accessor :note_citation_record

  ClassTracker <<  :Header_data_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:print, "DATA", :data_source] ]
    @sub_level =  [ #level + 1
                    [:print, "DATE", :date],
                    [:print, "COPR", :copyright],
                    [:walk, nil,    :note_citation_record],
                  ]
  end  
end
