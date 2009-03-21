require 'gedcom_base.rb'

class Submitter_record < GedComBase
  attr_accessor :submitter_ref, :name_record, :address_record, :phone, :multimedia_citation_record
  attr_accessor :language_list, :lds_submitter_id, :automated_record_id, :change_date_record, :note_citation_record

  ClassTracker <<  :Submitter_record
   
  def initialize(*a)
    super(*a)
    @this_level = [ [:xref, "SUBM", :submitter_ref] ]
    @sub_level =  [ #level + 1
                    [:walk, nil,    :name_record ],
                    [:walk, nil,    :address_record ],
                    [:print, "PHON",    :phone ],
                    [:print, "LANG",    :language_list ],
                    [:walk, nil,    :multimedia_citation_record ],
                    [:walk, nil,    :note_citation_record ],
                    [:print, "RFN",    :lds_submitter_id ],
                    [:print, "RIN",    :automated_record_id ],
                    [:walk, nil,    :change_date_record ],
                  ]
  end 
  
end

