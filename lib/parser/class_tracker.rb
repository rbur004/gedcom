#ClassTracker keeps track of the existence of our gedcom classes.
#If they don't exist yet, the parser will create them. 
#This started as an automated way to generate the gecom classes, but they now all exist
#and none should ever end up being created dynamically. 


class ClassTracker
  #Create a hash of known class definitions, we would not have to do this when I figure out how to tell if a class definition exists.
  @@classes = { }

  def self.exists(class_name)
    @@classes[class_name.to_sym]
  end
  
  def self.get(class_name)
    @@classes[class_name.to_sym]
  end
  
  def self.insert(class_name)
    @@classes[class_name.to_sym] = true
  end
  
  def self.<<(class_name)
    @@classes[class_name.to_sym] = true
  end
  
  def self.to_s
    s = '{'
    @@classes.each { |k,v| s += "\n\t#{k.to_s}=>#{v.to_s},"}
    s[-1] = '' if s[-1,1] == ','[0,1]
    s << "\n}"
  end
    
end

#ClassTracker << :kkk
#print ClassTracker
