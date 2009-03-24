require 'gedcom_base.rb'

class Change_date_record < GedComBase
  attr_accessor :date_record, :note_citation_record

  ClassTracker <<  :Change_date_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [ :nodata, "CHAN", nil] ]
    @sub_level =  [ #level + 1
                    [:walk, nil, :date_record],
                    [:walk, nil, :note_citation_record]
                  ]
  end
end
