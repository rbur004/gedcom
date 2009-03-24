require 'gedcom_base.rb'

class Date_record < GedComBase
  attr_accessor :date_value, :time_value, :source_citation_record, :note_citation_record

  ClassTracker <<  :Date_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [ :date, "DATE", :date_value ] ]
    @sub_level =  [ #level + 1
                    [ :time, "TIME", :time_value],
                    [ :walk, nil, :source_citation_record],
                    [ :walk,  nil, :note_citation_record]
                  ]
  end
end
