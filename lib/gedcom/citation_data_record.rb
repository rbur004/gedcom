require 'gedcom_base.rb'

class Citation_data_record < GedComBase
  attr_accessor :date_record, :text_record
  attr_accessor :note_citation_record

  ClassTracker <<  :Citation_data_record
  
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

