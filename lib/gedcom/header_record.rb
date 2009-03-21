require 'gedcom_base.rb'

class Header_record < GedComBase
  attr_accessor :header_source_record, :destination, :date_record, :submitter_ref, :submission_ref
  attr_accessor :file_name, :copyright, :gedcom_record, :character_set_record, :language_id
  attr_accessor :place_record, :note_citation_record
  
  ClassTracker <<  :Header_record
  
  def initialize(*a)
    super(*a)
    @this_level = [ [:nodata, "HEAD", nil] ]
    @sub_level =  [ #level + 1
                    [:walk, nil,:header_source_record],
                    [:print, "DEST", :destination],
                    [:walk, nil, :date_record], 
                    [:xref, "SUBM", :submitter_ref], 
                    [:xref, "SUBN", :submission_ref],
                    [:print, "FILE", :file_name], 
                    [:print, "COPR", :copyright], 
                    [:walk, nil, :gedcom_record],  
                    [:walk, nil, :character_set_record], 
                    [:print, "LANG", :language_id], 
                    [:walk, nil, :place_record], 
                    [:walk, nil, :note_citation_record],
                  ]
  end  
end
