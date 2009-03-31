require 'gedcom_base.rb'

#Family_individuals hold the FAMC and FAMS relationship between Individual_record and Family_record.
#
#=CHILD_TO_FAMILY_LINK:= (Identifies the family in which an individual appears as a child.)
#  n FAMC @<XREF:FAM>@                  {0:1}
#    +1 PEDI <PEDIGREE_LINKAGE_TYPE>    {0:M}
#    +1 <<NOTE_STRUCTURE>>              {0:M}
#
#=SPOUSE_TO_FAMILY_LINK:= (Identifies the family in which an individual appears as a spouse.)
#  n FAMS @<XREF:FAM>@                  {0:1}
#    +1 <<NOTE_STRUCTURE>>              {0:M}
#
#==PEDIGREE_LINKAGE_TYPE:= {Size=5:7}
#  adopted | birth | foster | sealing
#
#  A code used to indicate the child to family relationship for pedigree navigation purposes.
#  Where:
#    adopted:: indicates adoptive parents.
#    birth::   indicates birth parents.
#    foster::  indicates child was included in a foster or guardian family.
#    sealing:: indicates child was sealed to parents other than birth parents.
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
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
class Families_individuals < GEDCOMBase
  attr_accessor :relationship_type, :parents_family_ref, :family_ref, :pedigree
  attr_accessor :note_citation_record
  attr_accessor :source_citation_record #Only for FAMS (where did I get this idea from ?)

  ClassTracker <<  :Families_individuals
  
  def to_gedcom(level=0)
    @this_level = [ [:xref, @relationship_type[0], :family_ref],
                    [:xref, @relationship_type[0], :parents_family_ref] 
                  ]
    @sub_level =  [ #level 1
                    [:print, "PEDI",    :pedigree ], #Only for FAMC
                    [:walk, nil,    :source_citation_record ], #Only for FAMS (where did I get this idea from ?)
                    [:walk, nil,    :note_citation_record ]
                  ]
    super(level)
  end
  
  def parents_family
    if @parents_family_ref != nil
      find(:family,  @parents_family_ref)
    else
      nil
    end
  end
  
  def own_family
    if @family_ref != nil
      find(:family,  @family_ref)
    else
      nil
    end
  end
    
end

