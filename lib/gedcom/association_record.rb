require 'gedcom_base.rb'

#Internal representation of the GEDCOM ASSO record types. 
#
#A relationship between an Individual_record and one of the other level 0
#record types, as defined by the TYPE tag. The default being another 
#a relationship with another Individual_record.
#
#=ASSOCIATION_STRUCTURE:=
#  n ASSO @<XREF:TYPE>@                   {0:M}
#    +1 TYPE <RECORD_TYPE>                {1:1}
#    +1 RELA <RELATION_IS_DESCRIPTOR>     {1:1}
#    +1 <<NOTE_STRUCTURE>>                {0:M}
#    +1 <<SOURCE_CITATION>>               {0:M}
#
#==RECORD_TYPE:= {Size=3:4}
#  FAM | INDI | NOTE | OBJE | REPO | SOUR | SUBM | SUBN
#
#  An indicator of the record type being pointed to or used. For example if in an ASSOciation, an
#  INDIvidual record were to be ASSOciated with a FAM record then:
#    0 INDI
#      1 ASSO @F1@
#        2 TYPE FAM /* ASSOCIATION is with a FAM record.
#        2 RELA Witness at marriage
#
#==RELATION_IS_DESCRIPTOR:= {Size=1:25}
#  A word or phrase that states object 1's relation is object 2. For example you would read the following
#  as "Joe Jacob's great grandson is the submitter pointed to by the @XREF:SUBM@":
#     0 INDI
#       1 NAME Joe /Jacob/
#       1 ASSO @<XREF:SUBM>@
#        2 TYPE SUBM
#        2 RELA great grandson
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
class Association_record < GEDCOMBase
  attr_accessor :association_ref, :associated_record_tag, :relationship_description
  attr_accessor :source_citation_record, :note_citation_record

  ClassTracker <<  :Association_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:xref, "ASSO", :association_ref ] ]
    @sub_level =  [ #level 1
                    [:print, "TYPE",    :associated_record_tag ],
                    [:print, "RELA",    :relationship_description ],
                    [:walk, nil,    :source_citation_record ],
                    [:walk, nil,    :note_citation_record ],
                  ]
  end

  protected
  
  #validate that the record referenced by the XREF actually exists in this transmission.
  #Genearte a warning if it does not. It does not stop the processing of this line.
  #Association_records default to :individual, but the TYPE field can override this.
  def xref_check(level, tag, xref)
    asso_index = case @associated_record_tag
    when nil then xref.index #this should be the default :individual
    when 'FAM'  then :family
    when 'INDI' then :individual
    when 'NOTE' then :note
    when 'OBJE' then :multimedia
    when 'REPO' then :repository
    when 'SOUR' then :source
    when 'SUBM' then :submitter
    when 'SUBM' then :submission
    else :individual #which will be the default individual index.
    end
    
    super(level, tag, Xref.new(asso_index, xref.xref_value) )
  end
end

