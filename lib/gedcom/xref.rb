#Utility class just to make referencing xrefs clearer.

class Xref
  attr_accessor :index, :xref_value
  def initialize(index, xref_value)
    @index, @xref_value = index, xref_value
  end
end
