require 'gedcom_base.rb'

class Source_record < GedComBase
  attr_accessor :source_ref, :short_title, :title, :author,  :source_scope_record,  :publication_details
  attr_accessor :repository_citation_record, :text_record, :note_citation_record, :multimedia_citation_record
  attr_accessor :refn_record, :automated_record_id, :change_date_record

  ClassTracker <<  :Source_record
  
  def to_gedcom(level=0)
    if @source_ref
      @this_level = [ [:xref, "SOUR", :source_ref] ]
      @sub_level =  [ #level + 1
                      [:print, "ABBR", :short_title],
                      [:cont, "TITL", :title],
                      [:cont, "AUTH", :author],
                      [:cont, "PUBL", :publication_details],
                      [:walk, nil,  :repository_citation_record],
                      [:walk, nil, :text_record],
                      [:walk, nil, :multimedia_citation_record],
                      [:walk, nil, :source_scope_record],
                      [:walk, nil, :note_citation_record],
                      [:walk, nil, :refn_record],
                      [:print, "RIN", :automated_record_id],
                      [:walk,  nil, :change_date_record],
                    ]
    else
      @this_level = [ [:cont, "SOUR", :title] ]
      @sub_level =  [ #level + 1
                      [:walk, nil, :text_record],
                      [:walk, nil, :note_citation_record] ,
                    ] 
    end
    super(level)
  end
end

