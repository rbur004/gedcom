#ParseState sub-classes Array to provide a stack for holding the current parse state.

class ParseState < Array
  
  #Create the initial state.
  #Optional arguments:
  #* state, if it has a value, is pushed onto the state stack as the current state.
  #* target, if it has a value, then it is the object we are using when in this state.
  #          It should be non-nil if state is not nil.
  #e.g. GedcomParser.new calls ParseState.new( :transmission ,  @transmission) 
  #     Pushes the transmission state onto the stack, and records the GedcomParser.transmission 
  #     object as the current target object.
  def initialize(state  = nil, target = nil)
    super(0)
    push state if state != nil
    @target = target #record this so that we can control the targets stack as we alter this one.
  end
  
  #level() is the depth of the stack, less 1, which gives us the GEDCOM level we are working with.
  def level
    length - 1
  end
  
  #state() is the last item in the Array, hence the top of the stack.
  def state
    last
  end
  
  #last_state() is the previous state on the stack, so we know the state we came from.
  def last_state
    self[-2]
  end
  
  #pop() reverts to the previous state.
  def pop
    if level > 0
      super
      @target.pop if @target != nil #as we go up a level, we need to move up the target objects stack too.
    else
      raise "Empty Parse State Stack"
    end
  end
  
  #dump() is a debugging aid to print out the current ParseState's stack.
  def dump
    self.reverse.each { |the_state| p the_state }
  end
  
end
