require 'gedcom_base.rb'

#Internal representation of the GEDCOM SUBM record type
#
#The attributes are all arrays. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in the SUBM records.
class Submitter_record < GedComBase
  attr_accessor :submitter_ref, :name_record, :address_record, :phone, :multimedia_citation_record
  attr_accessor :language_list, :lds_submitter_id, :automated_record_id, :change_date_record, :note_citation_record

  ClassTracker <<  :Submitter_record
   
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
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

