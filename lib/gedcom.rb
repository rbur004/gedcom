#Gedcom class holds an array of GEDCOM transmissions (that is parsed GEDCOM files)
#Each transmission relates to the loading of a GEDCOM text file, parsing it into
#a tree, starting with a Transmission class at its root. Within the Transmission
#class are arrays for each of the level 0 GEDCOM record types of these classes:
#  * Header_record
#  * Submission_record 
#  * Submitter_record
#  * Individual_record
#  * Family_record
#  * Source_record
#  * Repository_record
#  * Multimedia_record
#  * Note_record
#  * Trailer_record
#
#Each of these classes has arrays for each of the Level 1 Gedcom records types
#associated with the Level 0 type. Some of these are attributes, that is they contain
#the actual data, while others are classes that contain attributes and/or classes
#e.g. an Individual_record class object could have any or all of these:
#
# * individual_ref                   ( that is individual_ref = 'I42' if the GEDCOM line is '0 INDI @I42@')
# Then 1 level down it is possible to get local attributes for this object
# * restriction                      (from the GEDCOM "1 RESN restriction_value" )
# * registered_ref_id                (from the GEDCOM "1 RFN registered_ref_id" )
# * lds_ancestral_file_no            (from the GEDCOM "1 AFN lds_ancestral_file_no" )
# * automated_record_id              (from the GEDCOM "1 RIN automated_record_id" )
# Also arrays of classes may exist for these:
# * Name_record                       (from the GEDCOM "1 NAME ..." )
# * Individual_attribute_record       (from the GEDCOM "1 [SEX | TITL | ... ] ...")
# * Event_record                      (from the GEDCOM "1 [BIRT | DEAT | ... ] ... ")
# * Families_individuals              (from the GEDCOM "1 [FAMC | FAMS] ...")
# * Individuals_individuals           (from the GEDCOM "1 [ANCI | DESO | ASSO] ...")
# * Multimedia_citation_record        (from the GEDCOM "1 OBJE ...")
# * Source_citation_record            (from the GEDCOM "1 SOUR ...")
# * Note_citation_record              (from the GEDCOM "1 NOTE ...")
# * Refn_record                       (from the GEDCOM "1 REFN ...")
# * Change_date_record                (from the GEDCOM "1 CHAN ...")
# And References to other record types:
# * alias_ref                         (from the GEDCOM "1 ALIA alias_ref" )
# * submitter_ref                     (from the GEDCOM "1 SUBM submitter_ref" )
#
# Below say an Event object in an Individual_record object, you could get further arrays of 
# attributes and other objects holding further levels of the GEDCOM hierarchy.
#
#These can all be seen in the TAGS hash in parser/gedcom_parser.rb, which defines 
#what TAGS are valid when, and what action to take when a particular tag is encountered
#in the input stream.
#
#The reverse, that is the conversion back to GEDCOM format is not a simple reversal of the
#TAGS entries. The generation of GEDCOM from the objects is done recursively, by calling the
#objects to_gedcom() method. This can occur at any level, from Transmission downward.
#

def path(s,fs='/')
  last_fs = s.rindex(fs)
  last_fs ? s[0..last_fs] : ""
end

$: << "#{path(__FILE__)}gedcom"
$: << "#{path(__FILE__)}parser"
$: << "#{path(__FILE__)}chart"

require 'gedcom_parser.rb'
#require 'chart.rb'

class Gedcom
  VERSION = '0.9.3'
  attr_accessor :transmissions
  
  def initialize(transmission = nil)
    @transmissions = []
    add_transmission(transmission) if transmission != nil
  end
  
  def self.file(*a)
    g = Gedcom.new
    g.file(*a)
    return g
  end
  
  def file(*a)
    transmission = Transmission.new
    gedcom_parser = GedcomParser.new(transmission)
    
    File.open(*a) do   |file| 
      file.each_line("\n") do |line|
        begin
          gedcom_parser.parse( file.lineno, line )
        rescue => exception
          puts "#{file.lineno}: #{exception} - " + line
          # raise exception
        end
      end
    end
    
    @transmissions << transmission
    
  end
  
  def add_transmission(transmission)
    @transmissions << transmission
  end
  
  def each
    @transmissions.each { |t| yield t }
  end
end