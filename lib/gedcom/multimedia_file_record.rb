require 'gedcom_base.rb'

#
#=GEDCOM 5.5.1
#=MULTIMEDIA_LINK:=
#  n OBJE  <XREF>                         {1:1} is a reference to level 0 multimedia record.
#  | 
#  n OBJE                                 {1:1} is inline reference to an external file, rather than multimedia record.
#    +1 FILE <MULTIMEDIA_FILE_REFN>       {1:M}	Now 1:M in 5.5.1, was 1:1 in 5.5
#    	+2 FORM	 <MULTIMEDIA_FORMAT>        {1:1} Was as level 1 in GEDCOM 5.5
#    		+3 MEDI <SOURCE_MEDIA_TYPE>       {0:1} New in 5.5.1
#    +1 TITL <DESCRIPTIVE_TITLE>          {0:1} 
#
# No blobs in 5.5.1
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.

class Multimedia_file_record < GEDCOMBase
  attr_accessor :multimedia_format_record, :filename
  #attr_accessor :title #Level above in the link version
  attr_accessor :note_citation_record #for user defined tags
  
  ClassTracker <<  :Multimedia_file_record
  
  def to_gedcom(level=0)
    
    @this_level =  [ [:print, "FILE", :filename]]
    @sub_level =  [#level 1
                    #[:print, "TITL",    :title ],                 #For OBJE record version
                    [:walk, nil,    :multimedia_format_record ],  # "FORM" 
                    [:walk, nil,    :note_citation_record ],      #for user defined tags
                  ]
    
    super(level)
  end
  
  
end

#=GEDCOM 5.5.1
#Almost the same structure inline in OBJE record. 
#   Note TITL subordinate to FILE, rather than at same level.
#        TYPE used, where MEDI used in Link version.
#=MULTIMEDIA_RECORD:=
#  0 @XREF:OBJE@ OBJE                     {0:M}
#    +1 FILE <MULTIMEDIA_FILE_REFN>       {1:M}	New in 5.5.1
#    	+2 FORM	 <MULTIMEDIA_FORMAT>        {1:1} Was as level 1 in GEDCOM 5.5
#    		+3 TYPE <SOURCE_MEDIA_TYPE>       {0:1} New in 5.5.1
#    	+2 TITL <DESCRIPTIVE_TITLE>         {0:1} Was as level 1 in GEDCOM 5.5
#    ....
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.

class Multimedia_obje_file_record < GEDCOMBase
  attr_accessor :multimedia_obje_format_record, :filename
  attr_accessor :title #Level above in the link version
  attr_accessor :note_citation_record #for user defined tags
  
  ClassTracker <<  :Multimedia_obje_file_record
  
  def to_gedcom(level=0)
    
    @this_level =  [ [:print, "FILE", :filename]]
    @sub_level =  [#level 1
                    [:print, "TITL",    :title ],                 #For OBJE record version
                    [:walk, nil,    :multimedia_obje_format_record ],  # "FORM" 
                    [:walk, nil,    :note_citation_record ],      #for user defined tags
                  ]
    
    super(level)
  end
  
  
end
