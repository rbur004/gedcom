require 'gedcom_base.rb'

#Character_set_record is part of the HEAD record, and names the
#the character set used in this transmission.
#
#=HEADER:=
#  0 HEAD                                         {1:1}
#   ...
#   1 CHAR <CHARACTER_SET>                        {1:1}
#     +1 VERS <VERSION_NUMBER>                    {0:1}
#   ...
#
#==CHARACTER_SET:= {Size=1:8}
#  ANSEL | UNICODE | ASCII
#
#  A code value that represents the character set to be used to interpret this data. The default character
#  set is ANSEL, which includes ASCII as a subset.
#
#  Note:: The IBMPC character set is not allowed. This character set cannot be interpreted properly
#  without knowing which code page the sender was using.
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
class Character_set_record < GEDCOMBase
  attr_accessor :char_set_id, :version
  attr_accessor :note_citation_record

  ClassTracker <<  :Character_set_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:print, "CHAR", :char_set_id] ]
    @sub_level =  [ #level + 1
                    [:print, "VERS", :version],
                    [:walk, nil,    :note_citation_record]
                  ]
  end
end
