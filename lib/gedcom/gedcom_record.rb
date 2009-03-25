require 'gedcom_base.rb'

#Internal representation of the GEDCOM GEDC record type in a HEAD record.
#
#=HEADER:=
#  n HEAD                                          {1:1}
#    ...
#   +1 GEDC                                        {1:1}
#     +2 VERS <VERSION_NUMBER>                     {1:1}
#     +2 FORM <GEDCOM_FORM>                        {1:1}
#   ...
#
#==VERSION_NUMBER:=
#  An identifier that represents the version level
#  changed by the creators of the product.
#
#==GEDCOM_FORM:= {Size=14:20}
#  [ LINEAGE-LINKED ]
#  The GEDCOM form used to construct this transmission. There maybe other forms used such as
#  CommSoft's "EVENT_LINEAGE_LINKED" but these specifications define only the LINEAGELINKED
#  Form. Systems will use this value to specify GEDCOM compatible with these
#  specifications.
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
class Gedcom_record < GEDCOMBase
  attr_accessor :version, :encoding_format
  attr_accessor :note_citation_record

  ClassTracker <<  :Gedcom_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:nodata, "GEDC", nil] ]
    @sub_level =  [ #level + 1
                    [ :print, "VERS", :version],
                    [ :print, "FORM", :encoding_format],
                    [ :walk, nil,  :note_citation_record],
                  ]
  end  
end
