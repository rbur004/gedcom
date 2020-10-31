require 'gedcom_base.rb'

#Adoption_record is a rarely seen sub-record of FAMC in Individual Event_record. 
#These can occur is Event_record BIRT and ADOP event types.
#
#=INDIVIDUAL_EVENT_STRUCTURE:=
#  ...
#  -1 ADOP [Y|<NULL>]                       {1:1} (Not this ADOP record. This is the event.)
#    ...
#    n FAMC @<XREF:FAM>@                    {0:1} (This FAMC and its ADOP record.)
#      +1 ADOP <ADOPTED_BY_WHICH_PARENT>    {0:1} 
#  ...
#    n BIRT [Y|<NULL>]                      {1:1}
#      ...
#      +1 FAMC @<XREF:FAM>@                 {0:1} (And this FAMC in the BIRT Event.)
#  ...
#
#==ADOPTED_BY_WHICH_PARENT:= {Size=1:4}
#  HUSB | WIFE | BOTH
#
#  A code which shows which parent in the associated family record adopted this person.
#  Where:
#    HUSB:: The HUSBand in the associated family adopted this person.
#    WIFE:: The WIFE in the associated family adopted this person.
#    BOTH:: Both HUSBand and WIFE adopted this person.
#
#  Linkage between a child and the family they belonged to at the time of an event can also optionally
#  be shown by a FAMC pointer subordinate to the appropriate event. For example, a FAMC pointer
#  subordinate to an adoption event would show which family adopted this individual. Biological parent
#  or parents can be indicated by a FAMC pointer subordinate to the birth event. The FAMC tag can
#  also optionally be used subordinate to an ADOPtion, or BIRTh event to differentiate which set of
#  parents were related by adoption, sealing, or birth.
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
class Adoption_record < GEDCOMBase
  attr_accessor :birth_family_ref, :adopt_family_ref, :adopted_by
  attr_accessor :note_citation_record

  ClassTracker <<  :Adoption_record

  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:xref, "FAMC", :birth_family_ref ], #Only adopted family version of birth event record
                    [:xref, "FAMC", :adopt_family_ref]   #Adopted family version of ADOP event record
                  ]
    @sub_level =  [ #level 1
                    [:print, "ADOP", :adopted_by], #Only adopted family version of ADOP event record
                    [:walk, nil,    :note_citation_record ]
                  ]
  end

end

