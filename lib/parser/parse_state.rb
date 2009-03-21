class ParseState < Array
  
  def initialize(state  = nil, target = nil)
    super(0)
    push state if state
    @target = target #record this so that we can control the targets stack as we alter this one.
  end
  
  def level
    length - 1
  end
  
  def state
    last
  end
  
  def last_state
    self[-2]
  end
  
  def pop
    if level > 0
      super
      @target.pop if @target #as we go up a level, we need to move up the target objects stack too.
    else
      raise "Empty Parse State Stack"
    end
  end
  
  def dump
    self.reverse.each { |the_state| p the_state }
  end
  
end
