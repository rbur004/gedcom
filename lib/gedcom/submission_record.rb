require 'gedcom_base.rb'

class Submission_record < GedComBase
  attr_accessor :submission_ref, :submitter_ref, :lds_family_file, :lds_temple_code
  attr_accessor :generations_of_ancestor, :generations_of_descendant, :automated_record_id
  attr_accessor :process_ordinates, :note_citation_record

  ClassTracker <<  :Submission_record
  
  def initialize(*a)
    super(*a)
    @this_level = [ [:xref, "SUBN", :submission_ref] ]
    @sub_level =  [ #level + 1
                    [:xref, "SUBM", :submitter_ref],
                    [:print, "FAMF",    :lds_family_file ],
                    [:print, "TEMP",    :lds_temple_code ],
                    [:print, "ANCE",    :generations_of_ancestor ],
                    [:print, "DESC",    :generations_of_descendant ],
                    [:print, "ORDI",    :process_ordinates ],
                    [:print, "RIN",    :automated_record_id ],
                    [:walk, nil,    :note_citation_record ],
                  ]
  end   
end

