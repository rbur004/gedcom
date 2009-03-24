require 'gedcom_base.rb'

#Internal representation of the GEDCOM NOTE record type
#Both inline and level 0 NOTEs are stored here and both are referenced through the Note_citation_record class. 
#NOTES are also used to store user defined tags, so can appear in places the GEDCOM standard doesn't specify NOTEs.
#
#The attributes are all arrays. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in the NOTE records.
class Note_record < GedComBase
  attr_accessor :note_ref, :note, :source_citation_record
  attr_accessor :restriction, :refn_record, :automated_record_id, :change_date_record
  attr_accessor :note_citation_record
  
  ClassTracker <<  :Note_record
  
  def to_gedcom(level=0)
    if @note_ref != nil
      @this_level = [ [:xref, "NOTE", :note_ref] ]
      @sub_level =  [ #level + 1
                      [:conc, "CONC", :note],
                      [:print, "RESN", :restriction ],
                      [:walk, nil,    :source_citation_record ],
                      [:walk, nil,    :note_citation_record ],
                      [:walk, nil, :refn_record ],
                      [:print, "RIN",  :automated_record_id ],
                      [:walk, nil,    :change_date_record],
                    ] 
    else
      @this_level = [ [:cont, "NOTE", :note] ]
      @sub_level =  [ #level + 1
                      [:print, "RESN", :restriction ],
                      [:walk, nil,    :source_citation_record ],
                      [:walk, nil,    :note_citation_record ],
                      [:walk, nil, :refn_record ],
                      [:print, "RIN",  :automated_record_id ],
                      [:walk, nil,    :change_date_record],
                    ]
    end
    super(level)
  end
end

