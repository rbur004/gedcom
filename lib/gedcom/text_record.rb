require 'gedcom_base.rb'

#Internal representation of the GEDCOM TEXT record type.
#
#This tag is used in SOUR and SOUR.DATA records
#=TEXT
#  n  TEXT <TEXT_FROM_SOURCE>            {0:M}
#  +1 [CONC | CONT ] <TEXT_FROM_SOURCE>  {0:M}
#
#==TEXT_FROM_SOURCE:= {Size=1:248}
#  A verbatim copy of any description contained within the source. This indicates notes or text that are
#  actually contained in the source document, not the submitter's opinion about the source. This should
#  be, from the evidence point of view, "what the original record keeper said" as opposed to the
#  researcher's interpretation. The word TEXT, in this case, means from the text which appeared in the
#  source record including labels.
#

class Text_record < GEDCOMBase
  attr_accessor :text
  
  ClassTracker <<  :Text_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [:cont, "TEXT", :text] ]
    @sub_level =  [ #level + 1
                  ]
  end 
end

