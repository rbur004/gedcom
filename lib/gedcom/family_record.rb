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
  
  #There should only ever be one husband record in a Family_record. If a women has
  #multiple husbands, as some cultures do, then each should be in their own FAM record.
  #The reasoning is that we are recording parentage, not marriages, so we want to be 
  #able to uniquely identify which husband is the actual parent (not that we could be
  #that certain in the case of polygamy). The term husband is also used loosely. It
  #refers to the father of children, not necessarily a spouse. 
  def husband
    if @husband_ref != nil
      find(@husband_ref.first.index, @husband_ref.first.xref_value)
    else
      nil
    end
  end
  
  #There should only ever be one wife record in a Family_record. If a man has
  #multiple wives, as some cultures do, then each should be in their own FAM record.
  #The reasoning is that we are recording parentage, not marriages, so we want to be 
  #able to uniquely identify which wife is the actual parent. The term wife is used
  #fairly loosely. It refers to the mother of the children, not necessarily a spouse.
  def wife
    if @wife_ref != nil
      find(@wife_ref.first.index, @wife_ref.first.xref_value)
    else
      nil
    end
  end
  
  #Returns an array of children, or if a block is present, yields them one by one.
  def children
    if @child_ref != nil
      children = []
      @child_ref.each do |c| 
        if (child = find(c.index, c.xref_value)) != nil
          yield child if block_given?
          children << c
        end
      end
      return children if children.length > 0
    end
    return nil
  end
  
  #Event looks in the Family_record for events, as specified by the type argument, 
  #returning an array of the events found. Returns nil if there were
  #no events of this type in this Family_record. 
  #
  #If a block is given, then yields each event to the block.
  def event(type)
    if @event_record != nil
      events = []
      @event_record.each do |e| 
        if e.is_event?(type)
          yield e if block_given?
          events << e
        end
      end
      return events if events.length > 0
    end
    return nil
  end
  
  #Short hand for event('ENGA')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def engagement(&p)
    if block_given? then event('ENGA',&p) else event('ENGA') end
  end
  
  #Short hand for event('MARB')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def marriage_bann(&p)
    if block_given? then event('MARB',&p) else event('MARB') end
  end
  
  #Short hand for event('MARL')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def marriage_license(&p)
    if block_given? then event('MARL',&p) else event('MARL') end
  end
  
  #Short hand for event('MARC')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def marriage_contract(&p)
    if block_given? then event('MARC',&p) else event('MARC') end
  end
  
  #Short hand for event('MARS')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def marriage_settlement(&p)
    if block_given? then event('MARS',&p) else event('MARS') end
  end
  
  #Short hand for event('MARR')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def marriage(&p)
    if block_given? then event('MARR',&p) else event('MARR') end
  end
  
  #Short hand for event('ANUL')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def annulment(&p)
    if block_given? then event('ANUL',&p) else event('ANUL') end
  end
  
  #Short hand for event('DIVF')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def divorce_filed(&p)
    if block_given? then event('DIVF',&p) else event('DIVF') end
  end
  
  #Short hand for event('DIV')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def divorce(&p)
    if block_given? then event('DIV',&p) else event('DIV') end
  end
  
  #Short hand for event('CENS')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def census(&p)
    if block_given? then event('CENS',&p) else event('CENS') end
  end
  
end
