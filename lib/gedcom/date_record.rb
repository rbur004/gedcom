require 'gedcom_base.rb'

class Date_record < GedComBase
  attr_accessor :date, :time, :source_citation_record, :note_citation_record

  ClassTracker <<  :Date_record
  
  def initialize(*a)
    super(*a)
    @this_level = [ [ :date, "DATE", :date ] ]
    @sub_level =  [ #level + 1
                    [ :time, "TIME", :time],
                    [ :walk, nil, :source_citation_record],
                    [ :walk,  nil, :note_citation_record],
                  ]
  end
end
