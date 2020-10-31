#shared methods for drawing decendant, pedigree and relationship charts.
#Chart is expected to be sub-classed, and offers no non-private methods.
require 'bit.rb'

class Chart

 PEDIGREE_WIDTH = 3 

  #Create a new Chart object.
  # if html is true, then the chart has HTML tags embeded in it.
  # else the chart is plain text (default).
  def initialize( html=false, pedigree_width=PEDIGREE_WIDTH)
    @html = html
    pedigree_width
    @colour_chart = [
      "#000000", #black
      "#FF0522", #Red
      "#F58309", #Orange
      "#FBFF02", #Yellow
      "#09C710", #Green
      "#02EFF3", #Light Blue
      "#FF0CEB", #Inigo
      "#052EFF", #RBlue
    ]
    @n_chart_colours = @colour_chart.length
    @lastspace = ' ' * (pedigree_width - 1)
    @spacebar = ' ' * pedigree_width + '|'
    @spacenobar = ' ' * (pedigree_width + 1)
    @url_base = '/gedserv?record=' #FIXME: probably not what anyone else wants.
  end

  #private 
  #returns a string of spaces and '|', with the '|' being where the bitmap values are set to 1
  #Each group of spaces, or spaces and a '|', are of width pedigree_width.
  def bars(bitmap,  depth)
    s =  bitmap.set?(0) ? "|" : " " 

    (1...depth).each do |i|
      if bitmap.set?(i)
        s += bar(depth) 
      else
        s += @spacenobar
      end
    end
    return s
  end

  #returns a string of pedigree_width ending in a |
  def bar(depth)
    if @html
      "<FONT COLOR=\"#{@colour_chart[depth % @n_chart_colours]}\">#{@spacebar}</FONT>"
    else
      @spacebar
    end
  end

  #returns a String of spaces of width @pedigree_width - 1
  def lastspace
    @lastspace
  end
  
  alias lastbar bar
  
  #Tests for html output being on.
  def html?
    @html == true
  end
  
  #Prints out a line on the chart with the individuals name and all the connecting bars between other parts
  #of the chart that cross this line (represented by bits being set in bitmap).
  #*Max_depth is the maximum number of generation we are printing, so we
  #return if we have exceeded this. A max_depth of 0 says that we will print all generations.
  #*prefix is printed before the individual's name
  #*suffix is printed after the individual's name.
  #*fams is the individual's own family's Family_record, the first of which will make the name an the HTML link to that family if fams != nil.
  #*famc is the individual's parent's Family_record. The first of these is used for the HTML link if fams == nil.
  #@html must be true for fams or famc to be used, and the link is currently specific to my family tree server.
  def output_pedigree_name( indiv, depth, famc, fams, bitmap, prefix, child_marker, blank, suffix, max_depth )
    #Check to see if we reached the depth limit we set for this chart.
    if(max_depth > 0 && max_depth < depth)
      s = bars( bitmap, depth)
      if(depth)
        if(blank)
          s += lastspace
        else
          s += lastbar(depth)
        end
      end  
      if html?
        s += "<b>Maximum Depth Reached</b>\n"
      else
        s += "Maximum Depth Reached\n"
      end
      return s
    end

    #ensure we actually have someone, and didn't just fall of the end of the world.
    #indiv == nil is our termination condition for recursion.
    if(indiv != nil)
      
      s = bars(bitmap, depth) #Add in leading bars, which form the visual links between individuals.
      if(depth > 0) #if we not on the first level, we need to add either a ' ' or a '|'.
        if(blank) #blank is passed in argument list.
          s += lastspace
        else
          s += lastbar(depth)
        end
      end

      if (name = indiv.primary_name) == ''
        name = '?'
      end
 
      #pull out the first TITL records from the Individual_record.individual_attribute_record array.
      #this will be an array of Individual_attribute records of type TITL records (probably only one element).
      if (title = indiv.title) != nil
        #For our display of this person in the chart, we want just on TITL. The GEDCOM standard says the most relevant one should be the first one.
        #This TITL record (title.first) has a value with the Title in it, stored in an array, so we need to take the first one.
        #A bit loopy, but consistent with records like PHON, where multiple phone number records are stored in the same array
        title_p = title.first.value.first 
      else
        title_p = ''
      end

      if(html?)
        #indiv.individual_ref[1] is the XREF, indiv.individual_ref[0] being the index name :individual.
        s += "<A NAME=\"#{indiv.individual_ref[1]}\"></A>" #Put a HTML Anchor, so we can jump to this point with a URL.
        #these fams & famc URLs are currently peculiar to my gedcom server, so need to be culled or the base needs to be set dynamically.
        if(fams != nil)    #passed in fams, so set up name to be a link to the family record.
          s += "#{prefix}<b>#{title_p}</b>#{(title_p == '' ?  "" : " ")}<A HREF=\"#{url_base}#{fams.family_ref[1]}.html\" >#{name}</A>"
        elsif(famc != nil) #passed in famc, so set up name to be a link to the parent family record
          s += "#{prefix}<b>#{title_p}</b>#{(title_p == '' ?  "" : " ")}<A HREF=\"#{url_base}#{famc.family_ref[1]}.html\" >#{name}</A>"
        else #weren't passed in either fams or famc, so don't set up a link.
          s += "#{prefix}<b>#{title_p}</b>#{(title_p == '' ?  "" : " ")}#{name}"
        end
      else
        s += "#{prefix}#{title_p}#{(title_p == '' ?  "" : " ")}#{name}"
      end
      
      
      if((birth = indiv.birth) != nil && (date = birth[0].date) != nil)
        #if we have a birth date, then we will add it to the output.
        s += html? ? " <b>b.</b>#{date}" : " b.#{date}" 
      elsif((chr = indiv.christening) && (date = chr[0].date) != nil)
        #if we don't have a birth date, we might have a christening date.
        s += html? ? " <b>c.</b>#{date}" : " c.#{date}"
      end

      if((deat = indiv.death) != nil && (date = deat[0].date) != nil)
        s += html? ? " <b>d.</b>#{date}" : " d.#{date}"
      end
      
      s += " #{suffix}\n" if suffix
      return s
    end
    
    return nil #allows test to break any recursion.
  end
  
end
