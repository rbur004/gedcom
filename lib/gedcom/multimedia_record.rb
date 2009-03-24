require 'gedcom_base.rb'

#Internal representation of the GEDCOM OBJE record type
#GEDCOM has both inline OBJE records and references to level 0 OBJE records.
#both are stored here and referenced through a Multimedia_citation_record class.
#
#The attributes are all arrays. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in the OBJE records.
class Multimedia_record < GedComBase
  attr_accessor :multimedia_ref, :format, :title, :encoded_line_record, :next_multimedia_ref, :filename
  attr_accessor :refn_record, :automated_record_id, :note_citation_record, :change_date_record

  ClassTracker <<  :Multimedia_record
  
  def to_gedcom(level=0)
    
    if @multimedia_ref != nil 
      @this_level =  [ [:xref, "OBJE", :multimedia_ref]]
    else
      @this_level =  [ [:nodata, "OBJE", nil] ]
    end

    @sub_level =  [#level 1
                    [:print, "TITL",    :title ],
                    [:print, "FORM",    :format ],
                    [:walk, nil,    :encoded_line_record ],
                    [:xref, nil,     :next_multimedia_ref ],
                    [:print, "FILE",    :filename ],
                    [:walk, nil,    :note_citation_record ],
                    [:walk, nil,     :refn_record ],
                    [:print, "RIN",    :automated_record_id ],
                    [:walk, nil,    :change_date_record ],
                  ]
    
    super(level)
  end
end
