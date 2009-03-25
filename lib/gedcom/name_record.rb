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
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
class Name_record < Individual_attribute_record
  attr_accessor :prefix, :given, :nickname, :surname_prefix, :surname, :suffix
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
                   ] + @sub_level
  end

  def event_tag(tag)
    case tag
    when "NAME" then tag
    else super(tag)
    end
  end
  
end

