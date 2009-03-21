require 'gedcom_base.rb'

class Address_record < GedComBase
  attr_accessor :address,  :address_line1, :address_line2, :city, :state, :post_code, :country, :address_type
  attr_accessor :note_citation_record

  ClassTracker <<  :Address_record
  
  def initialize(*a)
    super(*a)
    @this_level = [ [:cont, "ADDR", :address] ]
    @sub_level =  [ #level + 1
                    [:print, "ADR1", :address_line1],
                    [:print, "ADR2", :address_line2],
                    [:print, "CITY", :city],
                    [:print, "STAE", :state],
                    [:print, "POST", :post_code],
                    [:print, "CTRY", :country],
                    [:print, "TYPE", :address_type], #non standard.
                    [:walk,  nil,   :note_citation_record],
                  ]
  end
                
end
