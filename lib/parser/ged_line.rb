#GedLine takes a GEDCOM line tokenised into a word array returning an object 
#with the:
# * level number in @level
# * the GEDCOM tag in @tag
# * the data portion in @data
# * the XREF value, if this line has one, in @XREF
# * the @user set to true if this is a user defined TAG (e.g. starts with '_')

class GedLine
  attr_accessor :xref, :tag, :data, :level, :user
  
  #GedLine.new(*data) takes a GEDCOM line as word array and does all the work to categorize the tokens.
  def initialize(*data)
    case
      when data.length < 2
        raise "line too short (#{data.length})"
      when data[0] == nil
        raise "level is nil"
      when data[1] == nil
        raise "No Tag or Xref after the level"
      #need to add a test to ensure level is a number!
    end 
    
    @level = data[0].to_i
    
    if @level == 0 #At the top level, where the xrefs and tags are reversed.
      if data[1][0..0] == '@' #Then we have an xref line
        @xref = data[1].gsub(/\A@|@\Z/, '')
        @tag = data[2]
        @data = data.length == 3 ? nil : data[3..-1] #note lines can have data here. Others will not.
        if @xref.length > 22
          raise "Xref too long (Max = 22, length = #{@xref.length}) "
        end
      elsif data.length != 2 #This is a Head or Trailer line, so should be two tokens long.
        raise "Level 0 line has too many tokens"
      else
        @xref = nil
        @data = nil
        @tag = data[1]
      end
    else
      @tag = data[1]
      if data.length == 2
        @xref = nil
        @data = nil
      elsif data[2][0..0] == '@' #Then we have an xref line
        if data.length != 3           #These will always have 3 tokens.
          raise "Level #{@level} #{@tag} Xref Line has too many tokens"
        end
        @xref = data[2].gsub(/\A@|@\Z/, '')
        @data = nil
        if @xref.length > 22
          raise "Xref too long (Max = 22, length = #{@xref.length}) "
        end
      else
        @xref = nil
        @data = data[2..-1]
      end
    end 
    @user = nil
  end
  
  #Test for this being a user Tag.
  def user_tag?
    @user == true
  end

  #Returns the hash key for this GEDCOM LINE to lookup the action in the GedcomParser::TAG has.
  def index
    user_tag? ? [ "NOTE", :user ] : ( @xref ? [@tag, :xref] : [@tag, nil] )
  end
  
  
  #creates as NOTE from a user defined tag.
  #sets the @user field to true.
  def user_tag
    if @xref != nil
      if @data == nil
        @data = [ '@' + @xref + '@' ]
      else
        @data[0,0] = '@' + @xref + '@'
      end
      @xref = nil if @level != 0 #Retain for the NOTES xref if this is a level 0 user tag.
    end
    if @data == nil
      @data = [ @tag ]
    else
      @data[0,0] = @tag
    end
    @data[0,0] = @level.to_s
    @user = true
    @tag = "NOTE"
  end
      
  #Returns a String with the @level, @xref, @tag and @data values.
  def to_s
    "Level #{@level}, Xref = @#{@xref}@, Tag = #{@tag}, Data = '#{@data ? @data.inject('') do |x,y| x + ' ' + y end : nil}'"
  end
end
