require 'gedcom_base.rb'

#Copyright_record was introduced in 0.9.3 to allow CONT and CONC tags after the COPR record.
#Gedcom 5.5
#=HEADER:=
#  n HEAD                                          {1:1}
#    +1 SOUR <APPROVED_SYSTEM_ID>                  {1:1}
#      +2 VERS <VERSION_NUMBER>                    {0:1}
#      +2 NAME <NAME_OF_PRODUCT>                   {0:1}
#      +2 CORP <NAME_OF_BUSINESS>                  {0:1}
#        +3 <<ADDRESS_STRUCTURE>>                  {0:1}
#      +2 DATA <NAME_OF_SOURCE_DATA>               {0:1}
#        +3 DATE <PUBLICATION_DATE>                {0:1}
#        +3 COPR <COPYRIGHT_SOURCE_DATA>           {0:1}
#       ...
#GEDCOM 5.5.1
#=HEADER:=
#  n HEAD                                          {1:1}
#    +1 SOUR <APPROVED_SYSTEM_ID>                  {1:1}
#      +2 VERS <VERSION_NUMBER>                    {0:1}
#      +2 NAME <NAME_OF_PRODUCT>                   {0:1}
#      +2 CORP <NAME_OF_BUSINESS>                  {0:1}
#        +3 <<ADDRESS_STRUCTURE>>                  {0:1}
#      +2 DATA <NAME_OF_SOURCE_DATA>               {0:1}
#        +3 DATE <PUBLICATION_DATE>                {0:1}
#        +3 COPR <COPYRIGHT_SOURCE_DATA>           {0:1}
#           +4 [CONT|CONC]<COPYRIGHT_SOURCE_DATA>  {0:M}
#       ...

class Copyright_record   < GEDCOMBase
  attr_accessor :copyright
  attr_accessor :note_citation_record

  ClassTracker <<  :Copyright_record

  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:cont, "COPR", :copyright] ]
    @sub_level =  [ #level + 1
                    [:walk, nil, :note_citation_record], #to allow for user defined subtags
                  ]
  end
  
end
