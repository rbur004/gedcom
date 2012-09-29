= gedcom

* http://rubyforge.org/projects/gedcom/

== DESCRIPTION:

A Ruby GEDCOM text file parser and producer, that produces a tree of objects from each of the
GEDCOM file types and subtypes. Understands the full GEDCOM 5.5.1 grammar, and will handle 
unknown tags hierarchies as a Note class.
 
 
== FEATURES/PROBLEMS:

* Gedcom multicharacter ANSEL encoding is currently not understood when reading and writing, but is preserved if the file is opened as ASCII-8BIT.
* CR line termination causes issues for systems with native LF line termination (CRLF is fine).
* Dates are currently just strings, but I want to parse these and test their validatity. 
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
          to allow for the XXY, XXXY and X and other genetic anomolies associated with gender.
* * 'NAME' type allows event details ( eg 'DATE') , 
           as names changes are events, not just an attribute.
* * 'ADDR' type allows a 'TYPE' entry 
           to qualify what the address is for (e.g. home, work, ...) .
* User defined tags are converted to the NOTE type, with sublevels being CONT lines.
  These are recognised as any tag starting with '_'. 
* Haven't yet merged in the code to pretty print a family tree.
* Want to add a merge option, to take multiple transmission and make a single one from them.
* save/load (to/from a database) is yet to be ported. GedcomBase#to_db is a dummy function.

== SYNOPSIS:

	require 'gedcom'

	puts "parse TGC551LF.ged"
	g = Gedcom.file("../test_data/TGC551LF.ged", "r:ASCII-8BIT") #OK with LF line endings.
	g.transmissions[0].summary
	g.transmission[0].self_check #validate the gedcom file just loaded, printing errors found.
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


== REQUIREMENTS:

* require 'rubygems'

== INSTALL:

* sudo gem install gedcom

== LICENSE:

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
   may not written by the author, so that they are not under this terms.

5. The scripts and library files supplied as input to or produced as 
   output from the software do not automatically fall under the
   copyright of the software, but belong to whomever generated them, 
   and may be sold commercially, and may be aggregated with this
   software.

6. THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
   WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
   PURPOSE.
