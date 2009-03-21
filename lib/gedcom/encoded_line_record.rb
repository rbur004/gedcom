require 'gedcom_base.rb'

class Encoded_line_record < GedComBase
  attr_accessor :encoded_line
  
  ClassTracker <<  :Encoded_line_record
  
  def initialize(*a)
    super(*a)
    @this_level = [ [:nodata, "BLOB",    nil ] ]
    @sub_level =  [ [:blob, "CONT",    :encoded_line ] ]
  end  
end

