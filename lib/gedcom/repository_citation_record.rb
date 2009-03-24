require 'gedcom_base.rb'

#Internal representation of a reference to the GEDCOM REPO citation record type
#The actual REPO record is stored in the Repository_record class.
#
#The attributes are all arrays. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in the REPO records.
class Repository_citation_record < GedComBase
  attr_accessor :repository_ref, :note_citation_record, :repository_caln

  ClassTracker <<  :Repository_citation_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level =  [ [:xref, "REPO", :repository_ref] ] 
    @sub_level =  [ #level + 1
                    [:walk, nil, :repository_caln],
                    [:walk, nil, :note_citation_record],
                  ]
  end 
end

