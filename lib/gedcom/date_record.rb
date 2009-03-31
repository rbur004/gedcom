require 'gedcom_base.rb'

#Dates are stored here. In GEDCOM, they have to have the flexibility to hold
#multiple data formats, both current and historical. Dates can be strings or
#can have structure. At the moment, this class just stores them as strings,
#with an optional TIME information.
#
#=DATE:=                                            {Size=4:35}
#  [<DATE_CALENDAR_ESCAPE> | <NULL>] <DATE_CALENDAR>
#
#==DATE_CALENDAR_ESCAPE:=                              {Size=4:15}
#  @#DHEBREW@ | @#DROMAN@ | @#DFRENCH R@ | @#DGREGORIAN@ | @#DJULIAN@ | @#DUNKNOWN@
#
#  The date escape determines the date interpretation by signifying which <DATE_CALENDAR> to use.
#  The default calendar is the Gregorian calendar.
#
#==DATE_CALENDAR:=                                     {Size=4:35}
#  <DATE_GREG> | <DATE_JULN> | <DATE_HEBR> | <DATE_FREN> | <DATE_FUTURE>
#
#  The selection is based on the <DATE_CALENDAR_ESCAPE> that precedes the
#  <DATE_CALENDAR> value immediately to the left. If <DATE_CALENDAR_ESCAPE> doesn't
#  appear at this point, then @#DGREGORIAN@ is assumed. No future calendar types will use words
#  (e.g., month names) from this list: FROM, TO, BEF, AFT, BET, AND, ABT, EST, CAL, or INT.
#  When only a day and month appears as a DATE value it is considered a date phrase and not a valid
#  date form.
#
#  Date Escape         Syntax Selected
#  -----------         -------------
#  @#DGREGORIAN@       <DATE_GREG>
#  @#DJULIAN@          <DATE_JULN>
#  @#DHEBREW@          <DATE_HEBR>
#  @#DFRENCH R@        <DATE_FREN>
#  @#DROMAN@           for future definition
#  @#DUNKNOWN@         calendar not known
#
#==DATE_APPROXIMATED:=                               {Size=4:35}
#  ABT <DATE> | CAL <DATE> | EST <DATE>
# 
#  Where:
#  ABT:: About, meaning the date is not exact.
#  CAL:: Calculated mathematically, for example, from an event date and age.
#  EST:: Estimated based on an algorithm using some other event date.
#
#==DATE_EXACT:= {Size=10:11}
#  <DAY> <MONTH> <YEAR_GREG>
#
#==DATE_FREN:= {Size=4:35}
#  <YEAR> | <MONTH_FREN> <YEAR> | <DAY> <MONTH_FREN> <YEAR>
#===MONTH_FREN:=                                     {Size=4}
#  VEND | BRUM | FRIM | NIVO | PLUV | VENT | GERM | FLOR | PRAI | MESS | THER | FRUC | COMP
#  Where:
#    VEND:: VENDEMIAIRE
#    BRUM:: BRUMAIRE
#    FRIM:: FRIMAIRE
#    NIVO:: NIVOSE
#    PLUV:: PLUVIOSE
#    VENT:: VENTOSE
#    GERM:: GERMINAL
#    FLOR:: FLOREAL
#    PRAI:: PRAIRIAL
#    MESS:: MESSIDOR
#    THER:; THERMIDOR
#    FRUC:: FRUCTIDOR
#    COMP:: JOUR_COMPLEMENTAIRS
#
#==DATE_GREG:= {Size=4:35}
#  <YEAR_GREG> | <MONTH> <YEAR_GREG> | <DAY> <MONTH> <YEAR_GREG>
#===YEAR_GREG:= {Size=3:7}
#  [ <NUMBER> | <NUMBER>/<DIGIT><DIGIT> ]
#
#  The slash "/" <DIGIT><DIGIT> a year modifier which shows the possible date alternatives for pre-
#  1752 date brought about by a changing the beginning of the year from MAR to JAN in the English
#  calendar change of 1752, for example, 15 APR 1699/00. A (B.C.) appended to the <YEAR> indicates
#  a date before the birth of Christ.
#
#
#==DATE_HEBR:= {Size=4:35}
#  <YEAR> | <MONTH_HEBR> <YEAR> | <DAY> <MONTH_HEBR> <YEAR>
#===MONTH_HEBR:=                                     {Size=3}
#  TSH | CSH | KSL | TVT | SHV | ADR | ADS | NSN | IYR | SVN | TMZ | AAV | ELL
#  Where:
#    TSH:: Tishri
#    CSH:: Cheshvan
#    KSL:: Kislev
#    TVT:: Tevet
#    SHV:: Shevat
#    ADR:: Adar
#    ADS:: Adar Sheni
#    NSN:: Nisan
#    IYR:: Iyar
#    SVN:: Sivan
#    TMZ:: Tammuz
#    AAV:: Av
#    ELL:: Elul
#
#==DATE_JULN:=                                         {Size=4:35}
#  <YEAR> | <MONTH> <YEAR> | <DAY> <MONTH> <YEAR>
#===MONTH:=                                          {Size=3}
#  JAN | FEB | MAR | APR | MAY | JUN | JUL | AUG | SEP | OCT | NOV | DEC
#  Where:
#    JAN:: January
#    FEB:: February
#    MAR:: March
#    APR:: April
#    MAY:: May
#    JUN:: June
#    JUL:: July
#    AUG:: August
#    SEP:: September
#    OCT:: October
#    NOV:: November
#    DEC:: December
#
#==DATE_PERIOD:=                                         {Size=7:35}
#  FROM <DATE> | TO <DATE> | FROM <DATE> TO <DATE>
# 
#  Where:
#  FROM:: Indicates the beginning of a happening or state.
#  TO::   Indicates the ending of a happening or state.
#
#  Examples:
#  FROM 1904 to 1915
#    The state of some attribute existed from 1904 to 1915 inclusive.
#  FROM 1904
#    The state of the attribute began in 1904 but the end date is unknown.
#  TO 1915
#    The state ended in 1915 but the begin date is unknown.
# 
#==DATE_PHRASE:=                                         {Size=1:35}
#  (<TEXT>)
#
#  Any statement offered as a date when the year is not recognizable to a date parser, but which gives
#  information about when an event occurred. The date phrase is enclosed in matching parentheses.
# 
#==DATE_RANGE:=                                          {Size=8:35}
#  BEF <DATE> | AFT <DATE> | BET <DATE> AND <DATE>
#  
#  Where:
#  AFT:: Event happened after the given date.
#  BEF:: Event happened before the given date.
#  BET:: Event happened some time between date 1 AND date 2. For example, bet 1904 and 1915
#        indicates that the event state (perhaps a single day) existed somewhere between 1904 and
#        1915 inclusive.
#
#  The date range differs from the date period in that the date range is an estimate that an event happened
#  on a single date somewhere in the date range specified.
#
#  The following are equivalent and interchangeable:
#  Short form       Long Form
#  ---------—       ---------—-
#  1852             BET 1 JAN 1852 AND 31 DEC 1852
#  1852             BET 1 JAN 1852 AND DEC 1852
#  1852             BET JAN 1852 AND 31 DEC 1852
#  1852             BET JAN 1852 AND DEC 1852
#  JAN 1920         BET 1 JAN 1920 AND 31 JAN 1920
#
#==DATE_VALUE:=                                       {Size=1:35}
#  <DATE> | <DATE_PERIOD> | <DATE_RANGE> | <DATE_APPROXIMATED> | INT <DATE> (<DATE_PHRASE>) | (<DATE_PHRASE>)
# 
#  The DATE_VALUE represents the date of an activity, attribute, or event where:
#  INT:: Interpreted from knowledge about the associated date phrase included in parentheses.
#
#  An acceptable alternative to the date phrase choice is to use one of the other choices such as
#  <DATE_APPROXIMATED> choice as the DATE line value and then include the
#  <DATE_PHRASE> as a NOTE value subordinate to the DATE line.
#
#  The date value can take on the date form of just a date, an approximated date, between a date and
#  another date, and from one date to another date. The preferred form of showing date imprecision, is
#  to show, for example, MAY 1890 rather than ABT 12 MAY 1890. This is because limits have not
#  been assigned to the precision of the prefixes such as ABT or EST.
#
#==DAY:=                                                 {Size=1:2}
#  dd
#
#  Day of the month, where dd is a numeric digit whose value is within the valid range of the days for the
#  associated calendar month.
#
#=TIME_VALUE:= {Size=1:12}
#  [ hh:mm:ss.fs ]
#
#  The time of a specific event, usually a computer-timed event, where:
#    hh:: hours on a 24-hour clock
#    mm:: minutes
#    ss:: seconds (optional)
#    fs:: decimal fraction of a second (optional)
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
class Date_record < GEDCOMBase
  attr_accessor :date_value, :time_value, :source_citation_record, :note_citation_record

  ClassTracker <<  :Date_record
  
  #new sets up the state engine arrays @this_level and @sub_level, which drive the to_gedcom method generating GEDCOM output.
  def initialize(*a)
    super(*a)
    @this_level = [ [ :date, "DATE", :date_value ] ]
    @sub_level =  [ #level + 1
                    [ :time, "TIME", :time_value],
                    [ :walk, nil, :source_citation_record],
                    [ :walk,  nil, :note_citation_record]
                  ]
  end
  
  #If you want just one date, then this returns the first DATE record (probably the only one).
  #GEDCOM says that this should be the most vaild record. If you need all the dates, use date_value,
  #which will give you an array of DATE values.
  def date
    if @date_value
      @date_value.first
    else
      ''
    end
  end

  #If you want just one date, then this returns the first TIME record (probably the only one).
  #GEDCOM says that this should be the most vaild record. If you need all the dates, use date_value,
  #which will give you an array of TIME values.
  def time
    @time_value.first
  end
end
