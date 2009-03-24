require 'gedcom_base.rb'

#Internal representation of a reference to a GEDCOM level 0 NOTE record type
#NOTE types can be inline, references to Level 0 NOTEs, or used to store user defined tags. 
#All NOTES are stored in the Note_record closs and referenced through this class.
#
#The attributes are all arrays. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in the NOTE records.
class Note_citation_record < GedComBase
  attr_accessor :note_ref, :note_record, :source_citation_record

  ClassTracker <<  :Note_citation_record
  
  def to_gedcom(level=0)
    if @note_ref != nil
      @this_level = [ [:xref, "NOTE", :note_ref] ]
      @sub_level =  [#level 1
                      [:walk, nil,    :source_citation_record ],
                      [:walk, nil, :note_record] 
                    ]
    else
      @this_level = [ [:walk, nil, :note_record] ]
      @sub_level =  [#level 1
                    ]
    end
    super(level)
  end
end

