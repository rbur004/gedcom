require 'gedcom_base.rb'
require 'individual_attribute_record.rb'

class Name_record < Individual_attribute_record
  attr_accessor :prefix, :given, :nickname, :surname_prefix, :surname, :suffix
  ClassTracker <<  :Name_record
  
  def initialize
    super
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

