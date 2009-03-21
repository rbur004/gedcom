require 'gedcom_base.rb'

class Place_record < GedComBase
  attr_accessor :place_value, :place_hierachy, :source_citation_record, :note_citation_record

  ClassTracker <<  :Place_record
  
  def to_gedcom(level=0)
    if @place_value
      @this_level = [  [:print, "PLAC", :place_value] ]
                    [ #level + 1
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
