require 'gedcom_base.rb'

#Internal representation of a reference to the GEDCOM level 0 OBJE record type
#GEDCOM has both inline OBJE records and references to level 0 OBJE records.
#both are stored stored in a Multimedia_record class and both get referenced through this class.
#
#The attributes are all arrays. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in the OBJE records.
class Multimedia_citation_record < GedComBase
  attr_accessor :multimedia_ref, :multimedia_record
  attr_accessor :note_citation_record

  ClassTracker <<  :Multimedia_citation_record
  
  def to_gedcom(level=0)
    if @multimedia_ref != nil
      @this_level = [ [:xref, "OBJE", :multimedia_ref] ]
      @sub_level =  [#level 1
                      [:walk, nil,    :note_citation_record ],
                    ]
    else
      @this_level = [ [:walk, nil, :multimedia_record] ]
      @sub_level =  [#level 1
                    ]
    end
    super(level)
  end
end

