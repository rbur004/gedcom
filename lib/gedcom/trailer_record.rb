require 'gedcom_base.rb'

class Trailer_record < GedComBase
  
  ClassTracker <<  :Trailer_record
  
  def initialize(*a)
    super(*a)
    @this_level = [ [:nodata, "TRLR", nil] ]
    @sub_level =  [ #level + 1
                  ]
  end 
end

