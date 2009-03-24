require 'gedcom_base.rb'

class Event_record < GedComBase
  attr_accessor :restriction #not standard at the event level, but we might want this in DB.
  attr_accessor :event_type, :event_descriptor
  attr_accessor :event_status, :date_record, :phonenumber, :place_record, :address_record, :age
  attr_accessor :agency, :cause_record, :source_citation_record, :submitter_ref
  attr_accessor :multimedia_citation_record, :note_citation_record, :event_age_record, :adoption_record
  attr_accessor :lds_temp_code, :lds_date_status, :lds_slgc_family_ref

  ClassTracker <<  :Event_record
  
  def initialize(*a)
    super(*a)
    @sub_level = [ #level + 1
                    [:print, "RESN", :restriction],
                    [:print, "TYPE", :event_descriptor],
                    [:print, "STAT", :lds_date_status],
                    [:walk, nil,  :cause_record],
                    [:walk, nil, :date_record],
                    [:print,  "TEMP", :lds_temp_code],
                    [:walk, nil, :place_record],
                    [:walk, nil, :address_record],
                    [:print, "PHON", :phonenumber],
                    [:print, "AGE", :age],
                    [:walk, nil,  :event_age_record],
                    [:print, "AGNC", :agency],
                    [:walk, nil,   :multimedia_citation_record],
                    [:walk, nil,   :source_citation_record],
                    [:walk, nil, :note_citation_record],
                    [:xref, "SUBM", :submitter_ref],
                    [:walk, nil, :adoption_record],
                    [:xref, "FAMC",  :lds_slgc_family_ref],
                  ]
  end
      
  def to_gedcom(level=0)
    tag = event_tag(@event_type[0].to_s)
    
#    print "'#{@event_type}' '#{@event_descriptor}' => #{tag}\n"
    if @event_status != nil && @event_status[0] != nil && @event_status[0][0]  != nil
      @this_level = [ [:print, tag, :event_status] ]
    else
      @this_level = [ [:nodata, tag, nil] ]
    end
    super(level)
  end
  
  def event_tag(tag)
    case tag
    when "ANUL" then tag
    when "CENS" then tag
    when "DIV" then tag
    when "DIVF" then tag
    when "ENGA" then tag
    when "MARR" then tag
    when "MARB" then tag
    when "MARC" then tag
    when "MARL" then tag
    when "MARS" then tag
    when "EVEN" then tag
    when "RESI" then tag
    when "SLGS" then tag
    when "BIRT" then tag
    when "CHR" then tag
    when "ADOP" then tag
    when "DEAT" then tag
    when "BURI" then tag
    when "CREM" then tag
    when "BAPM" then tag
    when "BARM" then tag
    when "BASM" then tag
    when "BLES" then tag
    when "CHRA" then tag
    when "CONF" then tag
    when "FCOM" then tag
    when "ORDN" then tag
    when "NATU" then tag
    when "EMIG" then tag
    when "IMMI" then tag
    when "CENS" then tag
    when "PROB" then tag
    when "WILL" then tag
    when "GRAD" then tag
    when "RETI" then tag
    when "BAPL" then tag
    when "CONL" then tag
    when "ENDL" then tag
    when "SLGC" then tag
    else          "EVEN"
    end
  end
  
  def is_event(tag)
    @event_type.to_s == tag
  end
  
  def date
    if @date_record != nil
      @date_record[0].date
    else
      nil
    end
  end
end
