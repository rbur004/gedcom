require 'gedcom_base.rb'

#Internal representation of the GEDCOM DATA record type, a record type under the GEDCOM SUBN record type
#
#The attributes are all arrays. 
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in the SUBN-DATA records.
class Source_scope_record < GedComBase
  attr_accessor :events_list_record, :agency, :note_citation_record

  ClassTracker <<  :Source_scope_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [[:nodata, "DATA", nil]]
    @sub_level =  [ #level + 1
                    [:walk, nil, :events_list_record],
                    [:print, "AGNC",:agency],
                    [:walk, nil, :note_citation_record],
                  ]
  end 
end

