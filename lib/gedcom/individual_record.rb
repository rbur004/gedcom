require 'gedcom_base.rb'

#Internal representation of the GEDCOM level 0 INDI record type
#
#=INDIVIDUAL_RECORD:=
#  n @XREF:INDI@ INDI                       {1:1}
#    +1 RESN <RESTRICTION_NOTICE>           {0:1}
#    +1 <<PERSONAL_NAME_STRUCTURE>>         {0:M}
#    +1 <<INDIVIDUAL_EVENT_STRUCTURE>>      {0:M}
#    +1 <<INDIVIDUAL_ATTRIBUTE_STRUCTURE>>  {0:M}
#    +1 <<LDS_INDIVIDUAL_ORDINANCE>>        {0:M}
#    +1 <<CHILD_TO_FAMILY_LINK>>            {0:M}
#    +1 <<SPOUSE_TO_FAMILY_LINK>>           {0:M}
#    +1 SUBM @<XREF:SUBM>@                  {0:M}
#    +1 <<ASSOCIATION_STRUCTURE>>           {0:M}
#    +1 ALIA @<XREF:INDI>@                  {0:M}
#    +1 ANCI @<XREF:SUBM>@                  {0:M}
#    +1 DESI @<XREF:SUBM>@                  {0:M}
#    +1 <<SOURCE_CITATION>>                 {0:M}
#    +1 <<MULTIMEDIA_LINK>>                 {0:M}
#    +1 <<NOTE_STRUCTURE>>                  {0:M}
#    +1 RFN <PERMANENT_RECORD_FILE_NUMBER>  {0:1}
#    +1 AFN <ANCESTRAL_FILE_NUMBER>         {0:1}
#    +1 REFN <USER_REFERENCE_NUMBER>        {0:M}
#      +2 TYPE <USER_REFERENCE_TYPE>        {0:1}
#    +1 RIN <AUTOMATED_RECORD_ID>           {0:1}
#    +1 <<CHANGE_DATE>>                     {0:1}
#
#  The individual record is a compilation of facts, known or discovered, about an individual. Sometimes
#  these facts are from different sources. This form allows documentation of the source where each of
#  the facts were discovered.
#
#  The normal lineage links are shown through the use of pointers from the individual to a family
#  through either the FAMC tag or the FAMS tag. The FAMC tag provides a pointer to a family where
#  this person is a child. The FAMS tag provides a pointer to a family where this person is a spouse or
#  parent. The <<CHILD_TO_FAMILY_LINK>> (see page 27) structure contains a FAMC pointer
#  which is required to show any child to parent linkage for pedigree navigation. The
#  <<CHILD_TO_FAMILY_LINK>> structure also indicates whether the pedigree link represents a
#  birth lineage, an adoption lineage, or a sealing lineage.
#
#  Linkage between a child and the family they belonged to at the time of an event can also optionally
#  be shown by a FAMC pointer subordinate to the appropriate event. For example, a FAMC pointer
#  subordinate to an adoption event would show which family adopted this individual. Biological parent
#  or parents can be indicated by a FAMC pointer subordinate to the birth event. The FAMC tag can
#  also optionally be used subordinate to an ADOPtion, or BIRTh event to differentiate which set of
#  parents were related by adoption, sealing, or birth.
#
#  I removed SEX from INDI and added it to the Individual_attribute_record class.
#
#  Other associations or relationships are represented by the ASSOciation tag. The person's relation
#  or association is the person being pointed to. The association or relationship is stated by the value
#  on the subordinate RELA line. For example:
#    0 @I1@ INDI
#    1 NAME Fred/Jones/
#    1 ASSO @I2@
#    2 RELA Godfather
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
class Individual_record < GEDCOMBase
  attr_accessor :individual_ref, :restriction, :name_record, :event_record, :individual_attribute_record, :alias_ref
  attr_accessor :families_individuals, :association_record, :submitter_ref, :ancestor_interest_ref, :descendant_interest_ref
  attr_accessor :source_citation_record, :multimedia_citation_record, :note_citation_record
  attr_accessor :registered_ref_id, :lds_ancestral_file_no, :refn_record, :automated_record_id, :change_date_record

  ClassTracker <<  :Individual_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:xref, "INDI", :individual_ref] ]
    @sub_level =  [ #level 1
                    [:print, "RESN", :restriction],
                    [:walk, nil,  :name_record],
                    [:walk, nil, :individual_attribute_record],
                    [:walk, nil, :event_record],
                    [:walk, nil, :families_individuals],
                    [:walk, nil, :association_record],
                    [:xref, "ALIA", :alias_ref],
                    [:xref, "ANCI", :ancestor_interest_ref],
                    [:xref, "DESI", :descendant_interest_ref],
                    [:xref, "SUBM", :submitter_ref],
                    [:walk, nil,    :multimedia_citation_record ],
                    [:walk, nil,    :source_citation_record ],
                    [:walk, nil,    :note_citation_record ],
                    [:print, "RFN", :registered_ref_id],
                    [:print, "AFN", :lds_ancestral_file_no],
                    [:walk, nil, :refn_record ],
                    [:walk, nil,    :change_date_record],
                    [:print, "RIN",  :automated_record_id ],
                  ]
  end  
  
  def id
    #temporary 
    @individual_ref
  end
  
  def parents_family
    parents_family = []
    @families_individuals.each { |m| parents_family << m.parents_family_ref if m.relationship_type == "FAMC"}
    parent_family
  end
  
  def spouses
    spouses = []
    @families_individuals.each { |m| spouses << m.own_family if m.relationship_type == "FAMS"}
    spouses
  end
  
  def birth
    if @event_record != nil
      @event_record.each { |e| if e.is_event('BIRT') then return e end }
    else
      nil
    end
  end
  
  def death
    if @event_record != nil
      @event_record.each { |e| if e.is_event('DEAT') then return e end }
    else
      nil
    end
  end
end
