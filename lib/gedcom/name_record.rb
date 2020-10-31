require 'gedcom_base.rb'
require 'individual_attribute_record.rb'

#Internal representation of the GEDCOM NAME record as described under PERSONAL_NAME_STRUCTURE
#This sub-classes Individual_attribute_record, which in turn sub-classes Event_record. This may
#seem odd, but they share most class attributes and event records can be attached to most attributes.
#
#=PERSONAL_NAME_STRUCTURE:=
#  n NAME <NAME_PERSONAL>                 {1:1}
#    +1 NPFX <NAME_PIECE_PREFIX>          {0:1}
#    +1 GIVN <NAME_PIECE_GIVEN>           {0:1}
#    +1 NICK <NAME_PIECE_NICKNAME>        {0:1}
#    +1 SPFX <NAME_PIECE_SURNAME_PREFIX   {0:1}
#    +1 SURN <NAME_PIECE_SURNAME>         {0:1}
#    +1 NSFX <NAME_PIECE_SUFFIX>          {0:1}
#    +1 <<SOURCE_CITATION>>               {0:M}
#    +1 <<NOTE_STRUCTURE>>                {0:M}
#
#  The name value is formed in the manner the name is normally spoken, with the given name and family
#   name (surname) separated by slashes (/). (See <NAME_PERSONAL>, page 45.) Based on the
#  dynamic nature or unknown compositions of naming conventions, it is difficult to provide more
#  detailed name piece structure to handle every case. The NPFX, GIVN, NICK, SPFX, SURN, and
#  NSFX tags are provided optionally for systems that cannot operate effectively with less structured
#  information. For current future compatibility, all systems must construct their names based on the
#  <NAME_PERSONAL> structure. Those using the optional name pieces should assume that few
#  systems will process them, and most will not provide the name pieces. Future GEDCOM releases
#  (6.0 and later) will likely apply a very different strategy to resolve this problem, possibly using a
#  sophisticated parser and a name-knowledge database.
#
#==NAME_PERSONAL:=                                                        {Size=1:120}
#  <TEXT> | /<TEXT>/ | <TEXT> /<TEXT>/ | /<TEXT>/ <TEXT> | <TEXT> /<TEXT>/ <TEXT>
#
#  The surname of an individual, if known, is enclosed between two slash (/) characters. The order of the
#  name parts should be the order that the person would, by custom of their culture, have used when
#  giving it to a recorder. Early versions of Personal Ancestral File and other products did not use the (R)
#  trailing slash when the surname was the last element of the name. If part of name is illegible, that part
#  is indicated by an ellipsis (...). Capitalize the name of a person or place in the conventional
#  manner-capitalize the first letter of each part and lowercase the other letters, unless conventional
#  usage is otherwise. For example: McMurray.
#  Examples:
#    1 NAME William Lee                 (given name only or surname not known)
#    1 NAME /Parry/                     (surname only)
#    1 NAME William Lee /Parry/
#    1 NAME William Lee /Mac Parry/     (both parts (Mac and Parry) are surname parts
#    1 NAME William /Lee/ Parry         (surname imbedded in the name string)
#    1 NAME William Lee /Pa.../
#    1 NAME /HU/ Pan                    (Surname before firstname)
#
#==NAME_PIECE:=                                                           {Size=1:90}
#  The piece of the name pertaining to the name part of interest. The surname part, the given name part,
#  the name prefix part, or the name suffix part.
#
#==NAME_PIECE_GIVEN:=                                                     {Size=1:120}
#  <NAME_PIECE> | <NAME_PIECE_GIVEN>, <NAME_PIECE>
#
#  Given name or earned name. Different given names are separated by a comma.
#
#==NAME_PIECE_NICKNAME:=                                                  {Size=1:30}
#  <NAME_PIECE> | <NAME_PIECE_NICKNAME>, <NAME_PIECE>
#  A descriptive or familiar name used in connection with one's proper name.
#
#==NAME_PIECE_PREFIX:=                                                    {Size=1:30}
#  <NAME_PIECE> | <NAME_PIECE_PREFIX>, <NAME_PIECE>
#
#  Non indexing name piece that appears preceding the given name and surname parts. Different name
#  prefix parts are separated by a comma.
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
#
#GEDCOM 5.5.1 Draft adds
#
#    +1 TYPE <NAME_TYPE> 
#    +1 FONE <NAME_PHONETIC_VARIATION>
#      +2 TYPE <PHONETIC_TYPE>
#      +2 <<PERSONAL_NAME_PIECES>> 
#    +1 ROMN <NAME_ROMANIZED_VARIATION>
#      +2 TYPE <ROMANIZED_TYPE> 
#      +2 <<PERSONAL_NAME_PIECES>>
#
#==NAME_TYPE:=	                                                         {Size=5:30} 
# [ aka | birth | immigrant | maiden | married | <user defined> ]
#Indicates the name type, for example the name issued or assumed as an immigrant.
#e.g. birth indicates name given on birth certificate.
#
#==NAME_PHONETIC_VARIATION:=                                               {Size=1:120}
#  PHONETIC_TYPE [<user defined> | hangul | kana]                        {Size=5:30}
#The phonetic variation of the name is written in the same form as the was the name used in the superior <NAME_PERSONAL> primitive,
# but phonetically written using the method indicated by the subordinate <PHONETIC_TYPE> value, for example if hiragana was used 
#to provide a reading of a name written in kanji, then the <PHONETIC_TYPE> value would indicate 'kana'. 
#
#==NAME_ROMANIZED_VARIATION:=	                                              {Size=1:120} 
#  ROMANIZED_TYPE [<user defined> | pinyin | romaji | wadegiles]            {Size=5:30}
#The romanized variation of the name is written in the same form prescribed for the name used in the superior <NAME_PERSONAL> context. 
#The method used to romanize the name is indicated by the line_value of the subordinate <ROMANIZED_TYPE>, for example 
#if romaji was used to provide a reading of a name written in kanji, then the ROMANIZED_TYPE subordinate to the ROMN tag 
#would indicate romaji.
#==TYPE:=
class Name_record < Individual_attribute_record
  #Name stored in field "value", as this is an individual_attribute_record subtype.
  #Value of attribute "type" is set to NAME
  attr_accessor :prefix, :given, :nickname, :surname_prefix, :surname, :suffix
  attr_accessor :name_type, :name_phonetic_record, :name_romanized_record #GEDCOM 5.5.1
  ClassTracker <<  :Name_record
  
  def initialize(*a)
    super(*a)
     @sub_level = [
                       [:print, "NPFX",    :prefix ],
                       [:print, "GIVN",    :given ],
                       [:print, "NICK",    :nickname ],
                       [:print, "SPFX",    :surname_prefix ],
                       [:print, "SURN",    :surname ],
                       [:print, "NSFX",    :suffix ],
                       [:print, "TYPE",    :name_type ], #5.5.1
                       [:walk,  "FONE",    :name_phonetic_record],
                       [:walk,  "ROMN",    :name_romanized_record],
                   ] + @sub_level
  end

  #Attributes and Events have a common class, as they are essentially identical.
  def event_tag(tag)
    case tag
    when "NAME" then tag
    else super(tag)
    end
  end
  
  #return the name as a string. It might be returned be the Individual_attribute_record#value method.
  # or it might need to be contructed from the Name_record attributes. 99.9999% of all GEDCOM I have
  # seen does not use the Name_record attributes, and if the do, they are required to fill in the name on the
  # NAME line (NAME_PERSONAL value), so the value should be set. This helps, as the ordering of the surname and
  # first names is not standard across all cultures.
  def name
    if (name = value) == nil
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
end

