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
  
  #Finds the parent's family record(s) and returns the Family_record object in an array.
  #This allows for multiple parentage. There is usually only be one FAMC record, but their 
  #might be another recording an adoption or an alternate family, if parentage no clear.
  #Parents_family returns nil if there are no FAMC records (or the FAMC XREFs
  #don't resolve to a FAM record in the transmission).
  #
  #If a block is passed, then each Family_record is yielded to the block.
  def parents_family
    if @families_individuals
      parent_families = []
      @families_individuals.each do |p| 
        if p.relationship_type == "FAMC"
          if (parent_family = find(:family, p.parents_family_ref)) != nil
            parent_families << parent_family
            yield parent_family if block_given?
          end
        end
      end
      return parent_families if parent_families.length > 0 #might be a 0 length array.
    end
    return nil
  end
  
  #Finds the family record for each spouse (or fellow parent) and returns the Family_record objects in an array.
  #This allows for being a parent of multiple families. Spouses will return nil if there are no 
  #FAMS records (or the FAMS XREFs don't resolve to a FAM record in the transmission).
  #
  #If a block is passed, then each Family_record is yielded to the block.
  def spouses
    if @families_individuals
      spouses = []
      @families_individuals.each do |s|
        if s.relationship_type == "FAMS"
          #Make sure we can find the spouse's Family_record.
          if (spouse_family = find(:family, p.parents_family_ref)) != nil
            parent_families << spouse_family
            yield parent_family if block_given?
          end
        end
      end
      return spouses if spouses.length > 0 #might be a 0 length array.
    end
    return nil
  end
  
  #Event looks in the Individual_record for events, as specified by the type argument, 
  #returning an array of the events found. Returns nil if there were
  #no events of this type in this Individual_record. 
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
  
  #Short hand for event('BIRT')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def birth(&p)
    if block_given? then event('BIRT',&p) else event('BIRT') end
  end
  
  #Short hand for event('CHR')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def christening(&p)
    if block_given? then event('CHR',&p) else event('CHR') end
  end
  
  #Short hand for event('ADOP')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def adoption(&p)
    if block_given? then event('ADOP',&p) else event('ADOP') end
  end
  
  #Short hand for event('DEAT')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def death(&p)
    if block_given? then event('DEAT',&p) else event('DEAT') end
  end
  
  #Short hand for event('BURI')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def burial(&p)
    if block_given? then event('BURI',&p) else event('BURI') end
  end
  
  #Short hand for event('CREM')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def cremation(&p)
    if block_given? then event('CREM',&p) else event('CREM') end
  end
  
  #Short hand for event('WILL')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def will(&p)
    if block_given? then event('WILL',&p) else event('WILL') end
  end
  
  #Short hand for event('PROB')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def probate(&p)
    if block_given? then event('PROB',&p) else event('PROB') end
  end
  
  #Short hand for event('CENS')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def census(&p)
    if block_given? then event('CENS',&p) else event('CENS') end
  end
  
  #Short hand for event('GRAD')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def graduation(&p)
    if block_given? then event('GRAD',&p) else event('GRAD') end
  end
  
  #Short hand for event('RETI')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def retirement(&p)
    if block_given? then event('RETI',&p) else event('RETI') end
  end
  
  #Short hand for event('BAPM')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def baptism(&p)
    if block_given? then event('BAPM',&p) else event('BAPM') end
  end
  
  #Short hand for event('BARM')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def bar_mitzvah(&p)
    if block_given? then event('BARM',&p) else event('BARM') end
  end
  
  #Short hand for event('BASM')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def bas_mitzvah(&p)
    if block_given? then event('BASM',&p) else event('BASM') end
  end
  
  #Short hand for event('BLES')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def blessing(&p)
    if block_given? then event('BLES',&p) else event('BLES') end
  end
  
  #Short hand for event('ORDN')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def ordination(&p)
    if block_given? then event('ORDN',&p) else event('ORDN') end
  end
  
  #Short hand for event('CHRA')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def adult_christening(&p)
    if block_given? then event('CHRA',&p) else event('CHRA') end
  end
  
  #Short hand for event('CONF')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def confirmation(&p)
    if block_given? then event('CONF',&p) else event('CONF') end
  end
  
  #Short hand for event('FCOM')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def first_communion(&p)
    if block_given? then event('FCOM',&p) else event('FCOM') end
  end
  
  #Short hand for event('NATU')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def naturalization(&p)
    if block_given? then event('NATU',&p) else event('NATU') end
  end
  
  #Short hand for event('EMIG')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def emigration(&p)
    if block_given? then event('EMIG',&p) else event('EMIG') end
  end
  
  #Short hand for event('IMMI')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def immigration(&p)
    if block_given? then event('IMMI',&p) else event('IMMI') end
  end
  
  #Short hand for the event('BAPL') LDS Ordinance 
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def lds_baptism(&p)
    if block_given? then event('BAPL',&p) else event('BAPL') end
  end
  
  #Short hand for the event('CONL') LDS Ordinance 
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def lds_confirmation(&p)
    if block_given? then event('CONL',&p) else event('CONL') end
  end
  
  #Short hand for the event('ENDL') LDS Ordinance 
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def lds_endowment(&p)
    if block_given? then event('ENDL',&p) else event('ENDL') end
  end
  
  #Short hand for the event('SLGC') LDS Ordinance 
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def lds_child_sealing(&p)
    if block_given? then event('SLGC',&p) else event('SLGC') end
  end
  
  #Short hand for the event('SLGS') LDS Sealing 
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def lds_spouse_sealing(&p)
    if block_given? then event('SLGS',&p) else event('SLGS') end
  end
  
  #Attribute looks in the Individual_record for attributes, as specified by the attribute argument, 
  #returning an array of the attrbutes found. This may be a 0 length array, if there were
  #no attrbutes of this type in this Individual_record. 
  #
  #If a block is given, then yields each event to the block.
  def attribute(attribute)
    if @individual_attribute_record != nil
      attributes = [] #collect the individual_attribute_record's of type attribute in this array.
      @individual_attribute_record.each do |a| 
        #Look for the attribute in question.
        if a.is_attribute?(attribute)
          yield a if block_given? 
          attributes << a #add this record to the attributes array.
        end
      end
      return attributes if attributes.length > 0 #if we found any, return the array.
    end
    return nil #if we found none, then return nil.
  end
  
  #Short hand for attribute('SEX')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def sex(&p)
    if block_given? then attribute('SEX',&p) else attribute('SEX') end
  end
  
  #Short hand for attribute('CAST')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def caste_name(&p)
    if block_given? then attribute('CAST',&p) else attribute('CAST') end
  end
  
  #Short hand for attribute('DSCR')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def physical_description(&p)
    if block_given? then attribute('DSCR',&p) else attribute('DSCR') end
  end
  
  #Short hand for attribute('EDUC')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def education(&p)
    if block_given? then attribute('EDUC',&p) else attribute('EDUC') end
  end
  
  #Short hand for attribute('IDNO')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def national_id_number(&p)
    if block_given? then attribute('IDNO',&p) else attribute('IDNO') end
  end
  
  #Short hand for attribute('NATI')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def national_origin(&p)
    if block_given? then attribute('NATI',&p) else attribute('NATI') end
  end
  
  #Short hand for attribute('NCHI')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def number_children(&p)
    if block_given? then attribute('NCHI',&p) else attribute('NCHI') end
  end
  
  #Short hand for attribute('NMR')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def marriage_count(&p)
    if block_given? then attribute('NMR',&p) else attribute('NMR') end
  end
  
  #Short hand for attribute('OCCU')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def occupation(&p)
    if block_given? then attribute('OCCU',&p) else attribute('OCCU') end
  end
  
  #Short hand for attribute('PROP')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def possessions(&p)
    if block_given? then attribute('PROP',&p) else attribute('PROP') end
  end
  
  #Short hand for attribute('RELI')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def religion(&p)
    if block_given? then attribute('RELI',&p) else attribute('RELI') end
  end
  
  #Short hand for attribute('RESI')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def residence(&p)
    if block_given? then attribute('RESI',&p) else attribute('RESI') end
  end
  
  #Short hand for attribute('SSN')
  #passes on any block to the event method.
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def social_security_number(&p)
    if block_given? then attribute('SSN',&p) else attribute('SSN') end
  end
  
  #Short hand for attribute('TITL')
  #passes on any block to the event method 
  #(The block is the &p argument, so you don't pass any arguments to this method).
  def title(&p)
    if block_given? then attribute('TITL',&p) else attribute('TITL') end
  end

  #Test to see if we have a NAME record stored for this individual.
  def has_name?
    @name_record != nil && @name_record.length > 0
  end
  
  #Names looks in the Individual_record for Name_records, returning an array of the Name_records found. 
  #This may be a 0 length array, if there were no NAME tags in this GEDCOM record for this Individual_record. 
  #
  #If a block is given, then yields each event to the block.
  def names
    if has_name?
      if block_given?
        @name_record.each { |n| yield n }
      end
      return @name_record
    else
      return []
    end
  end
  
  #Primary_name returns the first name (as a string) defined in the @name_record array (and probably the only name defined).
  #The GEDCOM standard states that if multiple TAGS of the same type are present, then the first is the most
  #preferred, with the last the least preferred. I'm not certain that programs generating GEDCOM follow that rule,
  #but if there are multiple NAME records, and you want one to display, then picking the first is what the standard
  #says to do.
  #
  #Returns "" if no name is recorded in this Individual_record and if the individual requested privacy for this record.
  def primary_name
    if has_name? 
      if  self.private? || @name_record[0].private?
        ""
      else
         @name_record[0].name 
      end 
    else 
      "" 
    end
  end
  
end
