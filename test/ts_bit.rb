require "test/unit"
require "../lib/tree/bit.rb"

class TestGedcom < Test::Unit::TestCase
  def test_bit
    x = Bit.new
    x.set(43)
    
    assert_equal(false, x.set?(44))
    assert_equal(true, x.clear?(44))

    assert_equal(false, x.clear?(43))
    assert_equal(true, x.set?(43))
    
    x.clear(43)
    assert_equal(false, x.set?(43))
    assert_equal(true, x.clear?(43))
    
    puts x.set(4)
    assert_equal("10000", x.to_s)
    puts x.set(43)
    assert_equal("10000000000000000000000000000000000000010000", x.to_s)
  end
end

