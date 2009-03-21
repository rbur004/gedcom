require 'gedcom_base.rb'

class Text_record < GedComBase
  attr_accessor :text
  
  ClassTracker <<  :Text_record
  
  def initialize(*a)
    super(*a)
    @this_level = [ [:cont, "TEXT", :text] ]
    @sub_level =  [ #level + 1
                  ]
  end 
end

