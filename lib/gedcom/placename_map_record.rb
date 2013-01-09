require 'gedcom_base.rb'

#=Placename_map_record
#GEDCOM 5.5.1 Draft adds as subordinate to PLAC
#
#    +1 MAP 
#      +2 LATI <PLACE_LATITUDE> 
#      +2 LONG <PLACE_LONGITUDE>
#
#==PLACE_LATITUDE:=                                               {Size=5:8}
#  The value specifying the latitudinal coordinate of the place name. The latitude coordinate is 
#the direction North or South from the equator in degrees and fraction of degrees carried out to give 
#the desired accuracy. For example: 18 degrees, 9 minutes, and 3.4 seconds North would be formatted 
#as N18.150944. Minutes and seconds are converted by dividing the minutes value by 60 and the seconds 
#value by 3600 and adding the results together. This sum becomes the fractional part of the degree's value. 
#
#==PLACE_LONGITUDE:=	                                            {Size=5:8} 
#The value specifying the longitudinal coordinate of the place name. The longitude coordinate is Degrees 
#and fraction of degrees east or west of the zero or base meridian coordinate. For example: 168 degrees, 
#9 minutes, and 3.4 seconds East would be formatted as E168.150944.
#
#I allow a NOTE record too, to cope with user defined tags

class Placename_map_record < GEDCOMBase
  attr_accessor :latitude, :longitude
  attr_accessor :note_citation_record
  ClassTracker <<  :Placename_map_record
  
  def initialize(*a)
    super(*a)
    @this_level = [ [:print, "MAP", nil] ]
     @sub_level = [
                       [:print, "LATI", :latitude],
                       [:print, "LONG", :longitude], #Not standard
                       [:walk, nil,    :note_citation_record],
                   ] 
  end
end

