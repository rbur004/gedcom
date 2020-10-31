#!/usr/bin/env ruby1.9
#Our parser tokenize strings into word arrays. This is helpful in word wrapping for CONT and CONC,
#but pretty silly for most other uses. I'm still thinking about the best way to deal with this.
#
#The current thought is to flatten the array and store the value as a space separated string, and tokenize
#tokenize it again if we output GEDCOM. Most of the time, this is what we want, and it makes dealing with
#Data bases easier too.

class GedString < String
  
  #takes a word array from the parser and creates a space separated string.
  #Also excepts a String, assigning this to the 
  def initialize(word_array)
    if(word_array.class == String)
      super word_array
    elsif(word_array.class == Array)
      super(word_array.inject('') do |v, w|
        if v == '' 
          w 
        elsif w == "\n" || v[-1,1] == "\n"
          v + w
        else
          v + ' ' + w
        end
      end 
      )
    else
      raise "GedString word_array passed in as #{word_array.class}"
    end
  end
  
  #yields the string word by word. Line separators in the string will also be yielded as words.
  def each_word
    self.gsub(/\n/," \n ").split(/ /).each { |w| yield w }
  end
  
  #yields the string word by word. Line separators in the string will also be yielded as words.
  def each_word_with_index
    self.gsub(/\n/," \n ").split(/ /).each_with_index { |w,i| yield(w, i) }
  end
    
  #We aren't an array, but to simplify some code, the method each is defined to return our 1 value.  
  def each
    yield self
  end
  
  alias each_with_index each_word_with_index
  
end
