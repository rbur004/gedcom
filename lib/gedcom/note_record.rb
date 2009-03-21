require 'gedcom_base.rb'

class Note_record < GedComBase
  attr_accessor :note_ref, :note, :source_citation_record
  attr_accessor :restriction, :refn_record, :automated_record_id, :change_date_record
  attr_accessor :note_citation_record
  
  ClassTracker <<  :Note_record
  
  def to_gedcom(level=0)
    if @note_ref
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

