require 'gedcom_base.rb'
require 'event_record.rb'

#Internal representation of the GEDCOM Individual_Attribute_Structure.
#Individual_attribute_record subclasses Event_record, as they share the same class attributes as events.
#
#=INDIVIDUAL_ATTRIBUTE_STRUCTURE:=      {0:M} Note that this structure can occur many times an Individual_record.
#  n SEX <SEX_VALUE>                    {0:1}
#    +1 <<EVENT_DETAIL>>                {0:1}
#  n CAST <CASTE_NAME>                  {1:1}
#    +1 <<EVENT_DETAIL>>                {0:1}
#  n DSCR <PHYSICAL_DESCRIPTION>        {1:1}
#    +1 <<EVENT_DETAIL>>                {0:1}
#  n EDUC <SCHOLASTIC_ACHIEVEMENT>      {1:1}
#    +1 <<EVENT_DETAIL>>                {0:1}
#  n IDNO <NATIONAL_ID_NUMBER>          {1:1}
#    +1 <<EVENT_DETAIL>>                {0:1}
#  n NATI <NATIONAL_OR_TRIBAL_ORIGIN>   {1:1}
#    +1 <<EVENT_DETAIL>>                {0:1}
#  n NCHI <COUNT_OF_CHILDREN>           {1:1}
#    +1 <<EVENT_DETAIL>>                {0:1}
#  n NMR <COUNT_OF_MARRIAGES>           {1:1}
#    +1 <<EVENT_DETAIL>>                {0:1}
#  n OCCU <OCCUPATION>                  {1:1}
#    +1 <<EVENT_DETAIL>>                {0:1}
#  n PROP <POSSESSIONS>                 {1:1}
#    +1 <<EVENT_DETAIL>>                {0:1}
#  n RELI <RELIGIOUS_AFFILIATION>       {1:1}
#    +1 <<EVENT_DETAIL>>                {0:1}
#  n RESI                               {1:1}
#    +1 <<EVENT_DETAIL>>                {0:1}
#  n SSN <SOCIAL_SECURITY_NUMBER>       {0:1}
#    +1 <<EVENT_DETAIL>>                {0:1}
#  n TITL <NOBILITY_TYPE_TITLE>         {1:1}
#    +1 <<EVENT_DETAIL>>                {0:1}
# 
#  Note:: The usage of IDNO requires that the subordinate TYPE tag be used to define what kind of
#         number is assigned to IDNO.
#
#  Also Note that SEX has been added here, and removed from the Individual_record. This allows SEX
#  To be included multiple times, and have associated events (e.g. a sex change). I also do not check
#  That the SEX_VALUE is M,F or U. to allow for the XXY, XXXY and X and other genetic anomolies 
#  associated with gender that might need to be recorded. None of this affects reading GEDCOM files,
#  and will not affect the writing of them if you don't add an event, or use non-standard SEX_VALUEs.
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
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
