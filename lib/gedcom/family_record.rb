require 'gedcom_base.rb'

#Family_record is the internal representation of a level 0 GEDCOM FAM record.
#
#=FAM_RECORD:=
#  0 @<XREF:FAM>@ FAM                     {0:M}
#    +1 <<FAMILY_EVENT_STRUCTURE>>        {0:M} p.28
#      +2 HUSB                            {0:1}
#        +3 AGE <AGE_AT_EVENT>            {1:1} p.35
#      +2 WIFE                            {0:1}
#        +3 AGE <AGE_AT_EVENT>            {1:1}
#    +1 HUSB @<XREF:INDI>@                {0:1} p.52
#    +1 WIFE @<XREF:INDI>@                {0:1} p.52
#    +1 CHIL @<XREF:INDI>@                {0:M} p.52
#    +1 NCHI <COUNT_OF_CHILDREN>          {0:1} p.37
#    +1 SUBM @<XREF:SUBM>@                {0:M} p.52
#    +1 <<LDS_SPOUSE_SEALING>>            {0:M} p.30
#    +1 <<SOURCE_CITATION>>               {0:M} p.32
#    +1 <<MULTIMEDIA_LINK>>               {0:M} p.30,23
#    +1 <<NOTE_STRUCTURE>>                {0:M} p.31
#    +1 REFN <USER_REFERENCE_NUMBER>      {0:M} p.51
#      +2 TYPE <USER_REFERENCE_TYPE>      {0:1} p.51
#    +1 RIN <AUTOMATED_RECORD_ID>         {0:1} p.36
#   +1 <<CHANGE_DATE>>                    {0:1} p.27
#
#  The FAMily record is used to record marriages, common law marriages, and family unions caused by
#  two people becoming the parents of a child (i.e they may not be married). There can be no more 
#  than one HUSB/father and one WIFE/mother listed in each FAM_RECORD. We are recording parentage,
#  rather than marriages per se. If, for example, a man participated in more than one
#  family union (or with more than 1 wife) then he would appear in more than one FAM_RECORD. The 
#  family record structure assumes that the HUSB/father is male and WIFE/mother is female. Again,
#  as we are recording parentage, and we can't yet clone or reproduce from two males. or from two females.
#
#  The preferred order of the CHILdren pointers within a FAMily structure is chronological by birth.
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
class Family_record < GEDCOMBase
  attr_accessor :restriction #not standard at the event level, but we might want this in DB.
  attr_accessor :family_ref, :event_record, :husband_ref, :wife_ref, :child_ref, :number_children, :submitter_ref
  attr_accessor :source_citation_record, :multimedia_citation_record
  attr_accessor :note_citation_record, :refn_record, :automated_record_id, :change_date_record

  ClassTracker <<  :Family_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:xref, "FAM", :family_ref] ]
    @sub_level =  [ #level + 1
                    [:xref, "HUSB", :husband_ref],
                    [:xref, "WIFE", :wife_ref],
                    [:xref, "CHIL", :child_ref],
                    [:print, "NCHI", :number_children],
                    [:walk, nil, :event_record],
                    [:xref, "SUBM", :submitter_ref],
                    [:walk, nil,   :multimedia_citation_record],
                    [:walk, nil,  :source_citation_record],
                    [:walk, nil, :note_citation_record],
                    [:walk, nil, :refn_record],
                    [:print, "RIN", :automated_record_id],
                    [:walk, nil,  :change_date_record],
                  ]
  end  
  
  def id
    #temporary 
    @family_ref
  end
  
  def husband
    if @husband_ref != nil
      find(@husband_ref[0], @husband_ref[1])
    else
      nil
    end
  end
  
  def wife
    if @wife_ref != nil
      find(@wife_ref[0], @wife_ref[1])
    else
      nil
    end
  end
  
end
