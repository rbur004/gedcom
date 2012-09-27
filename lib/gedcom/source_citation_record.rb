require 'gedcom_base.rb'

#Internal representation of a reference to the GEDCOM SOUR record type.
#Both inline SOUR records and references to a Level 0 SOUR records are referenced via this class.
#We store inline SOUR records in Source_record objects, not Source_citation_record objects.
#
#=SOURCE_CITATION:= (within another record, referencing a SOURCE_RECORD)
#  n SOUR @<XREF:SOUR>@                         {1:1} (pointer to source record)
#    +1 PAGE <WHERE_WITHIN_SOURCE>              {0:1}
#    +1 EVEN <EVENT_TYPE_CITED_FROM>            {0:1}
#      +2 ROLE <ROLE_IN_EVENT>                  {0:1}
#    +1 DATA                                    {0:1}
#      +2 DATE <ENTRY_RECORDING_DATE>           {0:1}
#      +2 TEXT <TEXT_FROM_SOURCE>               {0:M}
#        +3 [ CONC | CONT ] <TEXT_FROM_SOURCE>  {0:M}
#    +1 QUAY <CERTAINTY_ASSESSMENT>             {0:1}
#    +1 <<MULTIMEDIA_LINK>>                     {0:M}
#    +1 <<NOTE_STRUCTURE>>                      {0:M}
#
#  The data provided in the <<SOURCE_CITATION>> structure is source-related information specific
#  to the data being cited. (See GEDCOM examples starting on page 57.) Systems that do not use
#  SOURCE_RECORDS must use the second SOURce citation structure option. When systems which
#  support SOURCE_RECORD structures encounter source citations which do not contain pointers to
#  source records, that system will need to create a SOURCE_RECORD and store the
#  <SOURCE_DESCRIPTION> information found in the non-structured source citation in either the
#  title area of that SOURCE_RECORD, or if the title field is not large enough, place a "(See Notes)"
#  text in the title area, and place the unstructured source description in the source record's note field.
#
#  The information intended to be placed in the citation structure includes:
#  * A pointer to the SOURCE_RECORD, which contains a more general description of the source.
#  * Information, such as a page number, on how to find the cited data within the source.
#  * Actual text from the source that was used in making assertions, for example a date phrase as
#    actually recorded or an applicable sentence from a letter, would be appropriate.
#  * Data that allows an assessment of the relative value of one source over another for making the
#    recorded assertions (primary or secondary source, etc.). Data needed for this assessment is how
#    much time from the asserted fact and when the source event was recorded, what type of event
#    was cited, and what was the role of this person in the cited event.
#    - Date when the entry was recorded in source document, ".SOUR.DATA.DATE."
#    - Event that initiated the recording, ".SOUR.EVEN."
#    - Role of this person in the event, ".SOUR.EVEN.ROLE".
#
#The attributes are all arrays representing all the +1 TAGS/Records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in the SOUR records.
#
class Source_citation_record < GEDCOMBase
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

