#ClassTracker keeps track of the existence of our gedcom classes.
#If they don't exist yet, the parser will need to dynamically create them. 
#
#This started as an experiment to automate the generation of the Gedcom classes, but they now all exist
#and none should ever end up being created dynamically. I need to deprecate this class at some point.


class ClassTracker
  #Create a hash of known class definitions, we would not have to do this when I figure out how to tell if a class definition exists.
  @@classes = { }

  #Returns true if the named class is in @@classes.
  def self.exists?(class_name)
    @@classes[class_name.to_sym] == true
  end
    
  #Adds a class to the @@classes hash using the << operator.
  def self.<<(class_name)
    @@classes[class_name.to_sym] = true
  end
  
  #return the state of each of the classes recorded in the @@classes hash, as a string.
  def self.to_s
    s = '{'
    @@classes.each { |k,v| s += "\n\t#{k.to_s}=>#{v.to_s},"}
    s[-1] = '' if s[-1,1] == ','[0,1]
    s << "\n}"
  end
    
end

#ClassTracker << :kkk
#print ClassTracker
