require 'gedcom_base.rb'

class Corporate_record < GedComBase
  attr_accessor :company_name, :phonenumber, :address_record
  attr_accessor :note_citation_record

  ClassTracker <<  :Corporate_record
  
  def initialize(*a)
    super(*a)
    @this_level = [ [:print, "CORP", :company_name] ]
    @sub_level =  [  #level + 1
                    [:print, "PHON", :phonenumber],
                    [:walk,  nil,    :address_record],
                    [:walk, nil,    :note_citation_record],
                  ]
  end
end
