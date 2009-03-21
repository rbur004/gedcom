class Instruction < Array
    attr_reader :tag, :action, :data
    
    def initialize(instruction)
      @action = instruction[0]
      @tag = instruction[1]
      @data = instruction[2]
    end
end