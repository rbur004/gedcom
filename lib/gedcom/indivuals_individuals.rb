require 'gedcom_base.rb'

class Individuals_individuals < GedComBase
  attr_accessor :relationship_type, :associate_ref, :associated_record_tag, :relationship_description
  attr_accessor :source_citation_record, :note_citation_record

  ClassTracker <<  :Individuals_individuals
  
  def to_gedcom(level=0)
    @this_level = [ [:xref, @relationship_type[0], :associate_ref ] ]
    @sub_level =  [ #level 1
                    [:print, "TYPE",    :associated_record_tag ],
                    [:print, "RELA",    :relationship_description ],
                    [:walk, nil,    :source_citation_record ],
                    [:walk, nil,    :note_citation_record ],
                  ]
    super(level)
  end
end

