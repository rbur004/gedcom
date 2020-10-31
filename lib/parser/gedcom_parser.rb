require 'parse_state.rb'
require 'ged_line.rb'
require 'transmission.rb'

#Class GedcomParser is a GEDCOM 5.5 Parser
#
#The GEDCOM 5.5 grammer is defined in the TAGS hash.
# * Each TAGS hash members key represents a name of a GEDCOM record definition in the standard.
#   The standard doesn't name all sub-levels of a record, but for our definitions we have had to.
#   e.g. In the standard: 
#          HEADER:=
#           n HEAD  {1:1}
#             +1 SOUR <APPROVED_SYSTEM_ID> {1:1}
#             ...
#        becomes a :header key and a :header_source key in the TAGS hash.
#
# * Each value is another hash, whose key is a two member array: [<GEDCOM_TAG>, <context>]
#   Valid Contexts:
#   [:xref] indicates that the GEDCOM TAG with a reference value, so should have an @XREF@ value following it
#           Nb. With level 0 GEDCOM records, the @XREF@ will proceed the  GEDCOM TAG.
#   [nil]   indicates this is a standard GEDCOM tag, possibly with a data value following it.
#   [:user] indicates that this is a user defined tag, not one from the standard.
#   e.g. 
#        ["NOTE", :xref] is a NOTE tag with a reference to a note, or at Level 0 the :xref is the key for other records to refer to.
#        ["NOTE", nil] is an inline NOTE, with the note being the value on the GEDCOM line
#        ["NOTE", :user] is a NOTE record where the standard didn't allow for one (i.e. user defined)
#   Each value of this hash being an array telling the parse what it must do when it meets the GEDCOM_TAG in the context.
#   This array array has the following fields
#   0. CHILD_RECORD     This is the key to the child level tag description lines.
#   1. MIN_OCCURANCES   What is the minimum number of times we should see this field. Usually 0 or 1
#   2. MAX_OCCURANCES   How many times can this tag appear at this level. Nil means any number of times
#   3. DATA_TYPE        What is the type of the data in the data field. Nil means we expect no data.
#   4. DATA_SIZE        How big can this field be. I haven't recorded how small, assuming 1, but some records have higher minimum sizes
#   5. ACTION         The action(s) the parser should take to instatiate a class and/or store the value portion of the GEDCOM line.
#                     The Action tags are processed in order. A class tag changes the target class of field, key and xref tags.
#                     -   [:class, :class_name] inidicates this line, and any further data, will be stored in the class  :class_name
#                     -   [:pop] indicates that data will now be stored in the previous class.
#                     -   [:field, :fieldname] indicates that the data part of the line will be stored in the field :field_name
#                     -   [:field, [:fieldname, value]]  fieldname stores the given value.
#                     -   [:append, :fieldname] indicates that the data part of the line will be appended to this field
#                     -   [:append_nl, :fieldname] indicates that the data part of the line will be appended to this field, after first appending a nl
#                     -   [:xref, [:field, :record_type]] indicates that the xref value of the line will get stored in the named field and points to the record_type.
#                     -   [:key, :index_name] means we need to create an index entry, in the index index_name, for this items xref value.
#                     -   nil in this field indicates that we should ignore this TAG and its children.
# 6. DATA_DESCRIPTION Comment to indicate purpose of the gedcom TAG at this level.

class GedcomParser
  
  attr_reader :transmission
  
  CHILD_RECORD = 0    #This is the key to the child level tag description lines.
  MIN_OCCURANCES = 1  #What is the minimum number of times we should see this field. Usually 0 or 1
  MAX_OCCURANCES = 2  #How many times can this tag appear at this level. Nil means any number of times
  DATA_TYPE = 3       #What is the type of the data in the data field. Nil means we expect no data.
  DATA_SIZE = 4       #How big can this field be
  ACTION = 5          #The action(s) the parser should take to instatiate a class and/or store the value portion of the GEDCOM line.
  DATA_DESCRIPTION = 6 #Comment to indicate purpose of the gedcom TAG at this level.

  TAGS = {
    :transmission =>  
    {
      ["HEAD", nil]		=> [:header,						  1,	1, 	  nil, 				0,	[ [:class, :header_record] ],                                 "File Header"],
      ["SUBM", :xref]	=> [:submitter_record,		0,	1,	  nil,				0,	[ [:class, :submitter_record], [:xref, [:submitter_ref, :submitter]], [:key, :submitter] ],          "File's Submitter Record"],	
      ["FAM", :xref]	=> [:family_record,				0,	nil,	nil,				0,	[ [:class, :family_record],    [:xref, [:family_ref, :family]], [:key, :family] ],            "Family Record"	],
      ["INDI", :xref]	=> [:individual_record,		0,	nil,	nil,				0,	[ [:class, :individual_record], [:xref, [:individual_ref, :individual]], [:key, :individual] ],        "Individual Record"	],
      ["SOUR", :xref]	=> [:source_record,				0,	nil,	nil,				0,	[ [:class, :source_record],     [:xref, [:source_ref, :source]], [:key, :source] ],            "Source Record"	],
      ["OBJE", :xref]	=> [:multimedia_record,		0,	nil,	nil,				0,	[ [:class, :multimedia_record], [:xref, [:multimedia_ref, :multimedia]], [:key, :multimedia] ],          "Multimedia Object"	],
      ["NOTE", :xref]	=> [:note_record,			    0,	nil, :string,		248,  [ [:class, :note_record],  [:xref, [:note_ref, :note]], [:key, :note], [:field, :note] ],  "Note Record"	],
      ["REPO", :xref]	=> [:repository_record,		0,	nil,	nil,				0,	[ [:class, :repository_record], [:xref, [:repository_ref, :repository]], [:key, :repository] ],        "Repository Record"	],
      ["SUBN", :xref]	=> [:submission_record,		0,	nil,	nil,				0,  [ [:class, :submission_record], [:xref, [:submission_ref, :submission]], [:key, :submission] ],        "Submission Record"	],
      ["NOTE", :user]	=>  [:user_subtag,	      0,	nil, :string,	248,    [ [:class, :note_record],  [:xref, [:note_ref, :note]], [:key, :note], [:field, :note] ],  "Treat Unknown Tags as Single line notes"	],
      ["TRLR", nil]   => [nil,		              1,	1, 	  nil, 				0,	[ [:class, :trailer_record], [:pop] ],                                                          "End of Data Line"	],
    },
    
		:header =>  
    {
      ["SOUR", nil]		=> [:header_source,   1,	1, :identifier, 20,   [ [:class, :header_source_record], [:field, :approved_system_id] ], "Source System's Registered Name"	],
      ["DEST", nil]		=> [nil,		          0,	1, :identifier, 20,   [ [:field, :destination] ],                                           "Destination System's Registered Name"	],
      ["DATE", nil]		=> [:date_structure,  0,	1, :date_exact, 11,   [ [:class, :date_record], [:field, :date_value] ],                         "Transmission Date"	],
      ["SUBM", :xref]	=> [nil,		          1,	1,	nil,        0,    [ [:xref, [:submitter_ref, :submitter]] ],                        "Reference to a Submitter Record"	],
      ["SUBN", :xref]	=> [nil,		          0,	1,	nil,        0,    [ [:xref, [:submission_ref, :submission]] ],                      "Reference to a Submission Record"		],
      ["FILE", nil]		=> [nil,		          0,	1, :string,			90,   [ [:field, :file_name] ],                                             "This files name"	],
      ["COPR", nil]		=> [nil,	0,	1, :string,			90,   [  [:field, :copyright] ],                                            "Copyright Notice for this file"	],
      ["GEDC", nil]		=> [:header_gedc,     1,	1,	nil,        0,    [ [:class, :gedcom_record] ],                                         "GEDCOM Info"	],
      ["CHAR", nil]		=> [:header_char,     1,	1, :char_set_id,8,    [ [:class, :character_set_record], [:field, :char_set_id] ],        "Character Set"	],
      ["LANG", nil]		=> [nil,              0,	1, :language_id,15,   [ [:field, :language_id] ],                                           "Language of Text"	],
      ["PLAC", nil]		=> [:header_plac,     0,	1,	nil,        0,    [ [:class, :place_record] ],                                          "Default's for Places"	],
      ["NOTE", nil]		=> [:note_cont_conc,  0,	1, :string,  		248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "File Content Description"	],
      ["NOTE", :user]	=> [:user_subtag,	    0,	nil, :string,	  248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
    
		:header_source =>
    { 
      ["VERS", nil]		=>  [nil,		                0,	1, :string,		15, [ [:field, :version] ],                                      "Program's Version :number"],
      ["NAME", nil]		=>  [nil,		                0,	1, :string,		90, [ [:field, :name] ],                                        "Program's Name"	],
      ["CORP", nil]		=>  [:header_source_corp,   0,	1, :string,		90, [ [:class, :corporate_record], [:field, :company_name] ], "Company name the produced the Pragram" 	],
      ["DATA", nil]		=>  [:header_source_data,   0,	1, :string,		90, [ [:class, :header_data_record], [:field, :data_source] ],       "Identifies Data Source Record"],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:header_source_corp =>  
    {
      ["ADDR", nil]		=>  [:address_structure, 0,	1, :string,			60, [ [:class, :address_record], [:field, :address] ],  "Address"	],
      ["PHON", nil]		=>  [nil,		            0,	3, :string,			25, [ [:field, :phonenumber] ],                            "Phone :number"	],
      #Added EMAIL,FAX,WWW Gedcom 5.5.1
      ["EMAIL",  nil]		=>  [nil,		                  0,	3, :string,			120,   [ [:field, :address_email] ],                          "email address"	],
      ["FAX",  nil]		=>  [nil,		                  0,	3, :string,			60,   [ [:field, :address_fax] ],                          "FAX :number"	],
      ["WWW",  nil]		=>  [nil,		                  0,	3, :string,			120,   [ [:field, :address_web_page] ],                          "Web URL"	],
      #
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:header_source_data => 
    { 
      ["DATE", nil]		=>  [nil,		0,	1, :date_value,	11, [ [:field, :date] ],     "Publication Date"	],
      #copyright has no CONT/CONC option in Gedcom 5.5
      #["COPR", nil]		=> [nil,	          0,	1, :string,			90,   [ [:field, :copyright] ],                                            "Copyright Notice for this file"	],
      #copyright has CONT/CONC option in Gedcom 5.5.1
      ["COPR", nil]		=>  [:copyright_cont_conc,		0,	1, :string,			90, [ [:class, :copyright_record], [:field, :copyright] ],  "Copyright Statement from Data Source"	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:date_structure =>
    {  
      ["TIME",  nil]		=>  [nil,		                 0,	1, :time_val,    12,   [  [:field, :time_value] ],                                 "Time of event"	],
      ["SOUR", :xref]	=>  [:source_citation,					0,	nil,  nil,				0,  [ [:class, :source_citation_record], [:xref, [:source_ref, :source]] ], "Reference to Source Record"	],
      ["SOUR", nil]		=>  [:source_citation_inline,	    0,	nil, :string,	248,  [ [:class, :source_citation_record], [:class, :source_record], [:field, :title] ], "Inline note describing source" 	],
      ["NOTE", :xref]	=>  [:note_structure,         0,	nil,  nil,          0,    [ [:class, :note_citation_record], [:xref, [:note_ref, :note]] ],                "Link to a Note Record"	], #Not legal gedcom 5.5
      ["NOTE",  nil]		=>  [:note_structure_inline,  0,	nil, :string,      248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ],      "Inline Note Record"	], #Not legal gedcom 5.5
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:header_gedc =>
    { 
      ["VERS", nil]		=>  [nil,		1,	1, :string,				15, [ [:field, :version] ],          "Version of GEDCOM"	],
      ["FORM", nil]		=>  [nil,		1,	1, :string,				20, [ [:field, :encoding_format] ],  "GEDCOM Encoding Format"	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:header_char =>  
    {
      ["VERS", nil]		=>  [nil,		0,	1, :string,				15, [ [:field, :version] ], "Character Set Version"	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:header_plac =>  
    {
      ["FORM", nil]		=>  [nil,		1,	1, :placehierachy, 120, [ [:field, :place_hierachy] ], "Default Place Hierachy (comma separarted jurisdictions)"],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:note_cont_conc => 
    {
      ["CONT", nil]		=>  [nil,		0,	nil, :string,			248, [ [:append_nl, :note] ], "Continuation on New Line"],
      ["CONC", nil]		=>  [nil,		0,	nil, :string,			248, [ [:append, :note] ], "Continuation on Same Line"	],
    },
    #copyright has CONT/CONC option in Gedcom 5.5.1
		:copyright_cont_conc => 
    {
      ["CONT", nil]		=>  [nil,		0,	nil, :string,			248, [ [:append_nl, :copyright] ], "Continuation on New Line"],
      ["CONC", nil]		=>  [nil,		0,	nil, :string,			248, [ [:append, :copyright] ], "Continuation on Same Line"	],
    },
		:family_record =>  
    {
      #RESN is not standard gedcom.
      ["RESN", nil]		=>  [nil,		                    0,	1, :restriction_value,	7, [ [:field, :restriction] ], "Record Locked or Parts removed for Privacy"	], #NOT GEDCOM 5.5, but in 5.5.1
 
      ["ANUL", nil]		=>  [:family_event_detail,   0,  nil, :y_or_null,	1,  [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "ANUL"]] ], "Annulment"	],
      ["CENS", nil]		=>  [:family_event_detail,   0,	nil, :y_or_null,	1,  [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "CENS"]] ], "Census"	],
      ["DIV",  nil]		=>  [:family_event_detail,   0,	nil, :y_or_null,	1,  [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "DIV"]] ], "Divorce"	],
      ["DIVF", nil]		=>  [:family_event_detail,   0,	nil, :y_or_null,	1,  [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "DIVF"]] ], "Divorce Filed"	],
      ["ENGA", nil]		=>  [:family_event_detail,   0,	nil, :y_or_null,	1,  [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "ENGA"]] ], "Engagement"	],
      ["MARR", nil]		=>  [:family_event_detail,   0,	nil, :y_or_null,	1,  [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "MARR"]] ], "Marriage"	],
      ["MARB", nil]		=>  [:family_event_detail,   0,	nil, :y_or_null,	1,  [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "MARB"]] ], "Marriage Bann"	],
      ["MARC", nil]		=>  [:family_event_detail,   0,	nil, :y_or_null,	1,  [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "MARC"]] ], "Marriage Contract"	],
      ["MARL", nil]		=>  [:family_event_detail,   0,	nil, :y_or_null,	1,  [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "MARL"]] ], "Marriage License"	],
      ["MARS", nil]		=>  [:family_event_detail,   0,	nil, :y_or_null,	1,  [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "MARS"]] ], "Marriage Settlement Agreement"	],
      ["EVEN", nil]		=>  [:family_event_detail,   0,  nil,	nil,				0,  [ [:class, :event_record], [:field, [:event_type, "EVEN"]] ], "Any Other Event"	],
      ["RESI", nil]		=>  [:event_detail,				   0,  nil,	:y_or_null,				0,  [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "RESI"]] ], "Residence"	], #NOT Standard gedcom 5.5

      ["HUSB", :xref]	=>  [:attached_note,		      0,  1,	  nil,				0,  [ [:xref, [:husband_ref, :individual]], [:push] ], "Husband and/or Biological Father of the Children"	],
      ["WIFE", :xref]	=>  [:attached_note,		      0,  1,	  nil,				0,  [ [:xref, [:wife_ref, :individual]], [:push] ],    "Wife and/or Biological Mother of the Children"	],
      ["CHIL", :xref]	=>  [:attached_note,		      0,  nil,	nil,				0,  [ [:xref, [:child_ref, :individual]], [:push] ],   "Child"		],
      ["NCHI", nil]		=>  [nil,		                  0,  1,    :number,		3,  [ [:field, :number_children] ],                  "Total :number of Children"	],
      ["SUBM", :xref]	=>  [nil,		                  0,  nil,	nil,				0,  [ [:xref, [:submitter_ref, :submitter]] ],"Submitter of Record's Information"	],

      ["SLGS", nil]		=>  [:lds_individual_ordinance_slgs,	0,	nil, :y_or_null,0,  [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "SLGS"]]],                "LDS Spouse Sealing Record"	],
      ["SOUR", :xref]	=>  [:source_citation,					0,	nil,  nil,				0,  [ [:class, :source_citation_record], [:xref, [:source_ref, :source]] ], "Reference to Source Record"	],
      ["SOUR", nil]		=>  [:source_citation_inline,	    0,	nil, :string,	248,  [ [:class, :source_citation_record], [:class, :source_record], [:field, :title] ], "Inline note describing source" 	],
      ["OBJE", :xref]	=>  [nil,		                  0,	nil,	nil,				0,  [ [:class, :multimedia_citation_record], [:xref, [:multimedia_ref, :multimedia]], [:pop] ],     "Link to a Multimedia Record"	],
      ["OBJE", nil]		=>  [:multimedia_link,				0,	nil,	nil,				0,  [ [:class, :multimedia_citation_record], [:class, :multimedia_record] ],                 "Inline Multimedia Record"	],
      ["NOTE", :xref]	=>  [:note_structure,				  0,	nil,	nil,				0,  [ [:class, :note_citation_record], [:xref, [:note_ref, :note]] ],        "Link to a Note Record"	],
      ["NOTE", nil]		=>  [:note_structure_inline,	0,	nil,  :string,		248,[ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
      ["REFN", nil]		=>  [:family_record_refn,		  0,	nil,  :string,		20, [ [:class, :refn_record], [:field, :user_reference_number] ], "User Defined Reference :number"	],
      ["RIN",  nil]		=>  [nil,		                  0,	1,    :number,		12, [ [:field, :automated_record_id] ],           "System Generated Record ID"	],
      ["CHAN", nil]		=>  [:change_date,						0,	1,	  nil,				0,  [ [:class, :change_date_record] ],            "Date this Record was Last Modified"	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:family_event_detail =>
    {  
      #RESN is not standard gedcom.
      ["RESN", nil]		=>  [nil,		                    0,	1, :restriction_value,	7, [ [:field, :restriction] ], "Record Locked or Parts removed for Privacy"	], #NOT GEDCOM 5.5, but in 5.5.1

      ["TYPE",  nil]		=>  [nil,		                0,	1, :string,			90,   [ [:field, :event_descriptor] ],                                 "Event Description"	],
      ["DATE",  nil]		=>  [:date_structure,		          0,	1, :date_value,	35,   [ [:class, :date_record], [:field, :date_value] ],       "Events Date(s)"	],
      ["PLAC",  nil]		=>  [:place_structure,        0,	1, :placehierachy,120, [ [:class, :place_record], [:field, :place_value] ],     "Jurisdictional Place Hierachy where the Event Occurred"	],
      ["ADDR",  nil]		=>  [:address_structure,      0,	1, :string,			60,   [ [:class, :address_record], [:field, :address] ], "Address"	],
      ["PHON",  nil]		=>  [nil,		                  0,	3, :string,			25,   [ [:field, :phonenumber] ],                          "Phone :number"	],
      #Added EMAIL,FAX,WWW Gedcom 5.5.1
      ["EMAIL",  nil]		=>  [nil,		                  0,	3, :string,			120,   [ [:field, :address_email] ],                          "email address"	],
      ["FAX",  nil]		=>  [nil,		                  0,	3, :string,			60,   [ [:field, :address_fax] ],                          "FAX :number"	],
      ["WWW",  nil]		=>  [nil,		                  0,	3, :string,			120,   [ [:field, :address_web_page] ],                          "Web URL"	],
      #
      ["AGE",   nil]		=>  [nil,		                  0,	1, :age,				  12,   [ [:field, :age] ],                                  "Age at the time of the Event"	],
      #GEDCOM 5.5.1
      ["RELI",   nil]		=>  [nil,		                  0,	1, :string,				  90,   [ [:field, :religion] ],  "A name of the religion with which this event was affiliated"	],
      ["AGNC",  nil]		=>  [nil,		                  0,	1, :string,			120,  [ [:field, :agency] ],                               "Controlling/Resonsible Entity/Authority"	],
      ["CAUS",  nil]		=>  [:cause_note_structure_inline,0,	1, :string,			90,   [ [:class, :cause_record], [:field, :cause] ],                                "Cause of the Event"	],
      ["SOUR", :xref]	=>  [:source_citation,					0,	nil,  nil,				0,  [ [:class, :source_citation_record], [:xref, [:source_ref, :source]] ], "Reference to Source Record"	],
      ["SOUR", nil]		=>  [:source_citation_inline,	    0,	nil, :string,	248,  [ [:class, :source_citation_record], [:class, :source_record], [:field, :title] ], "Inline note describing source" 	],
      #Subm records in events is not standard gedcom 5.5
      ["SUBM", :xref]	=>  [nil,		                  0,  nil,	nil,				0,  [ [:xref, [:submitter_ref, :submitter]] ],"Submitter of Record's Information"	],
      ["OBJE", :xref]	=>  [nil,		                  0,	nil,	nil,				0,  [ [:class, :multimedia_citation_record], [:xref, [:multimedia_ref, :multimedia]], [:pop] ],     "Link to a Multimedia Record"	],
      ["OBJE", nil]		=>  [:multimedia_link,				0,	nil,	nil,				0,  [ [:class, :multimedia_citation_record], [:class, :multimedia_record] ],                 "Inline Multimedia Record"	],
      ["NOTE", :xref]	=>  [:note_structure,         0,	nil,	nil,				  0,    [ [:class, :note_citation_record], [:xref, [:note_ref, :note]] ],               "Link to a Note Record"	],
      ["NOTE",  nil]		=>  [:note_structure_inline,  0,	nil, :string,			248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ],      "Inline Note Record"	],
      ["HUSB",  nil]		=>  [:family_event_detail_age,0,	1,	  nil,					0,    [ [:class, :event_age_record], [:field, [:relation, "HUSB"]] ], "Husband's Age Record"	],
      ["WIFE",  nil]		=>  [:family_event_detail_age,0,	1,    nil,					0,    [ [:class, :event_age_record], [:field, [:relation, "WIFE"]] ], "Wife's Age Record"	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:family_event_detail_age =>   
    {
      ["AGE", nil]		=>  [nil,		                    1,	1, :age,				  12, [ [:field, :age] ],   "Age at the time of the Event"],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:family_record_refn => 
    {
      ["TYPE", nil]		=>  [nil,		                  0,	1, :string,			40, [ [:field, :ref_type] ],  "User Defined Reference Type"],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:individual_record => 
    {
      ["RESN", nil]		=>  [nil,		                    0,	1, :restriction_value,	7, [ [:field, :restriction] ], "Record Locked or Parts removed for Privacy"	],


      #Internally, we ignore the y_or_null, as both indicate we have to build a record, but we don't need to record, in it, that we did it.
      ["BIRT", nil]		=>  [:individual_event_structure_birt,	0,	nil, :y_or_null,	1, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "BIRT"]] ], "Birth"	],
      ["CHR", nil]		=>   [:individual_event_structure_birt,	0,	nil, :y_or_null,	1, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "CHR"]] ], "Christening"	],
      ["ADOP", nil]		=>  [:individual_event_structure_adop,	0,	nil, :y_or_null,	1, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "ADOP"]] ], "Adoption"	],
      ["DEAT", nil]		=>  [:event_detail,							        0,	nil, :y_or_null,	1, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "DEAT"]] ], "Death"	],
      ["BURI", nil]		=>  [:event_detail,						        	0,	nil, :y_or_null,	1, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "BURI"]] ], "Burial"	],
      ["CREM", nil]		=>  [:event_detail,						        	0,	nil, :y_or_null,	1, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "CREM"]] ], "Cremation"	],
      ["BAPM", nil]		=>  [:event_detail,					        		0,	nil, :y_or_null,	1, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "BAPM"]] ], "Baptism"	],
      ["BARM", nil]		=>  [:event_detail,					        		0,	nil, :y_or_null,	1, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "BARM"]] ], "Bar Mitzvah (13y old Jewish Boys cermonial event)"	],
      ["BASM", nil]		=>  [:event_detail,					        		0,	nil, :y_or_null,	1, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "BASM"]] ], "Bas Mitzvah (13y old Jewish Girls cermonial event)"	],
      ["BLES", nil]		=>  [:event_detail,					        		0,	nil, :y_or_null,	1, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "BLES"]] ], "Blessing"	],
      ["CHRA", nil]		=>  [:event_detail,					        		0,	nil, :y_or_null,	1, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "CHRA"]] ], "Adult Christening"	],
      ["CONF", nil]		=>  [:event_detail,				        			0,	nil, :y_or_null,	1, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "CONF"]] ], "Confirmation"	],
      ["FCOM", nil]		=>  [:event_detail,					        		0,	nil, :y_or_null,	1, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "FCOM"]] ], "First Communion"	],
      ["ORDN", nil]		=>  [:event_detail,				          		0,	nil, :y_or_null,	1, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "ORDN"]] ], "Ordination"	],
      ["NATU", nil]		=>  [:event_detail,					        		0,	nil, :y_or_null,	1, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "NATU"]] ], "Naturalization"	],
      ["EMIG", nil]		=>  [:event_detail,					        		0,	nil, :y_or_null,	1, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "EMIG"]] ], "Emigration"	],
      ["IMMI", nil]		=>  [:event_detail,					        		0,	nil, :y_or_null,	1, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "IMMI"]] ], "Immigration"	],
      ["CENS", nil]		=>  [:event_detail,					        		0,	nil, :y_or_null,	1, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "CENS"]] ], "Census"	],
      ["PROB", nil]		=>  [:event_detail,				        			0,	nil, :y_or_null,	1, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "PROB"]] ], "Probate"	],
      ["WILL", nil]		=>  [:event_detail,				        			0,	nil, :y_or_null,	1, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "WILL"]] ], "Will (Event is date of signing)"	],
      ["GRAD", nil]		=>  [:event_detail,				        			0,	nil, :y_or_null,	1, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "GRAD"]] ], "Graduation"	],
      ["RETI", nil]		=>  [:event_detail,				        			0,	nil, :y_or_null,	1, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "RETI"]] ], "Retirement"	],
      ["BAPL", nil]		=>  [:lds_individual_ordinance_bapl,  	0,	nil,  :y_or_null,	0, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "BAPL"]] ], "LDS Baptisim"	],
      ["CONL", nil]		=>  [:lds_individual_ordinance_bapl,  	0,	nil,	:y_or_null,	0, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "CONL"]] ], "LDS Confirmation"	],
      ["ENDL", nil]		=>  [:lds_individual_ordinance_endl,  	0,	nil,	:y_or_null,	0, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "ENDL"]] ], "LDS Endowment"	],
      ["SLGC", nil]		=>  [:lds_individual_ordinance_slgc,  	0,	nil,	:y_or_null,	0, [ [:class, :event_record], [:field, :event_status], [:field, [:event_type, "SLGC"]] ], "LDS Childs Sealing"	],
      ["EVEN", nil]		=>  [:event_detail,						        	0,	nil,	nil,				0, [ [:class, :event_record], [:field, [:event_type, "EVEN"]] ], "Misc Event"	],
      
      ["NAME", nil]		=>  [:personal_name_structure,	        0,	nil, :name_string,	120,  [ [:class, :name_record], [:field, :value], [:field, [:attr_type,"NAME"]] ], "A Name of the Individual"	],
      ["SEX", nil]		=>  [:event_detail,		                  0,	nil, :sex_value,		1,    [ [:class, :individual_attribute_record], [:field, :value], [:field, [:attr_type,"SEX"]] ], "M or F"	],
      #gedcom 5.5 actually only allows 1 sex record, with no event. The real world says otherwise.
      #It is also possible to have Intersexuals. 
      #There is a spectrum of Male to Female, through varying causes
      #These are the known genetic combinations XX, XY, XXY, XXXY and X only
      #There are also XY people, who appear female or sexless at birth (androgen insensitivity syndrome, or in english, the hormone receptors don't work).
      #There are XX people, who may appear sexless and/or missing some or all of their reproductive organs. 
      #Some of these intersexuals can reproduce as males, females, or rarely, both, most not at all.
      #There is also the modern possibility of gender reassignment, which would require an event record, attached to a second sex record.
      ["TITL", nil]		=>  [:event_detail,						  	0,	nil, :string,			120,  [ [:class, :individual_attribute_record], [:field, :value], [:field, [:attr_type, "TITL"]] ], "Title"	],
      ["CAST", nil]		=>  [:event_detail,							  0,	nil, :string,			90,   [ [:class, :individual_attribute_record], [:field, :value], [:field, [:attr_type,"CAST"]] ], "Caste Name"	],
      ["DSCR", nil]		=>  [:event_detail,							  0,	nil, :string,			248,  [ [:class, :individual_attribute_record], [:field, :value], [:field, [:attr_type,"DSCR"]] ], "Physical Description"	],
      ["EDUC", nil]		=>  [:event_detail,						  	0,	nil, :string,			248,  [ [:class, :individual_attribute_record], [:field, :value], [:field, [:attr_type,"EDUC"]] ], "Scholastic Achievment"	],
      ["IDNO", nil]		=>  [:event_detail,						  	0,	nil, :string,			30,   [ [:class, :individual_attribute_record], [:field, :value], [:field, [:attr_type, "IDNO"]] ], "National ID :number"	],
      ["NATI", nil]		=>  [:event_detail,						  	0,	nil, :string,			120,  [ [:class, :individual_attribute_record], [:field, :value], [:field, [:attr_type, "NATI"]] ], "National or Tribal Origin"	],
      ["NCHI", nil]		=>  [:event_detail,						  	0,	nil, :number,			3,    [ [:class, :individual_attribute_record], [:field, :value], [:field, [:attr_type, "NCHI"]] ], ":number of Children"	],
      ["NMR", nil]		=>  [:event_detail,						  	0,	nil, :number,			3,    [ [:class, :individual_attribute_record], [:field, :value], [:field, [:attr_type, "NMR"]] ], ":number of Marriages"	],
      ["OCCU", nil]		=>  [:event_detail,						  	0,	nil, :string,			90,   [ [:class, :individual_attribute_record], [:field, :value], [:field, [:attr_type, "OCCU"]] ], "Occupation"	],
      ["PROP", nil]		=>  [:event_detail,						  	0,	nil, :string,			248,  [ [:class, :individual_attribute_record], [:field, :value], [:field, [:attr_type, "PROP"]] ], "Real Estate or other Property"	],
      ["RELI", nil]		=>  [:event_detail,						  	0,	nil, :string,			90,   [ [:class, :individual_attribute_record], [:field, :value], [:field, [:attr_type, "RELI"]] ], "Religious Affliliation"	],
      ["RESI", nil]		=>  [:event_detail,						  	0,	nil,	nil,					0,  [ [:class, :individual_attribute_record], [:field, [:value,""]], [:field, [:attr_type, "RESI"]] ], "Residence"	],
      ["SSN", nil]		=>  [:event_detail,							  0,	nil, :string,			11,   [ [:class, :individual_attribute_record], [:field, :value], [:field, [:attr_type, "SSN"]] ], "USA Social Security :number"	],
      ["FACT", nil]		=>  [:event_detail,							  0,	nil, :string,			90,   [ [:class, :individual_attribute_record], [:field, :value], [:field, [:attr_type, "FACT"]] ], "a noteworthy attribute or fact concerning an individual, a group, or an organization"	],
      #ATTR is not standard gedcom 5.5, which has no misc attribute tag.
      #["_ATTR", nil]		=>  [:attribute_detail,					  0,	nil,	:string,			   90,    [ [:class, :individual_attribute_record], [:field, :attr_type] ], "Misc Attribute"	],
      
      ["ALIA", :xref]	=>  [nil,		                    0,	nil,  nil,				0,  [ [:xref, [:alias_ref, :individual]] ], "Reference to possible duplicate Individual Record"		],
      ["FAMC", :xref]	=>  [:child_to_family_link,		  0,	nil,  nil,				0,  [ [:class, :families_individuals], [:field, [:relationship_type, "FAMC"]], [:xref, [:parents_family_ref, :family]] ], "Reference to Parent's Family Record"	],
      ["FAMS", :xref]	=>  [:attached_note,	      	  0,	nil,  nil,				0,  [ [:class, :families_individuals], [:field, [:relationship_type, "FAMS"]], [:xref, [:family_ref, :family]] ], "Reference to Own marriage's Family Record"		],
      ["ASSO", :xref]	=>  [:association_structure,		0,	nil,  nil,				0,  [ [:class, :association_record],  [:xref, [:association_ref, :individual]] ], "Reference to An Associated Individual's Record"		],

      ["SUBM", :xref]	=>  [nil,		                    0,	nil,  nil,				0,  [ [:xref, [:submitter_ref, :submitter]] ], "Reference to Submitter Record"		],
      ["ANCI", :xref]	=>  [nil,		                    0,	nil,  nil,				0,  [ [:xref, [:ancestor_interest_ref, :submitter]] ],  "Reference to Submitter's Record Interested in persons Ancestors"		],
      ["DESI", :xref]	=>  [nil,		                    0,	nil,  nil,				0,  [ [:xref, [:descendant_interest_ref, :submitter]] ], "Reference to Submitter's Record Interested in persons Decendants"	],
      ["SOUR", :xref]	=>  [:source_citation,					0,	nil,  nil,				0,  [ [:class, :source_citation_record], [:xref, [:source_ref, :source]] ], "Reference to Source Record"	],
      ["SOUR", nil]		=>  [:source_citation_inline,	    0,	nil, :string,	248,  [ [:class, :source_citation_record], [:class, :source_record], [:field, :title] ], "Inline note describing source" 	],
      ["OBJE", :xref]	=>  [nil,		                  0,	nil,	nil,				0,  [ [:class, :multimedia_citation_record], [:xref, [:multimedia_ref, :multimedia]], [:pop] ],     "Link to a Multimedia Record"	],
      ["OBJE", nil]		=>  [:multimedia_link,				0,	nil,	nil,				0,  [ [:class, :multimedia_citation_record], [:class, :multimedia_record] ],                 "Inline Multimedia Record"	],
      ["NOTE", :xref]	=>  [:note_structure,					  0,	nil,  nil,				0,  [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
      ["NOTE", nil]		=>  [:note_structure_inline,		  0,	nil, :string,		248,[ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
      ["RFN", nil]		=>  [nil,		                      0,	1, :registered_ref,90, [ [:field, :registered_ref_id] ], "Registered Resource File and Record ID"	],
      ["AFN", nil]		=>  [nil,		                      0,	1, :string,			12, [ [:field, :lds_ancestral_file_no] ], "LDS Ancestral File :number"	],
      ["REFN", nil]		=>  [:family_record_refn,			    0,	nil, :string,		20, [ [:class, :refn_record], [:field, :user_reference_number] ], "User Defined Reference :number"	],
      ["RIN",  nil]		=>  [nil,		                    0,	1, :number,		12, [ [:field, :automated_record_id] ], "System Generated Record ID"	],
      ["CHAN", nil]		=>  [:change_date,						  0,	1,	  nil,				0,  [ [:class, :change_date_record] ], "Date this Record was Last Modified"	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
    
    #These Notes, and Source attachments are non-standard GEDCOM 5.5
		:attached_note =>
    {
      ["SOUR", :xref]	=>  [:source_citation,					0,	nil,  nil,				0,  [ [:class, :source_citation_record], [:xref, [:source_ref, :source]] ], "Reference to Source Record"	],
      ["SOUR", nil]		=>  [:source_citation_inline,	    0,	nil, :string,	248,  [ [:class, :source_citation_record], [:class, :source_record], [:field, :title] ], "Inline note describing source" 	],
      ["NOTE", :xref]	=>  [:note_structure,				0,	nil,  nil,				    0,    [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
      ["NOTE", nil]		=>  [:note_structure_inline,		0,	nil, :string,		    248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },

    #:attribute_detail is Non-Standard gedcom 5.5, which has no such structure, nor is there an ATTR parent tag 
    :attribute_detail =>
    {
      ["_VALU", nil]		=>  [:nil,		                0,	1,    :string,	 90,  [ [:field, :value] ], "Attribute Description"	],
      ["EVEN", nil]		=>  [:event_detail,           0,  nil,	nil,				0,  [ [:class, :event_record] ], "Event associated with this attribute"	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:individual_event_structure_birt =>
    {
      #RESN is not standard gedcom.
      ["RESN", nil]		=>  [nil,		                    0,	1, :restriction_value,	7, [ [:field, :restriction] ], "Record Locked or Parts removed for Privacy"	], #NOT GEDCOM 5.5
 
      ["TYPE", nil]		=>  [nil,		                    0,	1, :string,			  90,   [ [:field, :event_descriptor] ], "Event Description"	],
      ["DATE", nil]		=>  [:date_structure,		            0,	1, :date_value,	  35,   [ [:class, :date_record], [:field, :date_value] ], "Events Date(s)"	], #illegal note attachment, Note gedcom 5.5 compliant.
      ["PLAC", nil]		=>  [:place_structure,					0,	1, :placehierachy,	120,  [ [:class, :place_record], [:field, :place_value] ], "Jurisdictional Place Hierarchy where the Event Occurred"	],
      ["ADDR", nil]		=>  [:address_structure,				0,	1, :string,			  60,   [ [:class, :address_record], [:field, :address] ], "Address"	],
      ["PHON", nil]		=>  [nil,		                    0,	3, :string,			  25,   [ [:field, :phonenumber] ], "Phone :number"	],
      #Added EMAIL,FAX,WWW Gedcom 5.5.1
      ["EMAIL",  nil]		=>  [nil,		                  0,	3, :string,			120,   [ [:field, :address_email] ],                          "email address"	],
      ["FAX",  nil]		=>  [nil,		                  0,	3, :string,			60,   [ [:field, :address_fax] ],                          "FAX :number"	],
      ["WWW",  nil]		=>  [nil,		                  0,	3, :string,			120,   [ [:field, :address_web_page] ],                          "Web URL"	],
      #
      ["AGE", nil]		=>  [nil,		                    0,	1, :age,				    12,   [ [:field, :age] ], "Age at the time of the Event"	],
      #GEDCOM 5.5.1
      ["RELI",   nil]		=>  [nil,		                  0,	1, :string,				  90,   [ [:field, :religion] ],                                  "A name of the religion with which this event was affiliated"	],
      ["AGNC", nil]		=>  [nil,		                    0,	1, :string,			  120,  [ [:field, :agency] ], "Controlling/Resonsible Entity/Authority"	],
      ["CAUS", nil]		=>  [:cause_note_structure_inline,0,	1, :string,			  90,   [ [:class, :cause_record], [:field, :cause] ], "Cause of the Event"	],
      ["SOUR", :xref]	=>  [:source_citation,					0,	nil,  nil,				0,  [ [:class, :source_citation_record], [:xref, [:source_ref, :source]] ], "Reference to Source Record"	],
      ["SOUR", nil]		=>  [:source_citation_inline,	    0,	nil, :string,	248,  [ [:class, :source_citation_record], [:class, :source_record], [:field, :title] ], "Inline note describing source" 	],
      #Subm records in events is not standard gedcom 5.5
      ["SUBM", :xref]	=>  [nil,		                  0,  nil,	nil,				0,  [ [:xref, [:submitter_ref, :submitter]] ],"Submitter of Record's Information"	],
      ["OBJE", :xref]	=>  [nil,		                  0,	nil,	nil,				0,  [ [:class, :multimedia_citation_record], [:xref, [:multimedia_ref, :multimedia]], [:pop] ],     "Link to a Multimedia Record"	],
      ["OBJE", nil]		=>  [:multimedia_link,				0,	nil,	nil,				0,  [ [:class, :multimedia_citation_record], [:class, :multimedia_record] ],                 "Inline Multimedia Record"	],
      ["NOTE", :xref]	=>  [:note_structure,				  0,	nil,  nil,				    0,    [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
      ["NOTE", nil]		=>  [:note_structure_inline,		0,	nil, :string,		  248,    [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
      ["FAMC", :xref]	=>  [:individual_event_structure_adop_famc,	0,	1, nil, 0,    [ [:class, :adoption_record], [:xref, [:birth_family_ref, :family]] ], "Reference to Birth Parent's Family Record"	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:individual_event_structure_adop =>
    {
      #RESN is not standard gedcom.
      ["RESN", nil]		=>  [nil,		                    0,	1, :restriction_value,	7, [ [:field, :restriction] ], "Record Locked or Parts removed for Privacy"	], #NOT GEDCOM 5.5

      ["TYPE", nil]		=>  [nil,		                    0,	1, :string,			  90,   [ [:field, :event_descriptor] ], "Event Description"	],
      ["DATE", nil]		=>  [:date_structure,		            0,	1, :date_value,	  35,   [ [:class, :date_record], [:field, :date_value] ], "Events Date(s)"	], #illegal note attachment, Note gedcom 5.5 compliant.
      ["PLAC", nil]		=>  [:place_structure,					0,	1, :placehierachy,	120,  [ [:class, :place_record], [:field, :place_value] ], "Jurisdictional Place Hierarchy where the Event Occurred"	],
      ["ADDR", nil]		=>  [:address_structure,				0,	1, :string,			  60,   [ [:class, :address_record], [:field, :address] ], "Address"	],
      ["PHON", nil]		=>  [nil,		                    0,	3, :string,			  25,   [ [:field, :phonenumber] ], "Phone :number"	],
      #Added EMAIL,FAX,WWW Gedcom 5.5.1
      ["EMAIL",  nil]		=>  [nil,		                  0,	3, :string,			120,   [ [:field, :address_email] ],                          "email address"	],
      ["FAX",  nil]		=>  [nil,		                  0,	3, :string,			60,   [ [:field, :address_fax] ],                          "FAX :number"	],
      ["WWW",  nil]		=>  [nil,		                  0,	3, :string,			120,   [ [:field, :address_web_page] ],                          "Web URL"	],
      #
      ["AGE", nil]		=>  [nil,		                    0,	1, :age,				    12,   [ [:field, :age] ], "Age at the time of the Event"	],
      #GEDCOM 5.5.1
      ["RELI",   nil]		=>  [nil,		                  0,	1, :string,				  90,   [ [:field, :religion] ],                                  "A name of the religion with which this event was affiliated"	],
      ["AGNC", nil]		=>  [nil,		                    0,	1, :string,			  120,  [ [:field, :agency] ], "Controlling/Resonsible Entity/Authority"	],
      ["CAUS", nil]		=>  [:cause_note_structure_inline,0,	1, :string,			  90,   [ [:class, :cause_record], [:field, :cause] ], "Cause of the Event"	],
      ["SOUR", :xref]	=>  [:source_citation,					0,	nil,  nil,				0,  [ [:class, :source_citation_record], [:xref, [:source_ref, :source]] ], "Reference to Source Record"	],
      ["SOUR", nil]		=>  [:source_citation_inline,	    0,	nil, :string,	248,  [ [:class, :source_citation_record], [:class, :source_record], [:field, :title] ], "Inline note describing source" 	],
      #Subm records in events is not standard gedcom 5.5
      ["SUBM", :xref]	=>  [nil,		                  0,  nil,	nil,				0,  [ [:xref, [:submitter_ref, :submitter]] ],"Submitter of Record's Information"	],
      ["OBJE", :xref]	=>  [nil,		                  0,	nil,	nil,				0,  [ [:class, :multimedia_citation_record], [:xref, [:multimedia_ref, :multimedia]], [:pop] ],     "Link to a Multimedia Record"	],
      ["OBJE", nil]		=>  [:multimedia_link,				0,	nil,	nil,				0,  [ [:class, :multimedia_citation_record], [:class, :multimedia_record] ],                 "Inline Multimedia Record"	],
      ["NOTE", :xref]	=>  [:note_structure,				  0,	nil,  nil,				    0,    [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
      ["NOTE", nil]		=>  [:note_structure_inline,		0,	nil, :string,		  248,    [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
      ["FAMC", :xref]	=>  [:individual_event_structure_adop_famc,	0,	1, nil, 0,    [ [:class, :adoption_record], [:xref, [:adopt_family_ref, :family]] ], "Reference to Adopt Parent's Family Record"	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:individual_event_structure_adop_famc =>  # /*note reuse of ADOP!!*/
    {
      ["ADOP", nil]		=>  [nil,		                  0,	1, :whichparent,	    4,    [ [:field, :adopted_by] ], "Adopted by HUSB | WIFE | BOTH"	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:multimedia_record =>
    { #Record form
      #GEDCOM 5.5.1 form has FILE and SOUR records
      ["FILE", nil]		=>  [:multimedia_obje_file_record,	0,	nil, :string,		120,   [ [:class, :multimedia_obje_file_record], [:field, :filename] ], " local or remote file reference to the auxiliary data"	],
      ["SOUR", :xref]	=>  [:source_citation,					0,	nil,  nil,				0,  [ [:class, :source_citation_record], [:xref, [:source_ref, :source]] ], "Reference to Source Record"	],
      ["SOUR", nil]		=>  [:source_citation_inline,	    0,	nil, :string,	248,  [ [:class, :source_citation_record], [:class, :source_record], [:field, :title] ], "Inline note describing source" 	],      
      #GEDCOM 5.5 Only, some non-standard variants have a +1 MEDI tag after the FORM tag
      ["FORM", nil]		=>  [:multimedia_format_record,		                  1,	1, :string,	    4,    [ [:class, :multimedia_format_record], [:field, :format] ], "bmp | gif | jpeg | ole | pcx | tiff | wav |..."	],
      ["TITL", nil]		=>    [nil,		                    0,	1, :string,			248,  [ [:field, :title] ], "Title of the work"	],
      ["BLOB", nil]		=>    [:encoded_multimedia_line,	1,	1,	  nil,			0,    [ [:class, :encoded_line_record] ], "Binary Object"	],
      ["OBJE", :xref]	=>  [nil,		                    0,	nil,  nil,				0,    [ [:xref, [:next_multimedia_ref, :multimedia]] ], "Link to a continued Multimedia Record"	],
      #Common to 5.5 and 5.5.1
      ["NOTE", :xref]	=>  [:note_structure,				    0,	nil,  nil,    	  0,    [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
      ["NOTE", nil]		=>    [:note_structure_inline,		0,	nil, :string,		248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
      #Blob's go away in 5.5.1
      ["REFN", nil]		=>    [:family_record_refn,			  0,	nil, :string,		20,   [ [:class, :refn_record], [:field, :user_reference_number] ], "User Defined Reference :number"	],
      ["RIN",  nil]		=>  [nil,		                    0,	1, :number,		    12,   [ [:field, :automated_record_id] ], "System Generated Record ID"	],
      ["CHAN", nil]		=>  [:change_date,						  0,	1,	  nil,				0,    [ [:class, :change_date_record] ], "Date this Record was Last Modified"	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
    :multimedia_obje_file_record =>
    { #GEDCOM 5.5.1 multimedia file references, rather than inline blobs.
      #TITL is at the previous level in the link form.
      ["TITL", nil]		=>    [nil,		                        0,	1, :string,			248,  [ [:field, :title] ], "Title of the work"	],
      ["FORM", nil]		=>  [:multimedia_obje_format_record,	0,	1, :string,		4,   [ [:class, :multimedia_obje_format_record], [:field, :format] ], "bmp | gif | jpeg | ole | pcx | tiff | ..."	],
      #Non-standard note field to allow for user defined tags.
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
      ["NOTE", :xref]	=> [:note_structure,				  0,	nil,  nil,		  0,    [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
      ["NOTE", nil]		=>  [:note_structure_inline,	0,	nil, :string,		248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
    },
    :multimedia_file_record =>
    { #GEDCOM 5.5.1 multimedia file references, rather than inline blobs.
      #TITL is at the previous level in the link form.
      #["TITL", nil]		=>    [nil,		                        0,	1, :string,			248,  [ [:field, :title] ], "Title of the work"	],
      ["FORM", nil]		=>  [:multimedia_format_record,	0,	1, :string,		4,   [ [:class, :multimedia_format_record], [:field, :format] ], "bmp | gif | jpeg | ole | pcx | tiff | ..."	],
      #Non-standard note field to allow for user defined tags.
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
      ["NOTE", :xref]	=> [:note_structure,				  0,	nil,  nil,		  0,    [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
      ["NOTE", nil]		=>  [:note_structure_inline,	0,	nil, :string,		248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
    },
    :multimedia_obje_format_record =>
    { #GEDCOM 5.5.1 multimedia file references, rather than inline blobs.
      #multimedia records use TYPE, where multimedia references use MEDI (Why?)
      ["TYPE", nil]		=>  [nil,	0,	1, :string,		15,   [ [:field, :media_type] ], " audio | book | card | electronic | fiche | film | magazine | manuscript | map | newspaper | photo | tombstone | video"	],
      #Not standard, but I've seen this form and we might as well recognise it.
      ["MEDI", nil]		=>  [nil,	0,	1, :string,		15,   [ [:field, :media_type] ], " audio | book | card | electronic | fiche | film | magazine | manuscript | map | newspaper | photo | tombstone | video"	],
      #Non-standard note field to allow for user defined tags.
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
      ["NOTE", :xref]	=> [:note_structure,				  0,	nil,  nil,		  0,    [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
      ["NOTE", nil]		=>  [:note_structure_inline,	0,	nil, :string,		248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
    },
    :multimedia_format_record =>
    { #GEDCOM 5.5.1 multimedia file references, rather than inline blobs.
      #multimedia records use TYPE, where multimedia references use MEDI (Why?)
      ["MEDI", nil]		=>  [nil,	0,	1, :string,		15,   [ [:field, :media_type] ], " audio | book | card | electronic | fiche | film | magazine | manuscript | map | newspaper | photo | tombstone | video"	],
      #Unlikely to see as TYPE tag, but to be consistent with multimedia_obje_format_record, I've included it. 
      ["TYPE", nil]		=>  [nil,	0,	1, :string,		15,   [ [:field, :media_type] ], " audio | book | card | electronic | fiche | film | magazine | manuscript | map | newspaper | photo | tombstone | video"	],
      #Non-standard note field to allow for user defined tags.
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
      ["NOTE", :xref]	=> [:note_structure,				  0,	nil,  nil,		  0,    [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
      ["NOTE", nil]		=>  [:note_structure_inline,	0,	nil, :string,		248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
    },
		:multimedia_link =>
    { #/* in line link form*/
      #GEDCOM 5.5.1
      #Reploces 5.5 FILE's filename with GEDCOM 5.5.1 class, but has a method in this class to return the first FILE filename, hence give the 5.5 behaviour
      #I have reused the Multimedia record's multimedia_file_record, which treats TYPE an MEDI as equivalent, but outputs only MEDI. 
      #It also has TITL as a subordinate tag of FILE, which makes more sense if there are multiple FILE tags allowed, though not if the 
      #purpose of multiple FILE tags is to collect parts of one object, rather than a collection of related objects.
      ["FILE", nil]		=>  [:multimedia_file_record,	0,	nil, :string,		120,   [ [:class, :multimedia_file_record], [:field, :filename] ], " local or remote file reference to the auxiliary data"	],
      ["FORM", nil]		=>  [:multimedia_format_record,		                  1,	1, :string,	    4,    [ [:class, :multimedia_format_record], [:field, :format] ], "bmp | gif | jpeg | ole | pcx | tiff | wav |..."	],
      #GEDCOM 5.5
      ["TITL", nil]		=>  [nil,		                  0,	1, :string,			248,  [ [:field, :title] ], "Title of the work"	],
      ["NOTE", :xref]	=> [:note_structure,				  0,	nil,  nil,		  0,    [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
      ["NOTE", nil]		=>  [:note_structure_inline,	0,	nil, :string,		248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
      #Filename max length is a touch on the short side, so have altered it to 248 (was 30) to avoid lots of annoying warning messages
      #GEDCOM 5.5 ["FILE", nil]		=>  [nil,		                  1,	1, :string,			248,  [ [:field, :filename] ], "Multimedia Data's Filename"	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:encoded_multimedia_line =>
    {
      ["CONT", nil]		=>  [nil,		                  1,	nil, :string,					87, [ [:append_nl, :encoded_line] ], "ASCII Encoded Multimedia Line"	],
    },
		:note_record =>
    {
       ["RESN", nil]		=>  [nil,		                    0,	1, :restriction_value,	7, [ [:field, :restriction] ], "Record Locked or Parts removed for Privacy"	], #NOT GEDCOM 5.5
    	 ["CONT", nil]		=>  [nil,		                  0,	nil, :string,		248,    [ [:append_nl, :note] ], "Continuation on New Line"],
    	 ["CONC", nil]		=>  [nil,		                  0,	nil, :string,		248,    [ [:append, :note] ], "Continuation on Same Line"	],
       ["SOUR", :xref]	=>  [:source_citation,					0,	nil,  nil,				0,  [ [:class, :source_citation_record], [:xref, [:source_ref, :source]] ], "Reference to Source Record"	],
       ["SOUR", nil]		=>  [:source_citation_inline,	    0,	nil, :string,	248,  [ [:class, :source_citation_record], [:class, :source_record], [:field, :title] ], "Inline note describing source" 	],
       ["REFN", nil]		=>  [:family_record_refn,		  0,	nil, :string,	  20,     [ [:class, :refn_record], [:field, :user_reference_number] ], "User Defined Reference :number"	],
       ["RIN",  nil]		=>  [nil,		                  0,	1, :number,	  12,       [ [:field, :automated_record_id] ], "System Generated Record ID"	],
       ["CHAN", nil]		=>  [:change_date,						0,	1,	  nil,				  0,  [ [:class, :change_date_record] ], "Date this Record was Last Modified"	],
       ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:note_structure =>
    {
      ["RESN", nil]		=>  [nil,		                    0,	1, :restriction_value,	7, [ [:field, :restriction] ], "Record Locked or Parts removed for Privacy"	], #NOT GEDCOM 5.5
      ["SOUR", :xref]	=>  [:source_citation,					0,	nil,  nil,				0,  [ [:class, :source_citation_record], [:xref, [:source_ref, :source]] ], "Reference to Source Record"	],
      ["SOUR", nil]		=>  [:source_citation_inline,	    0,	nil, :string,	248,  [ [:class, :source_citation_record], [:class, :source_record], [:field, :title] ], "Inline note describing source" 	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:note_structure_inline =>
    {
      ["RESN", nil]		=>  [nil,		                    0,	1, :restriction_value,	7, [ [:field, :restriction] ], "Record Locked or Parts removed for Privacy"	], #NOT GEDCOM 5.5
      ["CONT", nil]		=>  [nil,		                    0,	nil, :string,			  248,  [ [:append_nl, :note] ], "Continuation on New Line"],
      ["CONC", nil]		=>  [nil,		                    0,	nil, :string,			  248,  [ [:append, :note] ], "Continuation on Same Line"	],
      ["SOUR", :xref]	=>  [:source_citation,					0,	nil,  nil,				0,  [ [:class, :source_citation_record], [:xref, [:source_ref, :source]] ], "Reference to Source Record"	],
      ["SOUR", nil]		=>  [:source_citation_inline,	    0,	nil, :string,	248,  [ [:class, :source_citation_record], [:class, :source_record], [:field, :title] ], "Inline note describing source" 	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:repository_record =>
    {
    	 ["NAME", nil]		=>  [nil,			                0,	1, :string,		90,   [ [:field, :repository_name] ], "Official Name of the Archive" 	],
    	 ["ADDR", nil]		=>  [:address_structure,			0,	1, :string,		60,   [ [:class, :address_record], [:field, :address] ], "Address"	],
    	 ["PHON", nil]		=>  [nil,		                  0,	3, :string,		25,   [ [:field, :phonenumber] ], "Phone :number"	],
       #Added EMAIL,FAX,WWW Gedcom 5.5.1
       ["EMAIL",  nil]		=>  [nil,		                  0,	3, :string,			120,   [ [:field, :address_email] ],                          "email address"	],
       ["FAX",  nil]		=>  [nil,		                  0,	3, :string,			60,   [ [:field, :address_fax] ],                          "FAX :number"	],
       ["WWW",  nil]		=>  [nil,		                  0,	3, :string,			120,   [ [:field, :address_web_page] ],                          "Web URL"	],
       #
       ["NOTE", :xref]	=>  [:note_structure,				  0,	nil,  nil,				  0,  [ [:class, :note_citation_record], [:xref, [:note_ref, :note]] ], "Link to a Note Record"	],
       ["NOTE", nil]		=>  [:note_structure_inline,	0,	nil, :string,		248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
       ["REFN", nil]		=>  [:family_record_refn,		  0,	nil, :string,	  20,   [ [:class, :refn_record], [:field, :user_reference_number] ], "User Defined Reference :number"	],
       ["RIN",  nil]		=>  [nil,		                  0,	1, :number,	  12,   [ [:field, :automated_record_id] ], "System Generated Record ID"	],
       ["CHAN", nil]		=>  [:change_date,						0,	1,	  nil,				  0,  [ [:class, :change_date_record] ], "Date this Record was Last Modified"	],
       ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:source_record =>
    {
    	 ["DATA", nil]		=>   [:source_record_data,			0,	1,	nil,					0,  [ [:class, :source_scope_record] ], "Data Description"	],
    	 ["AUTH", nil]		=>   [:auth_cont_conc,					0,	1, :string,		248,  [ [:field, :author], [:push]], "Person or Entity who created the record"	],
    	 ["TITL", nil]		=>   [:titl_cont_conc,					0,	1, :string,		248,  [ [:field, :title], [:push] ], "Title of the Work"	],
    	 ["ABBR", nil]		=>   [nil,		                  0,	1, :string,		60,   [ [:field, :short_title] ], "Short Title for Filing"	],
    	 ["PUBL", nil]		=>   [:publ_cont_conc,					0,	1, :string,		248,  [ [:field, :publication_details], [:push]], "Publication Details"	],
    	 ["TEXT", nil]		=>   [:text_cont_conc,					0,	1, :string,		248,  [ [:class, :text_record], [:field, :text] ], "Verbatim Copy of the Source Tect"	],
    	 ["REPO", :xref]	=>  [:source_repository_citation,	0,	1,  nil,			0,	[ [:class, :repository_citation_record], [:xref, [:repository_ref, :repository]] ], "Repository Record"	],
       ["OBJE", :xref]	=>  [nil,		                  0,	nil,	nil,				0,  [ [:class, :multimedia_citation_record], [:xref, [:multimedia_ref, :multimedia]], [:pop] ],     "Link to a Multimedia Record"	],
       ["OBJE", nil]		=>  [:multimedia_link,				0,	nil,	nil,				0,  [ [:class, :multimedia_citation_record], [:class, :multimedia_record] ],                 "Inline Multimedia Record"	],
       ["NOTE", :xref]	=> [:note_structure,				  0,	nil,  nil,				0,  [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
       ["NOTE", nil]		=>   [:note_structure_inline,	0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
       ["REFN", nil]		=>  [:family_record_refn,		  0,	nil, :string,	20,   [ [:class, :refn_record], [:field, :user_reference_number] ], "User Defined Reference :number"	],
       ["RIN",  nil]		=>  [nil,		                  0,	1,   :number,	12,   [ [:field, :automated_record_id] ], "System Generated Record ID"	],
       ["CHAN", nil]		=>  [:change_date,						0,	1,	  nil,				0,  [ [:class, :change_date_record] ], "Date this Record was Last Modified"	],
       ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:source_record_data =>
    {
    	 ["EVEN", nil]		=>  [:source_record_data_even,	0,	nil, :eventlist,	90,   [ [:class, :events_list_record], [:field, :recorded_events] ], "List of Events Recorded"	],
    	 ["AGNC", nil]		=>  [nil,	                    0,	1, :string,		120,  [ [:field, :agency] ], "Controlling/Resonsible Entity/Authority"	],
       ["NOTE", :xref]	=> [:note_structure,				  0,	nil,  nil,				  0,  [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
       ["NOTE", nil]		=>   [:note_structure_inline,	0,	nil, :string,	  248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
       ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
    :titl_cont_conc => 
    {
      ["CONT", nil]		=>  [nil,		0,	nil, :string,			248, [ [:append_nl, :title] ], "Continuation on New Line"],
      ["CONC", nil]		=>  [nil,		0,	nil, :string,			248, [ [:append, :title] ], "Continuation on Same Line"	],
    },
		:auth_cont_conc => 
    {
      ["CONT", nil]		=>  [nil,		0,	nil, :string,			248, [ [:append_nl, :author] ], "Continuation on New Line"],
      ["CONC", nil]		=>  [nil,		0,	nil, :string,			248, [ [:append, :author] ], "Continuation on Same Line"	],
    },
		:text_cont_conc => 
    {
      ["CONT", nil]		=>  [nil,		0,	nil, :string,			248, [ [:append_nl, :text] ], "Continuation on New Line"],
      ["CONC", nil]		=>  [nil,		0,	nil, :string,			248, [ [:append, :text] ], "Continuation on Same Line"	],
    },
		:publ_cont_conc => 
    {
      ["CONT", nil]		=>  [nil,		0,	nil, :string,			248, [ [:append_nl, :publication_details] ], "Continuation on New Line"],
      ["CONC", nil]		=>  [nil,		0,	nil, :string,			248, [ [:append, :publication_details] ], "Continuation on Same Line"	],
    },
		:source_record_data_even =>
    {
    	 ["DATE", nil]		=>  [nil,		            0,	1, :date_period,	  35,   [ [:field, :date_period] ], "Period Covered by Source"	],
       ["PLAC", nil]		=>  [:place_structure,		0,	1, :placehierachy,	120,  [ [:class, :place_record], [:field, :place_value] ], "Jurisdictional Place Hierarchy where the Event Occurred"	],
       ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:submission_record =>
    {
    	 ["SUBM", :xref]	=>  [nil,		0,	1,  nil,				  0,    [ [:xref,  [:submitter_ref, :submitter]] ], "Reference to Submitter Record"		],
    	 ["FAMF", nil]		=>  [nil,		0,	1, :string,			120,  [ [:field, :lds_family_file] ], "LDS Family Name for Temple Family File"	],
    	 ["TEMP", nil]		=>  [nil,		0,	1, :string,			5,    [ [:field, :lds_temple_code] ], "Abbreviated LDS Temple Code"	],
    	 ["ANCE", nil]		=>  [nil,		0,	1, :number,			4,    [ [:field, :generations_of_ancestor] ], ":number of generations of Ancestors in this FIle"	],
    	 ["DESC", nil]		=>  [nil,		0,	1, :number,			4,    [ [:field, :generations_of_descendant] ], ":number of generations of Descendants in the File" 	],
    	 ["ORDI", nil]		=>  [nil,		0,	1, :yesno,		  	3,    [ [:field, :process_ordinates] ], "Yes/No (LDS: process for clearing temple ordinances"	],
       ["RIN",  nil]		=>  [nil,		0,	1, :number,	   12,    [ [:field, :automated_record_id] ], "System Generated Record ID"	],
       ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:submitter_record =>
    {
    	 ["NAME", nil]		=>  [nil,		                  1,	1, :string,	  60,    [ [:class, :name_record], [:field, :value], [:field, [:attr_type,"NAME"]] , [:pop] ], "Name of the Submitter"	],
    	 ["ADDR", nil]		=>  [:address_structure,			0,	1, :string,		60,   [ [:class, :address_record], [:field, :address] ], "Address"	],
    	 ["PHON", nil]		=>  [nil,		                  0,	3, :string,		25,   [ [:field, :phone] ], "Phone :number"	],
       #Added EMAIL,FAX,WWW Gedcom 5.5.1
       ["EMAIL",  nil]		=>  [nil,		                  0,	3, :string,			120,   [ [:field, :address_email] ],                          "email address"	],
       ["FAX",  nil]		=>  [nil,		                  0,	3, :string,			60,   [ [:field, :address_fax] ],                          "FAX :number"	],
       ["WWW",  nil]		=>  [nil,		                  0,	3, :string,			120,   [ [:field, :address_web_page] ],                          "Web URL"	],
       #
       ["OBJE", :xref]	=>  [nil,		                  0,	nil,	nil,				0,  [ [:class, :multimedia_citation_record], [:xref, [:multimedia_ref, :multimedia]], [:pop] ],     "Link to a Multimedia Record"	],
       ["OBJE", nil]		=>  [:multimedia_link,				0,	nil,	nil,				0,  [ [:class, :multimedia_citation_record], [:class, :multimedia_record] ],                 "Inline Multimedia Record"	],
    	 ["LANG", nil]		=>  [nil,		                  0,	3, :languagepreference,	90, [ [:field, :language_list] ], "Ordered List of Prefered Language IDs"	],
    	 ["RFN", nil]		=>  [nil,		                  0,	1, :string,	    30, [ [:field, :lds_submitter_id] ], "LDS Submitters registration :number"	],
       ["RIN",  nil]		=>  [nil,		                  0,	1, :number,	  12,   [ [:field, :automated_record_id] ], "System Generated Record ID"	],
       ["CHAN", nil]		=>  [:change_date,						0,	1,	  nil,				  0,  [ [:class, :change_date_record] ], "Date this Record was Last Modified"	],
       #Notes in SUBM records are not part of the gedcom 5.5 standard 
       ["NOTE", :xref]	=>  [:note_structure,				0,	nil,  nil,				    0,    [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
       ["NOTE", nil]		=>  [:note_structure_inline,		0,	nil, :string,		    248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
       ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:address_structure =>
    {
      #RESN is not standard gedcom.
      ["RESN", nil]		=>  [nil,		                    0,	1, :restriction_value,	7, [ [:field, :restriction] ], "Record Locked or Parts removed for Privacy"	], #NOT GEDCOM 5.5

    	 ["CONT", nil]		=>  [nil,		0,	nil, :string,			60, [ [:append_nl, :address] ], "Address Continuation on New Line"],
    	 ["ADR1", nil]		=>  [nil,		0,	1, :string,			60, [ [:field, :address_line1] ], "Formated Address Line 1"	],
    	 ["ADR2", nil]		=>  [nil,		0,	1, :string,			60, [ [:field, :address_line2] ], "Formated Address Line 2"	],
    	 ["CITY", nil]		=>  [nil,		0,	1, :string,			60, [ [:field, :city] ], "City"],	
    	 ["STAE", nil]		=>  [nil,		0,	1, :string,			60, [ [:field, :state] ], "State"],
    	 ["POST", nil]		=>  [nil,		0,	1, :string,			10, [ [:field, :post_code] ], "Postal Code"],
    	 ["CTRY", nil]		=>  [nil,		0,	1, :string,			60, [ [:field, :country] ], "Country"],
    	 ["TYPE", nil]		=>  [nil,    0,  1, :string,      16, [ [:field, :address_type] ], "Home, Country, ..."], #Non Standard Gedcom 5.5
       ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:association_structure =>
    {
    	 ["TYPE", nil]		=>  [nil,		                  1,	1, :recordtype,	  4,      [ [:field, :associated_record_tag] ], "Associated with FAM,INDI,NOTE,OBJE,REPO,SOUR,SUBM or SUBN"	],
    	 ["RELA", nil]		=>  [nil,		                  1,	1, :string,			  25,     [ [:field, :relationship_description] ], "Relationship"],
       ["SOUR", :xref]	=>  [:source_citation,					0,	nil,  nil,				0,  [ [:class, :source_citation_record], [:xref, [:source_ref, :source]] ], "Reference to Source Record"	],
       ["SOUR", nil]		=>  [:source_citation_inline,	    0,	nil, :string,	248,  [ [:class, :source_citation_record], [:class, :source_record], [:field, :title] ], "Inline note describing source" 	],
       ["NOTE", :xref]	=> [:note_structure,				0,	nil,  nil,				    0,      [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
       ["NOTE", nil]		=>  [:note_structure_inline,		0,	nil, :string,		  248,    [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
       ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:change_date =>
    {
    	 ["DATE", nil]		=>  [:date_structure,						  1,	1, :date_exact,	11,   [ [:class, :date_record], [:field, :date_value] ], "Date Record Last Changed"	],
       ["NOTE", :xref]	=> [:note_structure,				  0,	nil,  nil,				    0,  [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
       ["NOTE", nil]		=>  [:note_structure_inline,		0,	nil, :string,		  248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
       ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:child_to_family_link =>
    {
   	 ["PEDI", nil]		=>  [nil,		                  0,	nil, :pedigree,		  7, [ [:field, :pedigree] ], "Pedigree adopted,birth,foster or sealing"	],
     #Added STAT Gedcom version 5.5.1
  	 ["STAT", nil]		=>  [nil,		                  0,	nil, :child_linkage_status,	15, [ [:field, :child_linkage_status] ], "Opinion challenged,disproven,proven"	],
       ["NOTE", :xref]	=> [:note_structure,				  0,	nil,  nil,				    0,  [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
       ["NOTE", nil]		=>  [:note_structure_inline,		0,	nil, :string,		  248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
       ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:event_detail =>
    {
      #RESN is not standard gedcom.
      ["RESN", nil]		=>  [nil,		                    0,	1, :restriction_value,	7, [ [:field, :restriction] ], "Record Locked or Parts removed for Privacy"	], #NOT GEDCOM 5.5, but in 5.5.1
 
       ["TYPE", nil]		=>  [nil,		                    0,	1, :string,			  90,   [ [:field, :event_descriptor] ], "Event Description"	],
       ["DATE", nil]		=>  [:date_structure,		            0,	1, :date_value,	  35,   [ [:class, :date_record], [:field, :date_value] ], "Events Date(s)"	], #illegal note attachment, Note gedcom 5.5 compliant.
       ["PLAC", nil]		=>  [:place_structure,					0,	1, :placehierachy,	120,  [ [:class, :place_record], [:field, :place_value ]], "Jurisdictional Place Hierarchy where the Event Occurred"	],
       ["ADDR", nil]		=>  [:address_structure,				0,	1, :string,			  60,   [ [:class, :address_record], [:field, :address] ], "Address"	],
       ["PHON", nil]		=>  [nil,		                    0,	3, :string,			  25,   [ [:field, :phonenumber] ], "Phone :number"	],
       #Added EMAIL,FAX,WWW Gedcom 5.5.1
       ["EMAIL",  nil]		=>  [nil,		                  0,	3, :string,			120,   [ [:field, :address_email] ],                          "email address"	],
       ["FAX",  nil]		=>  [nil,		                  0,	3, :string,			60,   [ [:field, :address_fax] ],                          "FAX :number"	],
       ["WWW",  nil]		=>  [nil,		                  0,	3, :string,			120,   [ [:field, :address_web_page] ],                          "Web URL"	],
       #
       ["AGE", nil]		=>  [nil,		                    0,	1, :age,				    12,   [ [:field, :age] ], "Age at the time of the Event"	],
       #GEDCOM 5.5.1
       ["RELI",   nil]		=>  [nil,		                  0,	1, :string,				  90,   [ [:field, :religion] ],                                  "A name of the religion with which this event was affiliated"	],
       ["AGNC", nil]		=>  [nil,		                    0,	1, :string,			  120,  [ [:field, :agency] ], "Controlling/Resonsible Entity/Authority"	],
       ["CAUS", nil]		=>  [:cause_note_structure_inline,0,	1, :string,			  90,   [ [:class, :cause_record], [:field, :cause] ], "Cause of the Event"	],
       ["SOUR", :xref]	=>  [:source_citation,					0,	nil,  nil,				0,  [ [:class, :source_citation_record], [:xref, [:source_ref, :source]] ], "Reference to Source Record"	],
       ["SOUR", nil]		=>  [:source_citation_inline,	    0,	nil, :string,	248,  [ [:class, :source_citation_record], [:class, :source_record], [:field, :title] ], "Inline note describing source" 	],
       #Subm records in events is not standard gedcom 5.5
       ["SUBM", :xref]	=>  [nil,		                  0,  nil,	nil,				0,  [ [:xref, [:submitter_ref, :submitter]] ],"Submitter of Record's Information"	],
       ["OBJE", :xref]	=>  [nil,		                  0,	nil,	nil,				0,  [ [:class, :multimedia_citation_record], [:xref, [:multimedia_ref, :multimedia]], [:pop] ],     "Link to a Multimedia Record"	],
       ["OBJE", nil]		=>  [:multimedia_link,				0,	nil,	nil,				0,  [ [:class, :multimedia_citation_record], [:class, :multimedia_record] ],                 "Inline Multimedia Record"	],
       ["NOTE", :xref]	=>  [:note_structure,				  0,	nil,  nil,				    0,    [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
       ["NOTE", nil]		=>  [:note_structure_inline,		0,	nil, :string,		  248,    [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
       ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:lds_individual_ordinance_bapl => # /*and CONL*/
    {
    	 ["STAT", nil]		=>  [nil,		                    0,	1, :lds_bapt_enum,	10,   [ [:field, :lds_date_status] ], "LDS Baptism Date Status"	],
    	 ["DATE", nil]		=>  [:date_structure,		            0,	1, :date_value,	  35,   [ [:class, :date_record], [:field, :date_value] ], "Events Date(s)"	],
    	 ["TEMP", nil]		=>  [nil,		                    0,	1, :string,			  5,    [ [:field, :lds_temp_code] ], "Abbreviated LDS Temple Code"		],
       ["PLAC", nil]		=>  [:place_structure,					0,	1, :placehierachy,	120,  [ [:class, :place_record], [:field, :place_value] ], "Jurisdictional Place Hierarchy where the Event Occurred"	],
       ["SOUR", :xref]	=>  [:source_citation,					0,	nil,  nil,				0,  [ [:class, :source_citation_record], [:xref, [:source_ref, :source]] ], "Reference to Source Record"	],
       ["SOUR", nil]		=>  [:source_citation_inline,	    0,	nil, :string,	248,  [ [:class, :source_citation_record], [:class, :source_record], [:field, :title] ], "Inline note describing source" 	],
       ["NOTE", :xref]	=>  [:note_structure,				  0,	nil,  nil,				    0,  [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
       ["NOTE", nil]		=>  [:note_structure_inline,		  0,	nil, :string,		  248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
       ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:lds_individual_ordinance_endl =>
    {
      ["STAT", nil]		=>  [nil,		                    0,	1, :lds_endl_enum,	10,   [ [:field, :lds_date_status] ], "LDS Baptism Date Status"	],
      ["DATE", nil]		=>  [:date_structure,		            0,	1, :date_value,	  35,   [ [:class, :date_record], [:field, :date_value] ], "Events Date(s)"	],
      ["TEMP", nil]		=>  [nil,		                    0,	1, :string,			  5,    [ [:field, :lds_temp_code] ], "Abbreviated LDS Temple Code"		],
      ["PLAC", nil]		=>  [:place_structure,					0,	1, :placehierachy,	120,  [ [:class, :place_record], [:field, :place_value] ], "Jurisdictional Place Hierarchy where the Event Occurred"	],
      ["SOUR", :xref]	=>  [:source_citation,					0,	nil,  nil,				0,  [ [:class, :source_citation_record], [:xref, [:source_ref, :source]] ], "Reference to Source Record"	],
      ["SOUR", nil]		=>  [:source_citation_inline,	    0,	nil, :string,	248,  [ [:class, :source_citation_record], [:class, :source_record], [:field, :title] ], "Inline note describing source" 	],
      ["NOTE", :xref]	=>  [:note_structure,				  0,	nil,  nil,				    0,  [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
      ["NOTE", nil]		=>  [:note_structure_inline,		  0,	nil, :string,		  248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:lds_individual_ordinance_slgc =>
    {
      ["STAT", nil]		=>  [nil,		                    0,	1, :lds_child_seal_enum,	10, [ [:field, :lds_date_status] ], "LDS Baptism Date Status"	],
      ["DATE", nil]		=>  [:date_structure,		            0,	1, :date_value,	  35,       [ [:class, :date_record], [:field, :date_value] ], "Events Date(s)"	],
      ["TEMP", nil]		=>  [nil,		                    0,	1, :string,			  5,        [ [:field, :lds_temp_code] ], "Abbreviated LDS Temple Code"		],
      ["PLAC", nil]		=>  [:place_structure,					0,	1, :placehierachy,	120,      [ [:class, :place_record], [:field, :place_value] ], "Jurisdictional Place Hierarchy where the Event Occurred"	],
      ["SOUR", :xref]	=>  [:source_citation,					0,	nil,  nil,				0,  [ [:class, :source_citation_record], [:xref, [:source_ref, :source]] ], "Reference to Source Record"	],
      ["SOUR", nil]		=>  [:source_citation_inline,	    0,	nil, :string,	248,  [ [:class, :source_citation_record], [:class, :source_record], [:field, :title] ], "Inline note describing source" 	],
      ["NOTE", :xref]	=>  [:note_structure,				  0,	nil,  nil,				    0,        [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
      ["NOTE", nil]		=>  [:note_structure_inline,		0,	nil, :string,		  248,        [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
      ["FAMC", :xref]	=>  [nil,		                  1,	1,    nil,				  0,           [ [:xref,  [:lds_slgc_family_ref, :family]] ], "Link to Parents Family Record"	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:lds_individual_ordinance_slgs => 
    {
       ["STAT", nil]		=>  [nil,		                    0,	1, :lds_spouse_seal_enum,	10,   [ [:field, :lds_date_status] ], "LDS Baptism Date Status"	],
       ["DATE", nil]		=>  [:date_structure,		            0,	1, :date_value,	  35,   [ [:class, :date_record], [:field, :date_value] ], "Events Date(s)"	],
       ["TEMP", nil]		=>  [nil,		                    0,	1, :string,			  5,    [ [:field, :lds_temp_code] ], "Abbreviated LDS Temple Code"		],
       ["PLAC", nil]		=>  [:place_structure,					0,	1, :placehierachy,	120,  [ [:class, :place_record], [:field, :place_value] ], "Jurisdictional Place Hierarchy where the Event Occurred"	],
       ["SOUR", :xref]	=>  [:source_citation,					0,	nil,  nil,				0,  [ [:class, :source_citation_record], [:xref, [:source_ref, :source]] ], "Reference to Source Record"	],
       ["SOUR", nil]		=>  [:source_citation_inline,	    0,	nil, :string,	248,  [ [:class, :source_citation_record], [:class, :source_record], [:field, :title] ], "Inline note describing source" 	],
       ["NOTE", :xref]	=>  [:note_structure,				  0,	nil,  nil,				    0,  [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
       ["NOTE", nil]		=>  [:note_structure_inline,		  0,	nil, :string,		  248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
       ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:cause_note_structure_inline =>
    {
      ["RESN", nil]		=>  [nil,		                    0,	1, :restriction_value,	7, [ [:field, :restriction] ], "Record Locked or Parts removed for Privacy"	], #NOT GEDCOM 5.5
      ["CONT", nil]		=>  [nil,		                    0,	nil, :string,			  248,  [ [:append_nl, :cause] ], "Continuation on New Line"],
      ["CONC", nil]		=>  [nil,		                    0,	nil, :string,			  248,  [ [:append, :cause] ], "Continuation on Same Line"	],
      ["SOUR", :xref]	=>  [:source_citation,					0,	nil,  nil,				0,  [ [:class, :source_citation_record], [:xref, [:source_ref, :source]] ], "Reference to Source Record"	],
      ["SOUR", nil]		=>  [:source_citation_inline,	    0,	nil, :string,	248,  [ [:class, :source_citation_record], [:class, :source_record], [:field, :title] ], "Inline note describing source" 	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:personal_name_structure =>
    {
      ["RESN", nil]		=>  [nil,		                    0,	1, :restriction_value,	7, [ [:field, :restriction] ], "Record Locked or Parts removed for Privacy"	], #NOT GEDCOM 5.5
      ["NPFX", nil]		=>  [nil,	                  	0,	1, :name_piece_list,		30,   [ [:field, :prefix] ], "Non-indexed Name Prefix (comma separarted)"	],
      ["GIVN", nil]		=>  [nil,	                  	0,	1, :name_piece_list,		120,  [ [:field, :given] ], "Given Names (comma separarted)"	],
      ["NICK", nil]		=>  [nil,	                  	0,	1, :name_piece_list,		120,  [ [:field, :nickname] ], "Nickname(s) (comma separarted)"	],
      ["SPFX", nil]		=>  [nil,		                  0,	1, :name_piece_list,		30,   [ [:field, :surname_prefix] ], "Surname Prefix (comma separarted)"	],
      ["SURN", nil]		=>  [nil,		                  0,	1, :name_piece_list,		120,  [ [:field, :surname] ], "Surname(s) (comma separarted)"	],
      ["NSFX", nil]		=>  [nil,		                  0,	1, :name_piece_list,		30,   [ [:field, :suffix] ], "Non-indexed Name Suffix (comma separarted)"	],
      #GEDCOM 5.5.1 has TYPE, FONE, ROMN tags subordinate to the NAME Tag.
      ["TYPE", nil]		=>  [nil,		                  0,	1, :name_event_type,		30,   [ [:field, :name_type] ], "aka (i.e. alias)| birth | immigrant | maiden | married | <user defined>"	],
      ["FONE", nil]		=>  [:name_phonetic_variation,	0,	1, :name_string,		120,   [ [:class, :name_phonetic_record], [:field, :phonetic_name] ], " phonetically written using the method indicated by the subordinate PHONETIC_TYPE"	],
      ["ROMN", nil]		=>  [:name_romanized_variation,	0,	1, :name_string,		120,   [ [:class, :name_romanized_record], [:field, :romanized_name] ], " Romanized written using the method indicated by the subordinate ROMANIZED_TYPE"	],
      #
      ["SOUR", :xref]	=>  [:source_citation,					0,	nil,  nil,				0,  [ [:class, :source_citation_record], [:xref, [:source_ref, :source]] ], "Reference to Source Record"	],
      ["SOUR", nil]		=>  [:source_citation_inline,	    0,	nil, :string,	248,  [ [:class, :source_citation_record], [:class, :source_record], [:field, :title] ], "Inline note describing source" 	],
      ["NOTE", :xref]	=>  [:note_structure,				0,	nil,  nil,				        0,    [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
      ["NOTE", nil]		=>  [:note_structure_inline,	0,	nil, :string,		        248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
    #GEDCOM 5.5.1
		:name_phonetic_variation =>
    {  
      ["TYPE",  nil]		=>  [nil,		                 0,	1, :phonetic_type,    30,   [  [:field, :phonetic_type] ],  "<user defined> | hangul | kana"	],
      #Personal name structure tags
      ["NPFX", nil]		=>  [nil,	                  	0,	1, :name_piece_list,		30,   [ [:field, :prefix] ], "Non-indexed Name Prefix (comma separarted)"	],
      ["GIVN", nil]		=>  [nil,	                  	0,	1, :name_piece_list,		120,  [ [:field, :given] ], "Given Names (comma separarted)"	],
      ["NICK", nil]		=>  [nil,	                  	0,	1, :name_piece_list,		120,  [ [:field, :nickname] ], "Nickname(s) (comma separarted)"	],
      ["SPFX", nil]		=>  [nil,		                  0,	1, :name_piece_list,		30,   [ [:field, :surname_prefix] ], "Surname Prefix (comma separarted)"	],
      ["SURN", nil]		=>  [nil,		                  0,	1, :name_piece_list,		120,  [ [:field, :surname] ], "Surname(s) (comma separarted)"	],
      ["NSFX", nil]		=>  [nil,		                  0,	1, :name_piece_list,		30,   [ [:field, :suffix] ], "Non-indexed Name Suffix (comma separarted)"	],
      #source
      ["SOUR", :xref]	=>  [:source_citation,					0,	nil,  nil,				0,  [ [:class, :source_citation_record], [:xref, [:source_ref, :source]] ], "Reference to Source Record"	],
      ["SOUR", nil]		=>  [:source_citation_inline,	    0,	nil, :string,	248,  [ [:class, :source_citation_record], [:class, :source_record], [:field, :title] ], "Inline note describing source" 	],
      #Notes
      ["NOTE", :xref]	=>  [:note_structure,				0,	nil,  nil,				        0,    [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
      ["NOTE", nil]		=>  [:note_structure_inline,	0,	nil, :string,		        248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
      ["RESN", nil]		=>  [nil,		                    0,	1, :restriction_value,	7, [ [:field, :restriction] ], "Record Locked or Parts removed for Privacy"	], #NOT GEDCOM 5.5.
    },
		:name_romanized_variation =>
    {  
      ["TYPE",  nil]		=>  [nil,		                 0,	1, :romanized_type,    30,   [  [:field, :romanized_type] ],  "<user defined> | pinyin | romaji | wadegiles"	],
      #Personal name structure tags
      ["NPFX", nil]		=>  [nil,	                  	0,	1, :name_piece_list,		30,   [ [:field, :prefix] ], "Non-indexed Name Prefix (comma separarted)"	],
      ["GIVN", nil]		=>  [nil,	                  	0,	1, :name_piece_list,		120,  [ [:field, :given] ], "Given Names (comma separarted)"	],
      ["NICK", nil]		=>  [nil,	                  	0,	1, :name_piece_list,		120,  [ [:field, :nickname] ], "Nickname(s) (comma separarted)"	],
      ["SPFX", nil]		=>  [nil,		                  0,	1, :name_piece_list,		30,   [ [:field, :surname_prefix] ], "Surname Prefix (comma separarted)"	],
      ["SURN", nil]		=>  [nil,		                  0,	1, :name_piece_list,		120,  [ [:field, :surname] ], "Surname(s) (comma separarted)"	],
      ["NSFX", nil]		=>  [nil,		                  0,	1, :name_piece_list,		30,   [ [:field, :suffix] ], "Non-indexed Name Suffix (comma separarted)"	],
      #source
      ["SOUR", :xref]	=>  [:source_citation,					0,	nil,  nil,				0,  [ [:class, :source_citation_record], [:xref, [:source_ref, :source]] ], "Reference to Source Record"	],
      ["SOUR", nil]		=>  [:source_citation_inline,	    0,	nil, :string,	248,  [ [:class, :source_citation_record], [:class, :source_record], [:field, :title] ], "Inline note describing source" 	],
      #Notes
      ["NOTE", :xref]	=>  [:note_structure,				0,	nil,  nil,				        0,    [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
      ["NOTE", nil]		=>  [:note_structure_inline,	0,	nil, :string,		        248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
      ["RESN", nil]		=>  [nil,		                    0,	1, :restriction_value,	7, [ [:field, :restriction] ], "Record Locked or Parts removed for Privacy"	], #NOT GEDCOM 5.5.
    },
		:place_structure =>
    {
    	 ["FORM", nil]		=>  [nil,		                  0,	1, :placehierachy, 120,   [ [:field, :place_hierachy] ], "Place Hierachy (comma separarted jurisdictions)"	],
       #GEDCOM 5.5.1 adds FONE, ROMN, MAP
       ["FONE", nil]		=>  [:placename_phonetic_variation,	0,	1, :placehierachy,		120,   [ [:class, :placename_phonetic_record], [:field, :phonetic_name] ], " phonetically written using the method indicated by the subordinate PHONETIC_TYPE"	],
       ["ROMN", nil]		=>  [:placename_romanized_variation,	0,	1, :placehierachy,		120,   [ [:class, :placename_romanized_record], [:field, :romanized_name] ], " Romanized written using the method indicated by the subordinate ROMANIZED_TYPE"	],
       ["MAP", nil]		=>  [:placename_map_structure,	0,	1, nil,		0,   [ [:class, :placename_map_record] ], "Latitude and Longitude"	],
       ["SOUR", :xref]	=>  [:source_citation,					0,	nil,  nil,				0,  [ [:class, :source_citation_record], [:xref, [:source_ref, :source]] ], "Reference to Source Record"	],
       ["SOUR", nil]		=>  [:source_citation_inline,	    0,	nil, :string,	248,  [ [:class, :source_citation_record], [:class, :source_record], [:field, :title] ], "Inline note describing source" 	],
       ["NOTE", :xref]	=>  [:note_structure,				0,	nil,  nil,				    0,    [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
       ["NOTE", nil]		=>  [:note_structure_inline,		0,	nil, :string,		    248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
       ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
    #GEDCOM 5.5.1
		:placename_map_structure =>
    {  
      ["LATI",  nil]		=>  [nil,		                 0,	1, :latitude,    8,   [  [:field, :latitude] ],  "Decimal format e.g. N18.150944"	],
      ["LONG",  nil]		=>  [nil,		                 0,	1, :longitude,    8,   [  [:field, :longitude] ],  "Decimal format e.g. E168.150944"	],
      #Notes
      ["NOTE", :xref]	=>  [:note_structure,				0,	nil,  nil,				        0,    [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
      ["NOTE", nil]		=>  [:note_structure_inline,	0,	nil, :string,		        248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:placename_phonetic_variation =>
    {  
      ["TYPE",  nil]		=>  [nil,		                 0,	1, :phonetic_type,    30,   [  [:field, :phonetic_type] ],  "<user defined> | hangul | kana"	],
      #Notes
      ["NOTE", :xref]	=>  [:note_structure,				0,	nil,  nil,				        0,    [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
      ["NOTE", nil]		=>  [:note_structure_inline,	0,	nil, :string,		        248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:placename_romanized_variation =>
    {  
      ["TYPE",  nil]		=>  [nil,		                 0,	1, :romanized_type,    30,   [  [:field, :romanized_type] ],  "<user defined> | pinyin | romaji | wadegiles"	],
      #Notes
      ["NOTE", :xref]	=>  [:note_structure,				0,	nil,  nil,				        0,    [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
      ["NOTE", nil]		=>  [:note_structure_inline,	0,	nil, :string,		        248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:source_citation =>
    {
    	 ["PAGE", nil]		=>  [nil,		                0,	1, :string,			  248,    [ [:field, :page] ], "Location within the Source"	],
    	 ["EVEN", nil]		=>  [:source_citation_even,	0,	1, :event_attribute_enum,	15, [ [:class, :citation_event_type_record],[:field, :event_type] ], "Event Code the source record was made for"	],
    	 ["DATA", nil]		=>  [:source_citation_data,	0,	1,	nil,					    0,    [ [:class, :citation_data_record] ], "Data Record"	],
    	 ["QUAY", nil]		=>  [nil,		                0,	1, :quality_enum,		1,    [ [:field, :quality] ], "Unreliable (0), Questional (1), Secondary (2), Primary (1)"	],
       ["OBJE", :xref]	=>  [nil,		                  0,	nil,	nil,				0,  [ [:class, :multimedia_citation_record], [:xref, [:multimedia_ref, :multimedia]], [:pop] ],     "Link to a Multimedia Record"	],
       ["OBJE", nil]		=>  [:multimedia_link,				0,	nil,	nil,				0,  [ [:class, :multimedia_citation_record], [:class, :multimedia_record] ],                 "Inline Multimedia Record"	],
       ["NOTE", :xref]	=>  [:note_structure,				0,	nil,  nil,				    0,    [ [:class, :note_citation_record], [:xref,  [:note_ref, :note]] ], "Link to a Note Record"	],
       ["NOTE", nil]		=>  [:note_structure_inline,		0,	nil, :string,		  248,    [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
       ["NOTE", :user]	=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:source_citation_even =>
    {
      ["ROLE", nil]		=>  [nil,		0,	1, :role,			15, [ [:field, :role] ], "Role in Event (i.e. CHIL, HUSB, WIFE, MOTH ..."	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:source_citation_data =>
    {
    	 ["DATE", nil]		=>  [:date_structure,		    0,	1, :date_value,	90,   [ [:class, :date_record], [:field, :date_value] ], "Date event was entered into original source"],
    	 ["TEXT", nil]		=>  [:text_cont_conc,	  0,	nil, :string,		  248,  [ [:class, :text_record], [:field, :text]], "Verbatim Copy of the Source Tect"],
    	 ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:source_citation_inline =>
    { #A source record, less lots of the possible variables 
    	 ["CONT", nil]		=>  [nil,		                  0,	nil, :string,			248,  [ [:append_nl, :title] ], "Continuation on New Line"],
    	 ["CONC", nil]		=>  [nil,		                  0,	nil, :string,			248,  [ [:append, :title] ], "Continuation on Same Line"	],
    	 ["TEXT", nil]		=>  [:text_cont_conc,					0,	nil, :string,	  	248,  [  [:class, :text_record], [:field, :text] ], "Verbatim Copy of the Source Tect" 	],
    	 ["NOTE", :xref]	=>  [:note_structure,					0,	nil,  nil,				  0,    [ [:class, :note_citation_record], [:xref, [:note_ref, :note]] ], "Link to a Note Record"	],
    	 ["NOTE", nil]		=>  [:note_structure_inline,	  0,	nil, :string,			248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
       ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:source_repository_citation =>
    {
      ["NOTE", :xref]	=>  [:note_structure,					          0,	nil,  nil,			0,  [ [:class, :note_citation_record], [:xref, [:note_ref, :note]] ], "Link to a Note Record"	],
      ["NOTE", nil]		=>  [:note_structure_inline,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Inline Note Record"	],
      ["CALN", nil]		=>  [:source_repository_citation_caln,	0,	nil, :string,	120,  [ [:class, :repository_caln], [:field, :call_number] ], "Repository Source Call :number"	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },
		:source_repository_citation_caln =>
    {
      ["MEDI", nil]		=>  [nil,		                    0,	1, :mediatype_enum,	15, [ [:field, :media_type] ], "Code for Source Media Type"	],
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:class, :note_citation_record], [:class, :note_record], [:field, :note] ], "Treat Unknown Tags as Single line notes"	],
    },

    #Catchall for unknown, or user defined tags.
    :user_subtag =>
    {
      ["NOTE", :user]		=>  [:user_subtag,	          0,	nil, :string,	248,  [ [:append_nl, :note], [:push] ], "Treat Unknown Tags as Single line notes"	],
    }
  }
 
  #Create a new GedcomParser instance
  #Optional transmission argument provides an external Transmission object to hold the parsed file.
  def initialize(transmission = Transmission.new)
    @transmission =  transmission #We store the loaded records in here.
    @parse_state = ParseState.new :transmission ,  @transmission  #We are starting in a parse state of :transmission on the stack.
  end
  
  #Parse a GEDCOM line, adding it to the Transmission class hierarchy.
  #Takes a lineno for reporting errors 
  #and the line (as a String) to be tokenised and parsed.
  def parse(lineno, line)
    tokens = GedLine.new *line.chomp.strip.split(/\s/)
    parse_line(lineno, tokens)
  end
  
  #Dump the statistics of what we have parsed and stored in the Transission object.
  def summary
    @transmission.summary
  end
        
  private
  
  #Uses the TAGS hash to determine how to process the line.
  #Take a a line number for error reporting 
  #and the tokenised GEDCOM line. 
  def process_line(lineno, tokens)
    if (tag_line = TAGS[@parse_state.state]) == nil
      raise "In unknown state (#{@parse_state.state})"
    elsif (tag_spec = tag_line[ tokens.index ]) == nil
      if tokens.tag[0,1] == "_" || @parse_state.state == :user_subtag
        print "Unknown tag #{tokens}. "
        tokens.user_tag 
        pp "Converted to #{tokens}"
        process_line(lineno, tokens)
      else
        raise "Tag ([#{tokens.tag},#{tokens.xref}]) not valid in this state (#{@parse_state.state})"
      end
    elsif tag_spec[CHILD_RECORD] != nil #don't push nil states, as these represent terminals
      #Run the handler for this line.
      @transmission.action_handler lineno, tokens, *tag_spec
      #switch to new state
      @parse_state << tag_spec[CHILD_RECORD]
    else 
      #Run the handler for this line.
      @transmission.action_handler lineno, tokens, *tag_spec
    end
        
  end
  
  #Manages the parsing state stack and calling process_line() to create objects to hold the data.
  #Takes a lineno for error reporting 
  # and a tokenised GEDCOM line (including tokenizing the data value as a word array).
  def parse_line(lineno, tokens)
    #need to look in the ::TAGS hash for tags that match the level this line is on.
    #Annoyingly, Level 0 has the data and the TAG, reversed for xrefs. 
    current_level = @parse_state.level
    new_level = tokens.level
    
    if current_level > new_level
      #Reduce the parse state stack until we are at the new level
      while current_level > new_level
        current_level -= 1
        @parse_state.pop
      end
      process_line(lineno, tokens)  #We are now at the same level, so we process the line
    elsif current_level == new_level
      process_line(lineno, tokens)  #We are already at the same level, so we just process the line
    elsif current_level < new_level
      raise "Level increased by more than 1 (current_level = #{current_level}, new_level = #{new_level})"
    end
  end
  

end




