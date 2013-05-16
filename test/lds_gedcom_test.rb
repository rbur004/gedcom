#!/usr/local/bin/ruby
##!/usr/bin/ruby1.8
#Or 1.9 version at
#!/usr/local/bin/ruby
require 'rubygems'
require '../pkg/gedcom-0.9.4/lib/gedcom.rb'
require 'versioncheck'


#Parses the LDS GEDCOM test files and them dumps them back out as GEDCOM.
#This allows me to test for errors in parsing and output. The two files will
#not be an exact match, as the NOTE/CONT/CONC line breaks could be different
#and user defined tags will get converted to NOTES.

puts "parse TGC551LF.ged"
if VersionCheck.rubyversion.have_at_least_version?(1,9)
  g = Gedcom.file("../test_data/TGC551LF.ged", "r:ASCII-8BIT") #OK with LF line endings.
else
  g = Gedcom.file("../test_data/TGC551LF.ged", "r") #OK with LF line endings.
end
g.transmissions[0].summary
puts 

g.transmissions[0].self_check

#puts g.transmissions[0].header_record[0].to_s
puts
#f = g.transmissions[0].find(:individual,"PERSON1")
#puts f.to_s

#puts "parse TGC55CLF.ged"
#g.file("../test_data/TGC55CLF.ged", "r:ASCII-8BIT") #Ok with CR LF line endings.
#g.transmissions[1].summary
#puts 

#g.file("../test_data/TGC551.ged")  #fails to find CR line breaks, as native system uses LF, so reports parse error.
#g.file("../test_data/TGC55C.ged") #fails to find CR line breaks,  as native system uses LF, so reports parse error.

#print the parsed file to see if it matches the source file.
#Note CONT and CONC breaks may end up in different places
#Note Order of TAGS at the same level may be different
#Note User TAGS are output as Notes.
if VersionCheck.rubyversion.have_at_least_version?(1,9)
  File.open( "../test_data/TGC551LF.out", "w:ASCII-8BIT") do |file|
    file.print g.transmissions[0].to_gedcom
  end
else
  File.open( "../test_data/TGC551LF.out", "w") do |file|
    file.print g.transmissions[0].to_gedcom
  end
end

#File.open( "../test_data/TGC55CLF.out", "w:ASCII-8BIT") do |file|
#  file.print g.transmissions[1].to_gedcom
#end
puts "\nComplete"
#c = Chart.new
#puts c.output_pedigree_name( f, 10, nil, nil, Bit.new, '', '', nil, '', 0 )


