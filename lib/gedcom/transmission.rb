require 'pp'
require 'gedcom_all.rb'

class  Transmission < TransmissionBase
 
  def initialize
    super
    @print_on = false
  end
  
  def summary
    puts "HEAD count = #{@header_record.length}"
    puts "SUBM count = #{@submission_record.length}"
    puts "SUBN count = #{@submitter_record.length}"
    puts "INDI count = #{@individual_record.length}"
    puts "FAM count = #{@family_record.length}"
    puts "SOUR count = #{@source_record.length}"
    puts "REPO count = #{@repository_record.length}"
    puts "OBJE count = #{@multimedia_record.length}"
    puts "NOTE count = #{@note_record.length}"
    puts "TRLR count = #{@trailer_record.length}"
    #p ClassTracker
    #pp @indexes[:individual]["IPB4"]
    #pp @indexes[:family]["F1"]
    #pp @indexes[:note]
    #find(:individual,"IB1024").to_gedcom
  end
    
  def validate lineno, tokens, max_data_size
    #Validate the length of the data field is in bounds.
    if tokens.data
      length = 0
      tokens.data.inject(0) { |length,element| length += element.length + 1 }
      if length - 1 > max_data_size
        p "Warning Line #{lineno}: Data portion may be too long for some databases. (Length = #{length - 1}, MAX = #{max_data_size})"
      end
    end
  end
  
  def create_class(lineno, class_name)

    if class_name
      new_class = class_name.to_s.capitalize
      if defined(new_class) == nil
        p "#{lineno}: Create class #{new_class}"
        define(new_class)
        new_class = Object.const_set("#{new_class}", Class.new) #creates a Class and assigns it the constant given
      end 
      #p "#{lineno}: instance class #{class_name}"
      class_instance = eval "#{new_class}.new" #create an instance of the new class.
      if class_instance == nil
        raise "class #{class_name} instance nil"
      end
    end
    class_instance
  end
  
  def add_to_class_field(lineno, field, data)
    #puts "#{lineno}: Add class instance '#{data.class}' to field #{field} of #{@class_stack.last[0]}"
    if @class_stack.last[0].class.method_defined?(field) == false
      p "#{lineno}: create a field called #{field} in class #{@class_stack.last[0].class.to_s}" 
      @class_stack.last[0].class.class_eval("attr_accessor :#{field}")
      #p "#{lineno}: Add the class #{data.class.to_s} as an array, to the field #{field} in class #{@class_stack.last[0].class.to_s}" 
      @class_stack.last[0].send( field.to_s + "=", data ? [ data ] : []) #Much faster than eval("@class_stack.last[0].#{field} = [#{data}]")
    else
      if a = @class_stack.last[0].send( field )
        #Much faster than eval("@class_stack.last[0].#{field} << #{data}")
        #p "#{lineno}: Add the class #{data.class.to_s} to the field #{field}[] in class #{@class_stack.last[0].class.to_s}" 
        a << data if data
      else
        #p "#{lineno}: Add the class #{data.class.to_s} as an array, to the field #{field} in class #{@class_stack.last[0].class.to_s}" 
        @class_stack.last[0].send( field.to_s + "=", data ? [ data ] : [] )
      end
    end
  end
  
  def pop
    #this is to catch multiple classes added to the stack, for one gedcom line.
    i = @class_stack.last[1]
    i.times { @class_stack.pop }
  end
  
  def update_field(lineno, field, data_type, data)
    #p "#{lineno}: Add data '#{data}' to field #{field} of #{@class_stack.last[0]}"
    add_to_class_field(lineno, field, data)
  end
  
  def append_nl_field(lineno, field, data_type, data)
    #p "#{lineno}: Append data 'nl + #{data}' to field #{field} of #{@class_stack.last[0]}"
    the_data = ["\n"] #want to add a new line to the exising data
    the_data += data if data #add the new data only if it is not null.
    append_field(lineno, field,data_type, the_data)
  end
  
  def append_field(lineno, field, data_type, data)
    #p "#{lineno}: Append data '#{data}' to field #{field} of #{@class_stack.last[0]}"
    begin
      if data #Only bother if we have some data
        if a = @class_stack.last[0].send( field ) #The field is not nil
          if a != [] #The field is not an empty array
            if a[-1] #The last element is not null
              #p "Add the class #{data.class.to_s} to the field #{field}[] in class #{@class_stack.last[0].class.to_s}"
              a[-1] += data 
            else #The last element is null
              #p "Add the class #{data.class.to_s} as an array, to the field #{field} in class #{@class_stack.last[0].class.to_s}"
              a[-1] = data
            end
          else #Was an empty array, so add the element.
            a[0] = data
          end
        else #The field was null
          #p "Add the class #{data.class.to_s} as an array, to the field #{field} in class #{@class_stack.last[0].class.to_s}"
          @class_stack.last[0].send( field.to_s + '=',  [data])
        end
      end
    rescue => exception
      p "#{exception} : Append data '#{data}' to field '#{field}' of class '#{@class_stack.last[0]}'"
      raise exception
    end
  end
  
  def create_index(lineno, index_name, key, value)
    if index_name
      if @indexes[index_name] == nil
        #puts "#{lineno}: create index #{index_name}"
        @indexes[index_name] = {} #empty hash
      end
      if key
        #p "#{lineno}: Add (key,value) #{key} => #{@class_stack.last[0]} to index #{index_name}"
        if @indexes[index_name][key]
          raise "duplicate key #{key} in index #{index_name}"
        end
        @indexes[index_name][key] = value
      end
    end
  end
  
  def add_to_index(lineno, field_name, index_name, key)
    #p "#{lineno}: Add key #{key} to index #{index_name} to field #{field_name} of #{@class_stack.last[0]}"
     add_to_class_field(lineno, field_name, [index_name, *key] )
  end
  
  # [:class, :class_name] inidicates this line, and any further data, will be stored in the class  :class_name
  # [:pop] indicates that data will now be stored in the previous class.
  # [:field, :fieldname] indicates that the data part of the line will be stored in the field :field_name
  # [:field, [:fieldname, value]]  fieldname stores the given value.
  # [:append, :fieldname] indicates that the data part of the line will be appended to this field
  # [:append_nl, :fieldname] indicates that the data part of the line will be appended to this field, after first appending a nl
  # [:xref, [:field, :record_type]] indicates that the xref value of the line will get stored in the named field and points to the record_type.
  # [:key, :index_name] means we need to create an index entry, in the index index_name, for this items xref value.
  # nil in this field indicates that we should ignore this TAG and its children.
  ACTION = 0
  DATA = 1
  def action_handler( lineno, tokens, child_record = nil, min_occurances = 0, max_occurances = nil, data_type = nil, max_data_size = nil, action = nil, data_description = '' )
 
    validate(lineno, tokens, max_data_size)
 
    #p "#{lineno}: #{action}"
=begin
     if tokens.level == 0
       if tokens.tag == "SOUR"
         @print_on = true
       else
         @print_on = false
       end
     end
    p "#{lineno}: #{tokens.level} #{tokens.tag} of class #{@class_stack.last[0]}" if @print_on
=end
    if action
      nclasses = 1
      new_class = nil
      action.each do |do_this| #We have instructions for handling this line.
        case do_this[ACTION]
          when :class 
            #create a new class, making an instance of it, and making the instance the default one.
            new_class = create_class(lineno, do_this[DATA])
            #Add this instance to an Array field of the current class, of the same name as the new class.
            add_to_class_field(lineno, do_this[DATA], new_class)
            #Make this class the current one
            @class_stack << [new_class, nclasses]
            nclasses += 1 #We want to be able to unwind the stack in sync with the gedcom.
                          #Hence we need to know how many classes we created at each point.
          when :field
            if do_this[DATA].class == Array #Then the value we are storing is given, rather than derived from the source file.
              update_field(lineno, do_this[DATA][0], data_type, do_this[DATA][1])
            else
              update_field(lineno, do_this[DATA], data_type, tokens.data)
            end
          when :append_nl 
            #We want to add a line terminator, then append the new data field from tokens
            append_nl_field(lineno, do_this[DATA], data_type, tokens.data)
          when :append 
            #we want to append the data field in tokens, to the named field.
            append_field(lineno, do_this[DATA], data_type, tokens.data)
          when :xref 
            #we want to record the reference (xref) from the token object.
            add_to_index(lineno, do_this[DATA][0], do_this[DATA][1], tokens.xref)
          when :key
            #will only occur after a class that is the thing we want the xref index to point to. ie xref => new_class
            create_index(lineno, do_this[DATA], tokens.xref, new_class )
          when :pop
            @class_stack.pop #In this instance, we want to remove only the last item, even if there were several added.
          when :push
            @class_stack << @class_stack.last #We need to have dummy entries when the gedcom has another level, but we build no class for it.
        end
      end
    end    
  end
  
end
