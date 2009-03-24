require 'gedcom_base.rb'

#Internal representation of the GEDCOM GEDC record type in a HEAD record.
#
#The attributes are all arrays. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in the REFN records.
class Gedcom_record < GedComBase
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
