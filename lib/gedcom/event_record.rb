require 'gedcom_base.rb'

#Event_record holds multiple GEDCOM event record types. The type being held in @event_type.
#
#The following are all events and are stored in an Event_record object with their Tag as the @event_type:
#
#=FAMILY_EVENT_STRUCTURE:=                      {0:M}
#  n [ ANUL | CENS | DIV | DIVF ] [Y|<NULL>]    {1:1}
#    +1 <<EVENT_DETAIL>>                        {0:1}
#  n [ ENGA | MARR | MARB | MARC ] [Y|<NULL>]   {1:1}
#    +1 <<EVENT_DETAIL>>                        {0:1}
#  n [ MARL | MARS ] [Y|<NULL>]                 {1:1}
#    +1 <<EVENT_DETAIL>>                        {0:1}
#  n EVEN                                       {1:1}
#    +1 <<EVENT_DETAIL>>                        {0:1}
#
#=INDIVIDUAL_EVENT_STRUCTURE:=
#  n [ BIRT | CHR ] [Y|<NULL>]                  {1:1}
#    +1 <<EVENT_DETAIL>>                        {0:1}
#    +1 FAMC @<XREF:FAM>@                       {0:1}
#  n [ DEAT | BURI | CREM ] [Y|<NULL>]          {1:1}
#    +1 <<EVENT_DETAIL>>                        {0:1}
#  n ADOP [Y|<NULL>]                            {1:1}
#    +1 <<EVENT_DETAIL>>                        {0:1}
#    +1 FAMC @<XREF:FAM>@                       {0:1}
#      +2 ADOP <ADOPTED_BY_WHICH_PARENT>        {0:1}
#  n [ BAPM | BARM | BASM | BLES ] [Y|<NULL>]   {1:1}
#    +1 <<EVENT_DETAIL>>                        {0:1}
#  n [ CHRA | CONF | FCOM | ORDN ] [Y|<NULL>]   {1:1}
#    +1 <<EVENT_DETAIL>>                        {0:1}
#  n [ NATU | EMIG | IMMI ] [Y|<NULL>]          {1:1}
#    +1 <<EVENT_DETAIL>>                        {0:1}
#  n [ CENS | PROB | WILL] [Y|<NULL>]           {1:1}
#    +1 <<EVENT_DETAIL>>                        {0:1}
#  n [ GRAD | RETI ] [Y|<NULL>]                 {1:1}
#    +1 <<EVENT_DETAIL>>                        {0:1}
#  n EVEN                                       {1:1}
#    +1 <<EVENT_DETAIL>>                        {0:1}
#
#=LDS_INDIVIDUAL_ORDINANCE:=                    {0:M}
#  n [ BAPL | CONL ]                            {1:1}
#    +1 STAT <LDS_BAPTISM_DATE_STATUS>          {0:1}
#    +1 DATE <DATE_LDS_ORD>                     {0:1}
#    +1 TEMP <TEMPLE_CODE>                      {0:1}
#    +1 PLAC <PLACE_LIVING_ORDINANCE>           {0:1}
#    +1 <<SOURCE_CITATION>>                     {0:M}
#    +1 <<NOTE_STRUCTURE>>                      {0:M}
#  n ENDL {1:1}
#    +1 STAT <LDS_ENDOWMENT_DATE_STATUS>        {0:1}
#    +1 DATE <DATE_LDS_ORD>                     {0:1}
#    +1 TEMP <TEMPLE_CODE>                      {0:1}
#    +1 PLAC <PLACE_LIVING_ORDINANCE>           {0:1}
#    +1 <<SOURCE_CITATION>>                     {0:M}
#    +1 <<NOTE_STRUCTURE>>                      {0:M}
#  n SLGC {1:1}
#    +1 STAT <LDS_CHILD_SEALING_DATE_STATUS>    {0:1}
#    +1 DATE <DATE_LDS_ORD>                     {0:1}
#    +1 TEMP <TEMPLE_CODE>                      {0:1}
#    +1 PLAC <PLACE_LIVING_ORDINANCE>           {0:1}
#    +1 FAMC @<XREF:FAM>@                       {1:1}
#    +1 <<SOURCE_CITATION>>                     {0:M}
#    +1 <<NOTE_STRUCTURE>>                      {0:M}
#
#=LDS_SPOUSE_SEALING:=
#  n SLGS {1:1}
#    +1 STAT <LDS_SPOUSE_SEALING_DATE_STATUS>   {0:1}
#    +1 DATE <DATE_LDS_ORD>                     {0:1}
#    +1 TEMP <TEMPLE_CODE>                      {0:1}
#    +1 PLAC <PLACE_LIVING_ORDINANCE>           {0:1}
#    +1 <<SOURCE_CITATION>>                     {0:M}
#    +1 <<NOTE_STRUCTURE>>                      {0:M}
#
#  The EVEN tag in this structure is for recording general events or attributes that are not shown in the
#  above <<INDIVIDUAL_EVENT_STRUCTURE>>. The general event or attribute type is declared
#  by using a subordinate TYPE tag to show what event or attribute is recorded. For example, a
#  candidate for state senate in the 1952 election could be recorded:
#    1 EVEN
#      2 TYPE Election
#      2 DATE 07 NOV 1952
#      2 NOTE Candidate for State Senate.
#
#  The TYPE tag is also optionally used to modify the basic understanding of its superior event and is
#  usually provided by the user. For example:
#    1 ORDN
#      2 TYPE Deacon
#
#  The presence of a DATE tag and/or PLACe tag makes the assertion of when and/or where the event
#  took place, and therefore that the event did happen. The absence of both of these tags require a
#  Y(es) value on the parent TAG line to assert that the event happened. Using this convention protects
#  GEDCOM processors which may remove (prune) lines that have no value and no subordinate lines.
#  It also allows a note or source to be attached to the event context without implying that the event
#  occurred.
#
#  It is not proper to use a N(o) value with an event tag to infer that it did not happen. Inferring that an
#  event did not occur would require a different tag. A symbol such as using an exclamation mark (!)
#  preceding an event tag to indicate an event is known not to have happened may be defined in the future.
#
#=EVENT_DETAIL:= (These all get included in the Event_record as attributes)
#  n TYPE <EVENT_DESCRIPTOR>                {0:1}
#  n DATE <DATE_VALUE>                      {0:1}
#  n <<PLACE_STRUCTURE>>                    {0:1}
#  n <<ADDRESS_STRUCTURE>>                  {0:1}
#  n AGE <AGE_AT_EVENT>                     {0:1}
#  n AGNC <RESPONSIBLE_AGENCY>              {0:1}
#  n CAUS <CAUSE_OF_EVENT>                  {0:1}
#  n <<SOURCE_CITATION>>                    {0:M}
#  n <<MULTIMEDIA_LINK>>                    {0:M}
#  n <<NOTE_STRUCTURE>>                     {0:M}
#
#==AGE_AT_EVENT:=                                               {Size=1:12}
#  [ < | > | <NULL>] YYy MMm DDDd | YYy | MMm | DDDd | YYy MMm | YYy DDDd | MMm DDDd | CHILD | INFANT | STILLBORN
#
#  Where:
#    >::         greater than indicated age
#    <::         less than indicated age
#    y::         a label indicating years
#    m::         a label indicating months
#    d::         a label indicating days
#    YY::        number of full years
#    MM::        number of months
#    DDD::       number of days
#    CHILD::     age < 8 years
#    INFANT::    age < 1 year
#    STILLBORN:: died just prior, at, or near birth, 0 years
#
#  A number that indicates the age in years, months, and days that the principal was at the time of the
#  associated event. Any labels must come after their corresponding number, for example; 4y 8m 10d.
#
#==EVENT_DESCRIPTOR:=                                           {Size=1:90}
#  A descriptor that should be used whenever the EVEN tag is used to define the event being cited. For
#  example, if the event was a purchase of a residence, the EVEN tag would be followed by a
#  subordinate TYPE tag with the value "Purchased Residence." Using this descriptor with any of the
#  other defined event tags basically classifies the basic definition of the associated tag but does not
#  change its basic process. The form of using the TYPE tag with defined event tags has not been used
#  by very many products. The MARR tag could be subordinated with a TYPE tag and
#  EVENT_DESCRIPTOR value of Common Law. Other possible descriptor values might include
#  "Childbirth—unmarried," "Common Law," or "Tribal Custom," for example. The event descriptor
#  should use the same word or phrase and in the same language, when possible, as was used by the
#  recorder of the event. Systems that display data from the GEDCOM form should be able to display the
#  descriptor value in their screen or printed output.
#
#==RESPONSIBLE_AGENCY:=                                         {Size=1:120}
#  The organization, institution, corporation, person, or other entity that has authority or control
#  interests in the associated context. For example, an employer of a person of an associated occupation,
#  or a church that administered rites or events, or an organization responsible for creating and/or
#  archiving records.
#
#==CAUSE_OF_EVENT:=                                             {Size=1:90}
#  Used in special cases to record the reasons which precipitated an event. Normally this will be used
#  subordinate to a death event to show cause of death, such as might be listed on a death certificate.
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
class Event_record < GEDCOMBase
  attr_accessor :restriction #not standard at the event level, but we might want this in DB.
  attr_accessor :event_type, :event_descriptor
  attr_accessor :event_status, :date_record, :phonenumber, :place_record, :address_record, :age
  attr_accessor :agency, :cause_record, :source_citation_record, :submitter_ref
  attr_accessor :multimedia_citation_record, :note_citation_record, :event_age_record, :adoption_record
  attr_accessor :lds_temp_code, :lds_date_status, :lds_slgc_family_ref

  ClassTracker <<  :Event_record
  
  def initialize(*a)
    super(*a)
    @sub_level = [ #level + 1
                    [:print, "RESN", :restriction],
                    [:print, "TYPE", :event_descriptor],
                    [:print, "STAT", :lds_date_status],
                    [:walk, nil,  :cause_record],
                    [:walk, nil, :date_record],
                    [:print,  "TEMP", :lds_temp_code],
                    [:walk, nil, :place_record],
                    [:walk, nil, :address_record],
                    [:print, "PHON", :phonenumber],
                    [:print, "AGE", :age],
                    [:walk, nil,  :event_age_record],
                    [:print, "AGNC", :agency],
                    [:walk, nil,   :multimedia_citation_record],
                    [:walk, nil,   :source_citation_record],
                    [:walk, nil, :note_citation_record],
                    [:xref, "SUBM", :submitter_ref],
                    [:walk, nil, :adoption_record],
                    [:xref, "FAMC",  :lds_slgc_family_ref],
                  ]
  end
      
  def to_gedcom(level=0)
    tag = event_tag(@event_type[0].to_s)
    
#    print "'#{@event_type}' '#{@event_descriptor}' => #{tag}\n"
    if @event_status != nil && @event_status[0] != nil && @event_status[0][0]  != nil
      @this_level = [ [:print, tag, :event_status] ]
    else
      @this_level = [ [:nodata, tag, nil] ]
    end
    super(level)
  end
  
  def event_tag(tag)
    case tag
    when "ANUL" then tag
    when "CENS" then tag
    when "DIV" then tag
    when "DIVF" then tag
    when "ENGA" then tag
    when "MARR" then tag
    when "MARB" then tag
    when "MARC" then tag
    when "MARL" then tag
    when "MARS" then tag
    when "EVEN" then tag
    when "RESI" then tag
    when "SLGS" then tag
    when "BIRT" then tag
    when "CHR" then tag
    when "ADOP" then tag
    when "DEAT" then tag
    when "BURI" then tag
    when "CREM" then tag
    when "BAPM" then tag
    when "BARM" then tag
    when "BASM" then tag
    when "BLES" then tag
    when "CHRA" then tag
    when "CONF" then tag
    when "FCOM" then tag
    when "ORDN" then tag
    when "NATU" then tag
    when "EMIG" then tag
    when "IMMI" then tag
    when "CENS" then tag
    when "PROB" then tag
    when "WILL" then tag
    when "GRAD" then tag
    when "RETI" then tag
    when "BAPL" then tag
    when "CONL" then tag
    when "ENDL" then tag
    when "SLGC" then tag
    else          "EVEN"
    end
  end
  
  def is_event?(tag)
    @event_type.first.to_s == tag #all attributes are arrays, even the single value ones.
  end
  
  def date
    if @date_record != nil
      @date_record.first.date
    else
      nil
    end
  end
  
  #where the event took place. We are reporting only the first place as a string. If you want all the places recorded,
  #then you should access Event_record#place_record, which will return an array of PLAC records in the event. 
  def place
    if @place_record != nil
      @place_record.first.place
    else
      nil
    end
  end
end
