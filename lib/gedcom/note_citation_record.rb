require 'gedcom_base.rb'

class Note_citation_record < GedComBase
  attr_accessor :note_ref, :note_record, :source_citation_record

  ClassTracker <<  :Note_citation_record
  
  def to_gedcom(level=0)
    if @note_ref
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

