require 'gedcom_base.rb'

#Internal representation of a reference to the GEDCOM level 0 OBJE record type
#GEDCOM has both inline OBJE records and references to level 0 OBJE records.
#both are stored stored in a Multimedia_record class and both get referenced through this class.
#
#=MULTIMEDIA_LINK:=
#  n OBJE @<XREF:OBJE>@           {1:1}
#
#  This structure provides two options in handling the GEDCOM multimedia interface. The first
#  alternative (embedded) includes all of the data, including the multimedia object, within the
#  transmission file. The embedded method includes pointers to GEDCOM records that contain
#  encoded image or sound objects. Each record represents a multimedia object or object fragment. An
#  object fragment is created by breaking the multimedia files into several multimedia object records of
#  32K or less. These fragments are tied together by chaining from one multimedia object fragment to
#  the next in sequence. This procedure will help manage the size of a multimedia GEDCOM record so
#  that existing systems which are not expecting large multimedia records may discard the records
#  without crashing due to the size of the record. Systems which handle embedded multimedia can
#  reconstitute the multimedia fragments by decoding the object fragments and concatenating them to
#  the assigned multimedia file.
#
#  This second method allows the GEDCOM context to be connected to an external multimedia file.
#  GEDCOM defines this in the MULTIMEDIA_LINK definition, but I have put it into the Multimedia_record.
#  as the attributes are the same, except BLOB becomes FILE. A Multimedia_citation_record is also created
#  to make all references to Multimedia records consistent.
#
#  This process is only managed by GEDCOM in the sense that the appropriate file name is included in
#  the GEDCOM file in context, but the maintenance and transfer of the multimedia files are external to
#  GEDCOM. The parser can just treat this as a comment and doesn't check for the file being present.
#
#The attributes are all arrays for the level +1 tags/records. 
#* Those ending in _ref are GEDCOM XREF index keys
#* Those ending in _record are array of classes of that type.
#* The remainder are arrays of attributes that could be present in this record.
class Multimedia_citation_record < GEDCOMBase
  attr_accessor :multimedia_ref, :multimedia_record
  attr_accessor :note_citation_record

  ClassTracker <<  :Multimedia_citation_record
  
  def to_gedcom(level=0)
    if @multimedia_ref != nil
      @this_level = [ [:xref, "OBJE", :multimedia_ref] ]
      @sub_level =  [#level 1
                      [:walk, nil,    :note_citation_record ],
                    ]
    else
      @this_level = [ [:walk, nil, :multimedia_record] ]
      @sub_level =  [#level 1
                    ]
    end
    super(level)
  end
end

