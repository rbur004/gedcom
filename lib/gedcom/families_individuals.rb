require 'gedcom_base.rb'

class Families_individuals < GedComBase
  attr_accessor :relationship_type, :parents_family_ref, :family_ref, :pedigree
  attr_accessor :source_citation_record, :note_citation_record

  ClassTracker <<  :Families_individuals
  
  def to_gedcom(level=0)
    @this_level = [ [:xref, @relationship_type[0], :family_ref],
                    [:xref, @relationship_type[0], :parents_family_ref] 
                  ]
    @sub_level =  [ #level 1
                    [:print, "PEDI",    :pedigree ], #Only for FAMC
                    [:walk, nil,    :source_citation_record ], #Only for FAMS
                    [:walk, nil,    :note_citation_record ],
                  ]
    super(level)
  end
  
  def parents_family
    if @parents_family_ref != nil
      find(:family,  @parents_family_ref[0])
    else
      nil
    end
  end
  
  def own_family
    if @family_ref != nil
      find(:family,  @family_ref[0])
    else
      nil
    end
  end
    
end

