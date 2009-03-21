require 'gedcom_base.rb'

class Adoption_record < GedComBase
  attr_accessor :birth_family_ref, :adopt_family_ref, :adopted_by
  attr_accessor :note_citation_record

  ClassTracker <<  :Adoption_record

  def initialize(*a)
    super(*a)
    @this_level = [ [:xref, "FAMC", :birth_family_ref ],
                    [:xref, "FAMC", :adopt_family_ref] #Only adopted family version of birth event record
                  ]
    @sub_level =  [ #level 1
                    [:print, "ADOP", :adopted_by], #Only adopted family version of birth event record
                    [:walk, nil,    :note_citation_record ],
                  ]
  end

end

