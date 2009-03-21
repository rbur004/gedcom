require 'gedcom_base.rb'

class Repository_citation_record < GedComBase
  attr_accessor :repository_ref, :note_citation_record, :repository_caln

  ClassTracker <<  :Repository_citation_record
  
  def initialize(*a)
    super(*a)
    @this_level =  [ [:xref, "REPO", :repository_ref] ] 
    @sub_level =  [ #level + 1
                    [:walk, nil, :repository_caln],
                    [:walk, nil, :note_citation_record],
                  ]
  end 
end

