require 'gedcom_base.rb'
require 'individual_attribute_record.rb'

#Internal representation of the GEDCOM NAME record as described under PERSONAL_NAME_STRUCTURE:=
#
#The attributes are all arrays, thus allowing multiple GEDCOM tags of the same type.
#Name_record is a subclass of Individual_attribute_record, which includes many other attributes. 
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

