require 'gedcom_base.rb'

class Header_source_record < GedComBase
  attr_accessor :approved_system_id, :version, :name, :corporate_record, :header_data_record
  attr_accessor :note_citation_record
  
  ClassTracker <<  :Header_source_record
  
  def initialize(*a)
    super(*a)
    @this_level = [ [:print, "SOUR", :approved_system_id] ]
    @sub_level =  [ #level + 1
                    [:print, "VERS", :version],
                    [:print, "NAME", :name],
                    [:walk, nil, :corporate_record],
                    [:walk, nil, :header_data_record],
                    [:walk, nil, :note_citation_record],
                  ]
  end  
end
