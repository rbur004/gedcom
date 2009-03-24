require 'gedcom_base.rb'

#Internal representation of the GEDCOM TRLR record that terminates transmissions.
#The Trailer_record class is just a place marker to ensure we have encountered a termination record in the GEDCOM file.
class Trailer_record < GedComBase
  
  ClassTracker <<  :Trailer_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:nodata, "TRLR", nil] ]
    @sub_level =  [ #level + 1
                  ]
  end 
end

