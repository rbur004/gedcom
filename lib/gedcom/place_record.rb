require 'gedcom_base.rb'

#Internal representation of the GEDCOM PLAC record type
#
#The attributes are all arrays. 
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in the PLAC records.
class Place_record < GedComBase
  attr_accessor :place_value, :place_hierachy, :source_citation_record, :note_citation_record

  ClassTracker <<  :Place_record
  
  def to_gedcom(level=0)
    if @place_value != nil
      @this_level = [  [:print, "PLAC", :place_value] ]
      @sub_level =  [ #level + 1
                      [:print, "FORM", :place_hierachy],
                      [:walk, nil,    :source_citation_record],
                      [:walk, nil,    :note_citation_record],
                    ]
    else
      @this_level = [  [:nodata, "PLAC", nil] ]
      @sub_level =  [ #level + 1
                      [:print, "FORM", :place_hierachy],
                      [:walk, nil,    :source_citation_record],
                      [:walk, nil,    :note_citation_record],
                    ]
    end
    super(level)
  end
end
