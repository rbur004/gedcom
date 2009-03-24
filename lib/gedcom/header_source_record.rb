require 'gedcom_base.rb'

#Internal representation of the GEDCOM SOUR record in a level 0 HEAD record.
#These SOUR records are not the same as level 0 SOUR records.
#
#The attributes are all arrays. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in the REFN records.
class Header_source_record < GedComBase
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
