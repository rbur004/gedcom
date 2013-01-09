require 'gedcom_base.rb'

#GEDCOM 5.5.1 Draft adds as subordinate to NAME
#
#    +1 ROMN <NAME_ROMANIZED_VARIATION>
#      +2 TYPE <ROMANIZED_TYPE> 
#      +2 <<PERSONAL_NAME_PIECES>>
#
#
#
#==NAME_ROMANIZED_VARIATION:=	                                              {Size=1:120} 
#  ROMANIZED_TYPE [<user defined> | pinyin | romaji | wadegiles]            {Size=5:30}
#The romanized variation of the name is written in the same form prescribed for the name used in the superior <NAME_PERSONAL> context. 
#The method used to romanize the name is indicated by the line_value of the subordinate <ROMANIZED_TYPE>, for example 
#if romaji was used to provide a reading of a name written in kanji, then the ROMANIZED_TYPE subordinate to the ROMN tag 
#would indicate romaji.

class Name_romanized_record < GEDCOMBase
  #romanized Name is stored in romanized_name and recovered via def name, or the alias romanized_name
  attr_writer :romanized_name
  attr_accessor :prefix, :given, :nickname, :surname_prefix, :surname, :suffix
  attr_accessor :restriction, :source_citation_record, :note_citation_record
  ClassTracker <<  :Name_romanized_record
  
  def initialize(*a)
    super(*a)
    @this_level = [ [:print, "ROMN", :romanized_name] ]
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
  
  #return the name as a string. It might be returned be the romanized_name method.
  # or it might need to be contructed from the Name_romanized_record personal name pieces attributes. 
  def name
    if (name = romanized_name) == nil
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
  
  alias :romanized_name :name
end
