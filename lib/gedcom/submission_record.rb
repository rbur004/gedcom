require 'gedcom_base.rb'

#Internal representation of the GEDCOM SUBN record type
#
#The attributes are all arrays. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in the SUBN records.
class Submission_record < GedComBase
  attr_accessor :submission_ref, :submitter_ref, :lds_family_file, :lds_temple_code
  attr_accessor :generations_of_ancestor, :generations_of_descendant, :automated_record_id
  attr_accessor :process_ordinates, :note_citation_record

  ClassTracker <<  :Submission_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
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

