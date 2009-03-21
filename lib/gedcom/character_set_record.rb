require 'gedcom_base.rb'

class Character_set_record < GedComBase
  attr_accessor :char_set_id, :version
  attr_accessor :note_citation_record

  ClassTracker <<  :Character_set_record
  
  def initialize(*a)
    super(*a)
    @this_level = [ [:print, "CHAR", :char_set_id] ]
    @sub_level =  [ #level + 1
                    [:print, "VERS", :version],
                    [:walk, nil,    :note_citation_record],
                  ]
  end
end
