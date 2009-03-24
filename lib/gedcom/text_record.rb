require 'gedcom_base.rb'

#Internal representation of the GEDCOM TEXT record type.
class Text_record < GedComBase
  attr_accessor :text
  
  ClassTracker <<  :Text_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:cont, "TEXT", :text] ]
    @sub_level =  [ #level + 1
                  ]
  end 
end

