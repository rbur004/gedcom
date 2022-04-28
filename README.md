# gedcom

* Docs :: http://rbur004.github.io/gedcom/
* Source :: https://github.com/rbur004/gedcom
* Gem :: https://rubygems.org/gems/gedcom

## DESCRIPTION:

A Ruby GEDCOM text file parser and producer, that produces a tree of objects from each of the
GEDCOM file types and subtypes. Understands the full GEDCOM 5.5 grammar, and will handle
unknown tags hierarchies as a Note class.


## FEATURES/PROBLEMS:

* GEDCOM multi-character ANSEL encoding is currently not understood when reading and writing, but is preserved if the file is opened as ASCII-8BIT.
* CR line termination causes issues for systems with native LF line termination (CRLF is fine).
* Dates are currently just strings, but I want to parse these and test their validity.
  This is not as easy as it may seem at first, as dates may be in many formats,
  they may be partial, or may actually be strings describing the date.
* For my own use, I bend the GEDCOM 5.5 standard by allowing the reading of the following types in non-standard ways.
  These will not affect the reading and writing of valid GEDCOM 5.5.
* * 'NOTE' type to appear in places it is not defined to exist in GEDCOM.
           This is necessary in order to be able to convert user defined tags into NOTE records.
* * 'RESN' type to appear in places it is not defined to exist in GEDCOM.
           I wanted to be able to mark any record as restricted.
* * 'SUBM' type to appear in 'EVEN' records.
           I wanted to be able to track where I got the event information from.
* * 'SEX' type to appear multiple times in an 'INDI' record,
          as a person's sex can now be changed.
* * 'SEX' type to allow more than 'M', 'F' and 'U',  
          to allow for the XXY, XXXY and X and other genetic anomalies associated with gender.
* * 'NAME' type allows event details ( eg 'DATE') ,
           as names changes are events, not just an attribute.
* * 'ADDR' type allows a 'TYPE' entry
           to qualify what the address is for (e.g. home, work, ...) .
* User defined tags are converted to the NOTE type, with sublevels being CONT lines.
  These are recognised as any tag starting with '_'.
* Haven't yet merged in the code to pretty print a family tree.
* Want to add a merge option, to take multiple transmission and make a single one from them.
* save/load (to/from a database) is yet to be ported. GedcomBase#to_db is a dummy function.
* All GEDCOM TAG values are stored as Arrays. This allows multiple instances of a TAG in a record.
* All Strings values are stored as GedString, which adds each_word and changes the behaviour of each
* Individual attribute records are a sub-class of Event records. Specific attribute tags are also treated this way, To make this more readable, there are alias for
* *  attr_type() to event_type()
* * value() to event_status()
* * is_attribute?() to is_event?()


## SYNOPSIS:

### Read and Write a GEDCOM file

	require 'gedcom'

	puts "parse TGC551LF.ged"
	g = Gedcom.file("../test_data/TGC551LF.ged", "r:ASCII-8BIT") #OK with LF line endings.
	g.transmissions[0].summary
	g.transmissions[0].self_check #validate the gedcom file just loaded, printing errors found.
	puts

	puts "parse TGC55CLF.ged"
	g.file("../test_data/TGC55CLF.ged", "r:ASCII-8BIT") #Ok with CR LF line endings.
	g.transmissions[1].summary #Prints numbers of each level 1 record type found.
	g.transmission[1].self_check #validate the gedcom file just loaded, printing errors found.

	#print the parsed file to see if it matches the source file.
	#Note CONT and CONC breaks may end up in different places
	#Note Order of TAGS at the same level may be different
	#Note User TAGS are output as Notes.
	File.open( "../test_data/TGC551LF.out", "w:ASCII-8BIT") do |file|
	  file.print g.transmissions[0].to_gedcom
	end
	File.open( "../test_data/TGC55CLF.out", "w:ASCII-8BIT") do |file|
	  file.print g.transmissions[1].to_gedcom
	end
	puts "\nComplete"

### Create a GEDCOM file in memory, and write it to a file
```
require 'gedcom'

# Create a transmission record, and encapsulate it in a Gedcom record (which can technically have multiple transmissions, but usually doesn't)
  transmission = Transmission.new
  g = Gedcom.new(transmission)

# GEDCOM transmissions have a header and footer record.
  transmission.header_record << Header_record.new(transmission)
  transmission.trailer_record << Trailer_record.new(transmission)

# Create individual record
  ind = Individual_record.new(transmission)

  # Individual records (all LVL 0 records) need an Xref unique reference string
  ind.individual_ref = [ Xref.new(:individual, 'I1') ]

  # We also add these to the in memory index, to help with lookups
  transmission.create_index(0, :individual, 'I1', ind) # Can throw an exception if the xKey already exists.

# Create name record
  name_record = Name_record.new(transmission)
  name_record.value = [ GedString.new('Wynne George /CROLL/') ]
  name_record.attr_type = [ 'NAME' ]

  # Add in name sub fields (Optional)
    name_record.surname = [ GedString.new("Croll") ]
    name_record.given = [ GedString.new("Wynne George") ]

  # Add the name to the individual record
    ind.name_record ||= [] # Create Array, if name_record is nil
    ind.name_record << name_record # Append name_record to the Array

  # Add the individual record to the transmission record
    transmission.individual_record << ind

puts '*************GEDCOM output*****************'
puts g.transmissions[0].to_gedcom
puts
puts '*************Self Check*****************'
puts g.transmissions[0].self_check
```

## REQUIREMENTS:

* require 'rubygems'

## INSTALL:

* sudo gem install gedcom

## LICENSE:

Distributed under the Ruby License.

Copyright (c) 2009

1. You may make and give away verbatim copies of the source form of the
   software without restriction, provided that you duplicate all of the
   original copyright notices and associated disclaimers.

2. You may modify your copy of the software in any way, provided that
   you do at least ONE of the following:

     a) place your modifications in the Public Domain or otherwise
        make them Freely Available, such as by posting said
  modifications to Usenet or an equivalent medium, or by allowing
  the author to include your modifications in the software.

     b) use the modified software only within your corporation or
        organization.

     c) rename any non-standard executables so the names do not conflict
  with standard executables, which must also be provided.

     d) make other distribution arrangements with the author.

3. You may distribute the software in object code or executable
   form, provided that you do at least ONE of the following:

     a) distribute the executables and library files of the software,
  together with instructions (in the manual page or equivalent)
  on where to get the original distribution.

     b) accompany the distribution with the machine-readable source of
  the software.

     c) give non-standard executables non-standard names, with
        instructions on where to get the original software distribution.

     d) make other distribution arrangements with the author.

4. You may modify and include the part of the software into any other
   software (possibly commercial).  But some files in the distribution
   may not have been written by the author, so that they are not under this terms.

5. The scripts and library files supplied as input to or produced as
   output from the software do not automatically fall under the
   copyright of the software, but belong to whomever generated them,
   and may be sold commercially, and may be aggregated with this
   software.

6. THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
   WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
   PURPOSE.
