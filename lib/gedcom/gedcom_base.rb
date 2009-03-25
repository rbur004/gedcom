require "class_tracker.rb"
require "instruction.rb"

#base routines shared by all gedcom objects.
class GEDCOMBase
  attr_accessor  :class_stack, :indexes
  @@tabs = false #If true, indent gedcom lines on output a tab per level. Normally wouldn't have tabs in a transmission file.

  #Create a new GEDCOMBase or most likely a subclass of GEDCOMBase.
  #* transmission is the current transmission this object came from.
  #  This is useful in searchs of the transmission, starting from a reference in a record in that transmission.
  #* changed indicates that we have altered the data in the record
  #  The default is true, as the normal instantiation is creating a new record.
  #  to_db uses this to determine if the record needs to be saved to the DB.
  #* created indicates that this is a new record, rather than one we may have loaded from a DB.
  def initialize(transmission = nil, changed=true,created=true)
    @changed = changed
    @created = created
    @this_level = []
    @sub_level = []
    @transmission = transmission
  end
  
  #sets @@tabs to true.
  #This indents gedcom lines on output a tab per level. 
  #This is useful if pretty printing, but not normal in a gedcom file 
  #as most GEDCOM file parsers don't like leading tabs on lines of a transmission file.
  #I use this only for debugging.
  def self.tabs
    @@tabs = true 
  end
  
  #sets @@tabs to false.
  #This is the default as a lot of GEDCOM parsers don't like leading white space on lines.
  def self.no_tabs
    @@tabs = false #The default
  end
  
  #Marks this object as having been altered so we know to synchronise it with the DB.
  def changed
    @changed = true
  end
  
  #Tests for this object having been altered, so we know to synchronise it with the DB.
  def changed?
    @changed
  end
  
  #Tests to see if this is a new object, not one we have loaded from elsewhere (say a DB)
  def created?
    @created
  end
  
  #create a string from the objects instance variables, one per line, in the form "variable = value\n" ... .
  #For an ordered list, see to_s_ordered
  def to_s
    s = ''
    self.instance_variables.each do |v| #look at each of the instance variables
      if self.class.method_defined?(v_sym = v[1..-1].to_sym) #see if there is a method defined for this symbol (strip the :)
        s += "#{v} = " + pv_byname(v_sym) + "\n" #print it
      end
    end
    s
  end
  
  #Need to flesh this out. Right now it pretends to work and marks records as saved.
  def to_db(level = 0, this_level=[], sub_levels=[])
    @changed = false
    @created = false
  end
  
  #This is the default method, used by all classes inheriting from GEDCOMBase, to recursively generate GEDCOM lines from that Object downward.
  #All subclasses of GEDCOMBase are expected to define @this_level and @sub_level arrays, which are instructions to to_s_r on how to generate
  #GEDCOM lines from the attributes of the object. 
  def to_gedcom(level = 0)
    to_s_r( level, @this_level, @sub_level )
  end
  
  #This is the default method, used by all classes inheriting from GEDCOMBase, to recursively save the object and its sub-records to a DB.
  #All subclasses of GEDCOMBase are expected to define @this_level and @sub_level arrays, which are instructions to to_db on how to generate
  #GEDCOM lines from the attributes of the object. 
  def save
    to_db( level, @this_level, @sub_level)
  end
  
  private
  
  #Somewhat cryptic. This takes the symbol (variable name) and returns the object associatied with it.
  def pv_byname(v_sym, indent = 0)
    a = self.send( v_sym )
    pv(a)
  end
  
  #return a string of ',' separated values stored in the object in the variable v.
  def pv(v)
    s = ''
    if v == nil #nil object
      s += 'nil'
    elsif v.class == Array #object is an Array, so enumerate each to get each value (with recursive call).
      s += "[\n"
      s += v.inject('') { |x,y| x + pv(y) + ',' }
      s[-1,1] = "\n"
      s += "]"
      s
    else #object is singular, so return its to_s value if it has one.
      if x = v.to_s
        s += x
      else
        s += 'nil'
      end
    end
  end
  
  #Return and empty string unless @@tabs is true.
  #Returns a string of tabs (actually of pairs of spaces), one pair per GEDCOM level.
  #Used to indent GEDCOM output for pretty printing.
  def tabstop(level) 
    #printing aid for indenting each level
    return "" if !@@tabs || level <= 0
    '  ' * level
  end
  
  #Returns a GEDCOM line, with optional leading tabs.
  def single_line(level, tag, data = nil)
    #printing aid for tags that can have CONT or CONC sub-tags
    s_out = "#{tabstop(level)}#{level} #{tag}"
    if data != nil
      data.each do |word|
        if word != "\n"
          s_out +=  " #{word}"
        end
      end
    end
    s_out +=  "\n"
  end
  
  #Returns a GEDCOM line for this tag, with CONC lines if the length 
  #of a line exceeds the GEDCOM standard line length.
  #Recognises '\n' chars in the data and creates a CONT line after the '\n'
  #Recognised @@tab to indent lines if pretty printing the output.
  #Nb. Lots of GEDCOM files ignore the line lengths in the standard, so this
  #method can created extra CONC lines in the output if a transmission is read
  #then dumped again.
  #The standard says that 
  #* Leading white space should be ignored, though a lot of systems can't cope with leading white space.
  #* levels can be up to 2 digits (i.e. up to 99). 0 - 9 should not have a leading 0.
  #* XREFs can be 20 chars plus 2 for the enclosing '@'s
  #* GEDCOM tags can be 31 chars (though only 15 matter). No tag in the standard is bigger than 4 chars
  #* The Line terminator can end in LF, CR LF, CR, LF CR.
  #* The entire record should be no more than 32K, which mainly affects inline multimedia records.
  #* Individual lines should not exceed 255 bytes (not chars). This is effectively a max line buffer size.
  #* This includes the leading-space + level + delimiter + tag + delimiter + xref + delimiter + data-value + line-terminator.
  #* Many data values have tag specific recommended lengths for use in fixed length data base schemas.
  #  These are usually much smaller than the line length would allow.
  def cont_conc(level,tag, conc=nil, data = nil)
    #printing aid for tags that can have CONT or CONC sub-tags
    s_out = "#{tabstop(level)}#{level} #{tag}"
    nlevel = level + (conc ? 0 : 1)
    
    if data != nil
      length = s_out.length
      data.each_with_index do |word,i|
        if length > 253 && word != "\n" && data.length != i #253 allows for CR LF or LF CR pairs as the line terminator.
          s_tmp =  "#{tabstop(nlevel)}#{nlevel} CONC"
          length = s_tmp.length #new line, so reset length
          s_out +=  "\n" + s_tmp
        end
        s_out +=  " #{word}"
        if word == "\n"
          s_tmp =  "#{tabstop(nlevel)}#{nlevel} CONT" #Start a CONT line after the '\n'
          length = s_tmp.length  #new line, so reset length
          s_out +=   s_tmp
        else
          length += word.length
        end
      end
    end
    s_out +=  "\n"
  end
  
  #Generate a Multimedia_record's Encoded_line_record.
  #This is an inline Multimedia data source, rather than a file reference.
  #The blob is stored internally as a multiline string. In the GEDCOM file
  #a blob is stored as multiple GEDCOM lines. The first uses a BLOB tag.
  #Subsequent lines use CONT tags.
  def blob(level, data = nil)
    #blobs only have CONT sub-tags
    s_out = "#{tabstop(level)}#{level} CONT"
    
    if data != nil
      data.each_with_index do |word,i|
        s_out +=  " #{word}"
        if word == "\n"
          s_out +=  "#{tabstop(level)}#{level} CONT"
        end
      end
    end
    s_out += "\n"
  end

  #returns a XREF gedcom line.
  #Level 0 GEDCOM has the @XREF@ before the tag.
  #Level n GEDCOM records have the @XREF@ after the tag.
  def xref(level, tag, xref)
    if level == 0 
       "#{tabstop(level)}#{level} @#{xref}@ #{tag}\n"
    else
       "#{tabstop(level)}#{level} #{tag} @#{xref}@\n"
    end
  end
  
  #Process an instruction, defined by action, for this level, tag and data value
  #The actions:
  #* :xref indicates that we need to generate a GEDCOM line with an @XREF@ tag
  #* :print indicates that we need to generate a non-XREF GEDCOM line
  #* :conc indicates that this GEDCOM line can be split into multiple lines with CONC or CONT
  #   The first line output uses the tag, subsequent lines use CONC or CONT.
  #* :cont indicates that this GEDCOM line con be split into multiple lines with CONC or CONT.
  #   This differs for :conc, in that the tags level starts at level+1, not at level.
  #* :blob indicates the GEDCOM line can be split over multiple lines using just CONT tags.
  #   These occur in inline multimedia records.
  #* :date outputs a GEDCOM date line from a Date_record
  #* :time outputs a GEDCOM time line from a Time_record
  #* :nodata indicates that only the level and tag need to output. There is no data value.
  #* :walk indicates this item is a sub-record, therefore we need to recurse and process it using
  #   its action arrays, not this objects action arrays. These are the @this_level and @sub_level 
  #   arrays, which are usually defined in the classes initialize method, but sometimes in a 
  #   an object specific to_gedcom method. 
  def to_s_r_action(level, action, tag, data=nil)
    case action
    when :xref   then 
      xref_check(level, tag, data[0], data[1])
      xref(level, tag, data[1])
    when :print then single_line(level, tag, data )
    when :conc then  cont_conc(level, tag, true, data )
    when :cont then  cont_conc(level, tag, false, data )
    when :blob then  blob(level, data )
    when :walk then  data.to_gedcom(level)
    when :date then  single_line(level, tag, data ) #fix later to format date records
    when :time then  single_line(level, tag, data ) #fix later to format time records
    when :nodata then single_line(level, tag, nil ) 
    end
  end
  
  protected
  
  #validate that the record referenced by the XREF actually exists in this transmission.
  #Genearte a warning if it does not. It does not stop the processing of this line.
  def xref_check(level, tag, index, xref)
    if @transmission != nil && @transmission.find(index, xref) == nil
      #Warning message that reference points to an unknown target.
      print "#{level+1} NOTE ****************Key not found: #{index} #{xref}\n"
    end
  end
  
  #to_s with the variable list (as symbols) passed to it in the order they are to be printed
  def to_s_ordered(variable_list)
    if variable_list != nil
      s = ''
      variable_list.each do |v|
        s += "@#{v} = " + pv_byname(v) + "\n"
      end
      s
    else
      ''
    end
  end
  
 
  #recursive to_s. We want to print this object and its sub-records.
  #the definition of how we want to print and when to recurse, is in the this_level and sub_level arrays.
  #These have the form [ [ action, tag, data_source ],...] (see to_s_r_action )
  def to_s_r(level = 0, this_level=[], sub_levels=[])
    s_out = ""
    this_level.each do |l|
      this_level_instruction = Instruction.new(l)
      if this_level_instruction.data != nil
        data = self.send( this_level_instruction.data ) #gets the contents using the symbol, and sending "self" a message
      else
        data =  [['']]
      end
      if data != nil #could be if the self.send targets a variable that doesn't exist.
        data.each do |data_instance| 
          s_out += to_s_r_action(level, this_level_instruction.action, this_level_instruction.tag, data_instance)
        
          sub_levels.each do |sl|
            sub_level_instruction = Instruction.new(sl)
            if sub_level_instruction.data != nil
              sub_level_data = self.send( sub_level_instruction.data ) #gets the contents using the symbol, and sending "self" a message
            else
               sub_level_data = [['']]
            end
            if sub_level_data != nil  #could be if the self.send targets a variable that doesn't exist.
              sub_level_data.each do |sub_data_instance| 
                s_out += to_s_r_action(level+1, sub_level_instruction.action, sub_level_instruction.tag, sub_data_instance )
              end
            end
          end

        end
      end
    end
    return s_out
  end
  
  
  
end





























