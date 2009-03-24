require 'gedcom_base.rb'

#Internal representation of a reference to the GEDCOM SOUR record type.
#Both inline SOUR records and references to a Level 0 SOUR records are referenced via this class.
#
#The attributes are all arrays. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in the SOUR records.
class Source_citation_record < GedComBase
  attr_accessor :source_ref, :source_record, :page, :citation_event_type_record, :citation_data_record, :quality 
  attr_accessor :note_citation_record, :multimedia_citation_record 

  ClassTracker <<  :Source_citation_record
  
  #to_gedcom sets up the state engine arrays @this_level and @sub_level, which drive the parent class to_gedcom method generating GEDCOM output.
  #There are two types of SOUR record, inline and reference, so this is done dynamically in to_gedcom rather than the initialize method.
  #Probably should be two classes, rather than this conditional.
  def to_gedcom(level=0)
    if(@source_ref != nil)
      @this_level = [ [:xref, "SOUR", :source_ref] ]
      @sub_level =  [  #level + 1
                      [:print, "PAGE", :page],
                      [:walk, nil,    :citation_event_type_record],
                      [:walk, nil,    :citation_data_record],
                      [:print, "QUAY",  :quality],
                      [:walk, nil,  :multimedia_citation_record],
                      [:walk, nil,  :note_citation_record],
                    ]
     elsif @source_record != nil
       @this_level = [ [:walk, nil,  :source_record] ]
       @sub_level =  []
     end
     super(level)
  end
end

