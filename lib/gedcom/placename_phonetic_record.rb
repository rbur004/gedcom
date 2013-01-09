require 'gedcom_base.rb'

#GEDCOM 5.5.1 Draft adds as subordinate to PLAC
#
#    +1 FONE <PLACE_PHONETIC_VARIATION>
#      +2 TYPE <PHONETIC_TYPE>
#
#==PLACE_PHONETIC_VARIATION:=                                               {Size=1:120}
#  PHONETIC_TYPE [<user defined> | hangul | kana]                           {Size=5:30}
#The phonetic variation of the place name is written in the same form as was the place name used in the superior 
#<PLACE_NAME> primitive, but phonetically written using the method indicated by the subordinate <PHONETIC_TYPE> value, 
#for example if hiragana was used to provide a reading of a a name written in kanji, then the <PHONETIC_TYPE> value 
#would indicate kana. 
#
#I allow a NOTE record too, to cope with user defined tags

class Placename_phonetic_record < GEDCOMBase
  attr_accessor :phonetic_name, :phonetic_type
  attr_accessor :note_citation_record
  ClassTracker <<  :Placename_phonetic_record
  
  def initialize(*a)
    super(*a)
    @this_level = [ [:print, "FONE", :phonetic_name] ]
     @sub_level = [
                       [:print, "TYPE", :phonetic_type],
                       [:walk, nil,    :note_citation_record],
                   ] 
  end
end
