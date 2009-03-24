require 'gedcom_base.rb'
require 'event_record.rb'

#Internal representation of the GEDCOM SEX, CAST, DSCR, EDUC, IDNO, NATI, NCHI, NMR, OCCU, PROP, RELI, RESI, SSN and TITL record types
#Individual_attribute_record subclasses Event_record, as they share the same class attributes as events.
#
#The attributes are all arrays. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in these record types.
class Individual_attribute_record < Event_record

  ClassTracker <<  :Individual_attribute_record
  
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
