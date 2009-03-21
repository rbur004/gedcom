require "class_tracker.rb"
require "instruction.rb"

class GedComBase
  attr_accessor  :class_stack, :indexes

  #base printing routines shared by all gedcom objects.
  def initialize(changed=true,created=true)
    #Create a stack holding the classes we create as we walk down the levels of a gedcom record.
    #The class we are currently working with is on the top of the stack.
    #The number represents the number of class to pop to go back one level of gedcom.
    @class_stack = [[self, 0]]
    #Create a hash to hold the indexes used in this transmission
    @indexes = {}
    @changed = changed
    @created = created
    @this_level = []
    @sub_level = []
    @@tabs = false #Normally wouldn't have them in a transmission.
  end
  
  def self.tabs
    @@tabs = true #useful if pretty printing, but not normal in a gedcom file as most parsers don't like this.
  end
  
  def self.no_tabs
    @@tabs = false #The default
  end
  
  def changed
    @changed = true
  end
  
  def changed?
    @changed
  end
  
  def created?
    @created
  end
  
  def find(index_name, key)
    if index = @indexes[index_name.to_sym]
      index[key]
    else
      false
    end
  end
  
  def pv_byname(v_sym, indent = 0)
    #Somewhat cryptic. This takes the symbol and returns the object associatied with it.
    a = self.send( v_sym )
    pv(a)
  end
  
  def pv(v)
    #return a string of ',' separated values stored in the object.
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
  
  def to_s
    #create a string from the child object.
    s = ''
    self.instance_variables.each do |v| #look at each of the instance variables
      if self.class.method_defined?(v_sym = v[1..-1].to_sym) #see if there is a method defined for this symbol (strip the :)
        s += "#{v} = " + pv_byname(v_sym) + "\n" #print it
      end
    end
    s
  end
  
  def to_s_ordered(variable_list)
    #To_s with the variable list (as symbols) passed to it in order to be printed
    if variable_list
      s = ''
      variable_list.each do |v|
        s += "@#{v} = " + pv_byname(v) + "\n"
      end
      s
    else
      ''
    end
  end
  
  def tabstop(level) 
    #printing aid for indenting each level
    return "" if !@@tabs
    s = ''
    level.times { s += '  ' }
    return s
  end
  
  def single_line(level,tag, data = nil)
    #printing aid for tags that can have CONT or CONC sub-tags
    s_out =  tabstop(level) + "#{level} #{tag}"
    if data != nil
      data.each do |word|
        if word != "\n"
          s_out +=  " #{word}"
        end
      end
    end
    s_out +=  "\n"
  end
  
  def cont_conc(level,tag, conc=nil, data = nil)
    #printing aid for tags that can have CONT or CONC sub-tags
    s_out =  tabstop(level) + "#{level} #{tag}"
    nlevel = level + (conc ? 0 : 1)
    
    if data
      length = 0
      data.each_with_index do |word,i|
        if length > 80 && word != "\n" && data.length != i
          s_out +=  "\n" + tabstop(nlevel) + "#{nlevel} CONC"
          length = 0
        end
        s_out +=  " #{word}"
        if word == "\n"
          s_out +=   tabstop(nlevel) + "#{nlevel} CONT"
          length = 0
        else
          length += word.length
        end
      end
    end
    s_out +=  "\n"
  end
  
  def blob(level, data = nil)
    #blobs only have CONT sub-tags
    s_out = tabstop(level) + "#{level} CONT"
    
    if data
      data.each_with_index do |word,i|
        s_out +=  " #{word}"
        if word == "\n"
          s_out +=   tabstop(level) + "#{level} CONT"
        end
      end
    end
    s_out += "\n"
  end

  def xref(level, tag, xref)
    if level == 0 
      tabstop(level) + "#{level} @#{xref}@ #{tag}\n"
    else
      tabstop(level) + "#{level} #{tag} @#{xref}@\n"
    end
  end
    
  def xref_check(level, tag, index, xref)
    if find(index, xref) == nil
      #Warning message that reference points to an unknown target.
      print "#{level+1} NOTE ****************Key not found: #{index} #{xref}\n"
    end
  end
  
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
    when :date then  single_line(level, tag, data ) #fix later to format dates
    when :time then  single_line(level, tag, data ) #fix later to formac times
    when :nodata then single_line(level, tag, nil ) 
    end
  end
 
  def to_s_r(level = 0, this_level=[], sub_levels=[])
    #recursive to_s. We want to print this object and its sub-tags
    #the definition of how we want to print and when to recurse, is in the instructions array.
    #instructions = [ [ action, tag, data_source ],...]
    s_out = ""
    this_level.each do |l|
      this_level_instruction = Instruction.new(l)
      if this_level_instruction.data
        data = self.send( this_level_instruction.data ) #gets the contents using the symbol, and sending "self" a message
      else
        data =  [['']]
      end
      if data != nil
        data.each do |data_instance| 
          s_out += to_s_r_action(level, this_level_instruction.action, this_level_instruction.tag, data_instance)
        
          sub_levels.each do |sl|
            sub_level_instruction = Instruction.new(sl)
            if sub_level_instruction.data
              sub_level_data = self.send( sub_level_instruction.data ) #gets the contents using the symbol, and sending "self" a message
            else
               sub_level_data = ['']
            end
            if sub_level_data
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
  
  #Need to flesh this out. Right now it pretends to work and marks records as saved.
  def to_db(level = 0, this_level=[], sub_levels=[])
    @changed = false
    @created = false
  end
  
  def to_gedcom(level = 0)
    to_s_r( level, @this_level, @sub_level )
  end
  
  def save
    to_db( level, @this_level, @sub_level)
  end
  
end





























