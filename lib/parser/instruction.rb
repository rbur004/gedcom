#Instruction names the array elements
#0. The Action to perform
#1. The Tag involved
#2. The Data associated with the Tag.

class Instruction < Array
    attr_reader :tag, :action, :data
    
    def initialize(instruction)
      @action = instruction[0]
      @tag = instruction[1]
      @data = instruction[2]
    end
end