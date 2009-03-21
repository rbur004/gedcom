require 'gedcom_base.rb'
require 'event_record.rb'

class Individual_attribute_record < Event_record

  ClassTracker <<  :Individual_attribute_record
  
  def initialize(*a)
    super(*a)
  end

  def attr_type=(value)
    @event_type = value
  end
  def attr_type
    @event_type
  end
  def value=(value)
    @event_status = value
  end
  def value
    @event_status
  end

  def event_tag(tag)
    case tag
    when "SEX" then tag
    when "CAST" then tag
    when "DSCR" then tag
    when "EDUC" then tag
    when "IDNO" then tag
    when "NATI" then tag
    when "NCHI" then tag
    when "NMR"  then tag
    when "OCCU" then tag
    when "PROP" then tag
    when "RELI" then tag
    when "RESI" then tag
    when "SSN"  then tag
    when "TITL" then tag
    else super(tag)
    end
  end
end
