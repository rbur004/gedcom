require 'gedcom_base.rb'

class Event_age_record < GedComBase
  attr_accessor :relation, :age
  attr_accessor :note_citation_record

  ClassTracker <<  :Event_age_record
  
  def to_gedcom(level=0)
    @this_level = [ [:nodata, @relation[0], nil] ] #dynamic, so need to define after initialize method.
    @sub_level =  [ #level + 1
                    [:print, "AGE",  :age],
                    [:walk, nil,  :note_citation_record]
                  ]
    super(level)
  end
end

