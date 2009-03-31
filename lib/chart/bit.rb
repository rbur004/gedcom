#Simple Bit array class to hold state for our tree drawing class.

class Bit
  #create a bit store using Fixnum. Initialize to 0.
  def initialize(bm = 0)
    @bm = bm
  end
  
  #set the bit i to 1. Relies on auto promotion of Fixnum to Bignum.
  def set(i)
  	@bm |= 1 << i
  end

  #Set bit i to 0. 
  def clear(i)
  	@bm &= 0 << i
  end

  #Return true if bit i is set
  def set?(i)
    @bm[i] == 1
  end

  #Return true if bit i is clear
  def clear?(i)
    @bm[i] == 0
  end

  #print the Bit array as a binary number.
  def to_s
    @bm.to_s(2)
  end
end

