require 'gedcom_base.rb'

class Source_citation_record < GedComBase
  attr_accessor :source_ref, :source_record, :page, :citation_event_type_record, :citation_data_record, :quality 
  attr_accessor :note_citation_record, :multimedia_citation_record 

  ClassTracker <<  :Source_citation_record
  
  def to_gedcom(level=0)
    if(@source_ref)
      @this_level = [ [:xref, "SOUR", :source_ref] ]
      @sub_level =  [  #level + 1
                      [:print, "PAGE", :page],
                      [:walk, nil,    :citation_event_type_record],
                      [:walk, nil,    :citation_data_record],
                      [:print, "QUAY",  :quality],
                      [:walk, nil,  :multimedia_citation_record],
                      [:walk, nil,  :note_citation_record],
                    ]
     elsif @source_record
       @this_level = [ [:walk, nil,  :source_record] ]
       @sub_level =  []
     end
     super(level)
  end
end

