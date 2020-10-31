require 'gedcom_base.rb'

#An inline Multimedia_record uses BLOB records to hold the data.
#This is unusual in practice, as it bloats the GEDCOM file.
#Normal practice is to reference a file or URL.
#
#=BLOB {BINARY_OBJECT}:=
#  A grouping of data used as input to a multimedia system that processes binary data to represent
#  images, sound, and video.
#
#=MULTIMEDIA_RECORD:=
#  0 @XREF:OBJE@ OBJE                     {0:M}
#    ...
#    n BLOB                               {1:1}
#      +1 CONT <ENCODED_MULTIMEDIA_LINE>  {1:M}
#    ...
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
class Encoded_line_record < GEDCOMBase
  attr_accessor :encoded_line
  
  ClassTracker <<  :Encoded_line_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:nodata, "BLOB",    nil ] ]
    @sub_level =  [ [:blob, "CONT",    :encoded_line ] ]
  end  
end

