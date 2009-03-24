require 'gedcom_base.rb'

#Internal representation of the GEDCOM ASSO record types
#
#The attributes are all arrays. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record types.
class Association_record < GedComBase
  attr_accessor :association_ref, :associated_record_tag, :relationship_description
  attr_accessor :source_citation_record, :note_citation_record

  ClassTracker <<  :Association_record
  
  def initialize(*a)
    super(*a)
    @this_level = [ [:xref, "ASSO", :association_ref ] ]
    @sub_level =  [ #level 1
                    [:print, "TYPE",    :associated_record_tag ],
                    [:print, "RELA",    :relationship_description ],
                    [:walk, nil,    :source_citation_record ],
                    [:walk, nil,    :note_citation_record ],
                  ]
  end
end

