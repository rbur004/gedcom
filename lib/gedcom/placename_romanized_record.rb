require 'gedcom_base.rb'

#GEDCOM 5.5.1 Draft adds as subordinate to PLAC
#
#  +1 ROMN <PLACE_ROMANIZED_VARIATION>
#    +2 TYPE <PHONETIC_TYPE>
#
#==PLACE_ROMANIZED_VARIATION:=                                               {Size=1:120}
#  ROMANIZED_TYPE [<user defined> | pinyin | romaji | wadegiles ]            {Size=5:30}
#The romanized variation of the place name is written in the same form prescribed for the place name used 
#in the superior <PLACE_NAME> context. The method used to romanize the name is indicated by the line_value of 
#the subordinate <ROMANIZED_TYPE>, for example if romaji was used to provide a reading of a place name written 
#in kanji, then the <ROMANIZED_TYPE> subordinate to the ROMN tag would indicate romaji.  
#
#I allow a NOTE record too, to cope with user defined tags

class Placename_romanized_record < GEDCOMBase
  attr_accessor :romanized_name, :romanized_type
  attr_accessor :note_citation_record
  ClassTracker <<  :Placename_romanized_record
  
  def initialize(*a)
    super(*a)
    @this_level = [ [:print, "ROMN", :romanized_name] ]
     @sub_level = [
                       [:print, "TYPE", :romanized_type],
                       [:walk, nil,    :note_citation_record],
                   ] 
  end
end