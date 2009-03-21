require 'gedcom_base.rb'

class Repository_record < GedComBase
  attr_accessor :repository_ref, :repository_name, :phonenumber, :address_record,  :note_citation_record 
  attr_accessor :refn_record, :automated_record_id, :change_date_record

  ClassTracker <<  :Repository_record
  
  def initialize(*a)
    super(*a)
    @this_level = [ [:xref, "REPO", :repository_ref]]
    @sub_level =  [#level 1
                    [:print, "NAME",    :repository_name ],
                    [:print, "PHON",    :phonenumber ],
                    [:walk, nil,    :address_record ],
                    [:walk, nil,    :note_citation_record ],
                    [:walk, nil,     :refn_record ],
                    [:print, "RIN",    :automated_record_id ],
                    [:walk, nil,    :change_date_record ],
                  ]
  end 
end

