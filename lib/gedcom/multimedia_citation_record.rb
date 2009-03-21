require 'gedcom_base.rb'

class Multimedia_citation_record < GedComBase
  attr_accessor :multimedia_ref, :multimedia_record
  attr_accessor :note_citation_record

  ClassTracker <<  :Multimedia_citation_record
  
  def to_gedcom(level=0)
    if @multimedia_ref
      @this_level = [ [:xref, "OBJE", :multimedia_ref] ]
      @sub_level =  [#level 1
                      [:walk, nil,    :note_citation_record ],
                    ]
    else
      @this_level = [ [:walk, nil, :multimedia_record] ]
      @sub_level =  [#level 1
                    ]
    end
    super(level)
  end
end

