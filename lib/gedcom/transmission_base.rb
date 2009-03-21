require 'gedcom_base.rb'

class TransmissionBase < GedComBase
  attr_accessor :header_record, :submitter_record, :family_record, :individual_record, :source_record
  attr_accessor :multimedia_record, :note_record, :repository_record, :submission_record, :trailer_record
  
  ClassTracker <<  :TransmissionBase
 
  def initialize(*a)
    super(*a)
     #Create the initial top level arrays of records that can exist in a transmission.
    @header_record = []
    @submission_record = []
    @submitter_record = []
    @individual_record = []
    @family_record = []
    @source_record = []
    @repository_record = []
    @multimedia_record = []
    @note_record = []
    @trailer_record = []    
    
    @this_level = [ [:walk, nil, :header_record],     #Recurse over the HEAD header records (should only be one)
                    [:walk, nil, :submission_record], #Recurse over the SUBN submission records
                    [:walk, nil, :submitter_record],  #Recurse over the SUBM submitter record(s)
                    [:walk, nil, :source_record],     #Recurse over the SOUR Source records
                    [:walk, nil, :repository_record], #Recurse over the REPO repository records
                    [:walk, nil, :family_record],     #Recurse over the FAM Family records
                    [:walk, nil, :individual_record], #Recurse over the INDI Individual records
                    [:walk, nil, :multimedia_record], #Recurse over the OBJE multimedia records
                    [:walk, nil, :note_record],       #Recurse over the NOTE records
                    [:walk, nil, :trailer_record],    #Recurse over the Trailer Record(s). (should only be the one).
                  ]
    @sub_level =  [#level + 1
                  ]
  end
  
  def defined(class_name)
    ClassTracker::exists class_name
  end
  
  def define(class_name)
    ClassTracker <<  class_name
  end
       
end

