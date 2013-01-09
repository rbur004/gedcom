require 'gedcom_base.rb'

#GEDCOM 5.5.1 Draft adds as subordinate to NAME
#
#    +1 FONE <NAME_PHONETIC_VARIATION>
#      +2 TYPE <PHONETIC_TYPE>
#      +2 <<PERSONAL_NAME_PIECES>> 
#
#==NAME_PHONETIC_VARIATION:=                                               {Size=1:120}
#  PHONETIC_TYPE [<user defined> | hangul | kana]                        {Size=5:30}
#The phonetic variation of the name is written in the same form as the was the name used in the superior <NAME_PERSONAL> primitive,
# but phonetically written using the method indicated by the subordinate <PHONETIC_TYPE> value, for example if hiragana was used 
#to provide a reading of a name written in kanji, then the <PHONETIC_TYPE> value would indicate 'kana'. 
#

class Name_phonetic_record < GEDCOMBase
  #Phonetic Name is stored in phonetic_name and recovered via def name, or the alias phonetic_name
  attr_writer :phonetic_name
  attr_accessor :prefix, :given, :nickname, :surname_prefix, :surname, :suffix
  attr_accessor :restriction, :source_citation_record, :note_citation_record
  ClassTracker <<  :Name_phonetic_record
  
  def initialize(*a)
    super(*a)
     @this_level = [ [:print, "FONE", :phonetic_name] ]
     @sub_level = [
                       [:print, "NPFX",    :prefix ],
                       [:print, "GIVN",    :given ],
                       [:print, "NICK",    :nickname ],
                       [:print, "SPFX",    :surname_prefix ],
                       [:print, "SURN",    :surname ],
                       [:print, "NSFX",    :suffix ],
                       [:walk, nil,    :source_citation_record],
                       [:walk, nil,    :note_citation_record],
                       [:print, "RESN", :restriction],
                   ] 
  end
  
  #return the name as a string. It might be returned be the #phonetic_name method.
  # or it might need to be contructed from the Name_phonetic_record personal name pieces attributes. 
  def name
    if (name = phonetic_name) == nil
      name = "" #could be what we return if none of the Name_record attributes are set
      if @prefix
        name += @prefix.first
        name += ' ' if @given || @nickname || @surname_prefix || @surname || @suffix
      end
      if @given
        name += @given.first  
        name += ' ' if  @nickname || @surname_prefix || @surname || @suffix
      end
      if @nickname
        name += '(' + @nickname.first + ')'  
        name += ' ' if @surname_prefix || @surname || @suffix
      end
      if @surname_prefix
        name += @surname_prefix.first
        name += ' ' if  @surname || @suffix
      end
      if @surname
        name += ( '/' + @surname.first + '/' ) 
        name += ' ' if  @suffix
      end
      name += @suffix.first  if @suffix
    end
    return name.first
  end
  
  alias :phonetic_name :name
end
