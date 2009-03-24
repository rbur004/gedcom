require 'gedcom_base.rb'

class Citation_data_record < GedComBase
  attr_accessor :date_record, :text_record
  attr_accessor :note_citation_record

  ClassTracker <<  :Citation_data_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:print, "DATA", nil ] ]
    @sub_level =  [ #level 1
                    [:walk, nil, :date_record],
                    [:walk, nil, :text_record ],
                    [:walk, nil, :note_citation_record ],
                  ]
  end
end

