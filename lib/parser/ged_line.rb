class GedLine
  attr_accessor :xref, :tag, :data, :level, :user
  
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
  
  def index
    @user ? [ "NOTE", :user ] : ( @xref ? [@tag, :xref] : [@tag, nil] )
  end
  
  def user_tag
    if @xref
      if @data == nil
        @data = [ '@' + @xref + '@' ]
      else
        @data[0,0] = '@' + @xref + '@'
      end
      @xref = nil
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
      
  def to_s
    "Level #{@level}, Xref = @#{@xref}@, Tag = #{@tag}, Data = '#{@data ? @data.inject('') do |x,y| x + ' ' + y end : nil}'"
  end
end
