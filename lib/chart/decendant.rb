require 'chart.rb'

#Construction of decendant charts

class Decendant < Chart
  
  def initialize
    @seen = {}  #to test if we have looped
  end

  def decendants( individual , max_depth = 0 )
    glob_map = Bit.new
  
    if @html
      if(name = individual.name_record) != nil)
        title = name[0].name #pull out the first name (probably the only one in most cases.
      else
        title = "unknown"; #they don't have a name recorded.
      end
      s = "<HTML><TITLE>#{title} Desc.</TITLE><NAME=\"IndexWindow\">\n<BODY><HR>\n<PRE>\n"
    else
      s = ""
    end
    
    s += output_decendants_info(ofile, individual, 0, 0, glob_map, 0, max_depth);
    s += output_descendants_index(ofile, individual, max_depth );
    
    if @html
      s += "</BODY></HTML>\n"
    end
    
    return s
  end

  def decendants_of_name( individual, max_depth)
    glob_map = Bit.new

    if @html
      if(name = individual.name_record) != nil)
        title = name[0].name #pull out the first name (probably the only one in most cases).
      else
        title = "unknown"; #they don't have a name recorded.
      end
      s = "<HTML><TITLE>#{title} Desc.(R.)</TITLE><NAME=\"IndexWindow\">\n<BODY><HR>\n<PRE>\n"
    else
      s = ""
    end
    
    s += output_decendants_info_of_name(individual, 0, 0, glob_map, max_depth);
    
    if @html
      s += "</BODY></HTML>\n"
    end
    
    return s
  end

  private
  
  #Recursively walks down through the decendants and builds up the descendants chart.
  def output_decendants_info( individual, curdepth, direction, glob_map, rel_chart, max_depth )
    
    if(individual != nil) #if it is nil, then we fell off the end, and can stop
      if((fams = individual.spouses) != nil) #look for the spouses (FAMS records) and return the families of each in an array.
        family = fams.first; #we want the first these.
      else
        family = nil
      end

      famc = individual.parents_family.first; #get the first of the FAMC records, probably the only one.
    
      if @seen[individual]
        #A loop has occured in the recursion. Print the record with a leading * and return.
        s = output_pedigree_name(individual, curdepth, famc, family, glob_map, "*", 0, 0, "", max_depth);
        if(curdepth > 0 && direction == 0) //No more children or second spouse
          glob_map.clear(curdepth)
        end
        return s #break recursion.
      end
      
      @seen[individual] = true #mark this record as seen, so we don't loop forever if we have loops in the GEDCOM.
          
      if(  max_depth == 0 || max_depth >= curdepth  )
        #output this individuals details.
        s = output_pedigree_name(individual, curdepth, famc, family, glob_map, curdepth ? "-" : "", 0, 0, "", max_depth);
      end
      
      #Now walk through each of the families this individual is a parent of.
      fams.each_with_index do |family,fams_i|
        if ( marr = family.marriage ) != nil
          prefix = html? ? "<b>m.</b>" : "m."
          prefix += " #{date} " if ( date = marr.date ) != nil
          suffix = (( plac = marr.place ) == nil) ? '' : (html? ? "<b>,m. at</b> #{plac} " : "m. at #{plac} ")
        else
           prefix = ''
           suffix = ''
        end
        
        if( (husb = family.husband) != nil  &&  husb != individual ) #get male partner and ensure it isn't the individual we started with.
          output_pedigree_name(husb, curdepth, husb.parents_family.first, family, glob_map, prefix, 0, 0, suffix, max_depth)
        elsif( (wife = family.wife) != nil  &&  wife != individual ) #get female partner and ensure it isn't the individual we started with.
          output_pedigree_name(wife, curdepth, wife.parents_family.first, family, glob_map,  prefix, 0, 0, suffix, max_depth)
        end

        glob_map.clear(curdepth) if(curdepth > 0 && direction == 0) #No more children or second spouse

        child = family.children

        if(fams[fams_i] != nil)
          glob_map.set(curdepth)
        elsif(direction == 0)
          glob_map.clear(curdepth)
        end
        
        if( ( max_depth == 0 || max_depth >= curdepth ) && child != nil)
        {
        int ccount = 0;
        ged_type *child_tmp = child;
          do
          {
            child_rec = find_hash(child_tmp->data);
            child_tmp = find_next_this_type(family, child_tmp);
            if(child_rec 
            && (rel_chart == 0 
              || in_rel_list(individual->rel_child_1, child_rec)
              || in_rel_list(individual->rel_child_2, child_rec)))
            {
              ccount++;
            }
          }while(child_tmp);
          
          if(ccount)
          {
            setbit(glob_map, curdepth + 1);
            print_bars(ofile, glob_map, curdepth + 1);
            print_lastbar(ofile, curdepth+1);
            fputc('\n', ofile);
            next_child_rec = find_hash(child->data);
            do
            {
              child_rec = next_child_rec;
              if(child = find_next_this_type(family, child))
                next_child_rec = find_hash(child->data);
              if(child_rec 
              && (rel_chart == 0 
                || in_rel_list(individual->rel_child_1, child_rec)
                || in_rel_list(individual->rel_child_2, child_rec)))
                output_decendants_info(ofile, child_rec, curdepth + 1, 
                ((next_child_rec && --ccount) ) ? 1:0, glob_map, rel_chart, max_depth );
            }while(child);
            if(direction)
            {
              print_bars(ofile, glob_map, curdepth + 1);
              fputc('\n', ofile);
            }
          }
        }
        else if(family)
        {
          print_bars(ofile, glob_map, curdepth + 1);
          fputc('\n', ofile);
        }
        if(fams)
        {
          family = find_hash(fams->data);
          if(curdepth == 0 && family == 0)
            clearbit(glob_map, curdepth);
        }
        else
          family = 0;
      }         
      }
  end

  def output_decendants_info_of_name
  (
    FILE *ofile, 
    ged_type *individual,
    int curdepth,
    int direction,
    unsigned int *glob_map,
    int max_depth
  )
  ged_type *famc;
  ged_type *fams;
  ged_type *nfams;
  ged_type *child;
  ged_type *marr;
  ged_type *date;
  ged_type *plac;
  ged_type *child_rec;
  ged_type *family;
  ged_type *husb, *wife;
  ged_type *husb_rec, *wife_rec;
  ged_type *sex;
  int mcount = 0 ;
  char buffer[64];
  char buff2[128];

      if(individual) 
      {
        if((fams = find_type(individual, FAMS))) //look for a spouse and family
        family = find_hash(fams->data);
      else
        family = 0;
      
      famc = find_type(individual, FAMC);
    
        if(individual->processed == @pass)
      { //A loop has occured. Print the record with a * and return
        output_pedigree_name(ofile, individual, curdepth, famc, fams, glob_map, "*", 0, 0, "", max_depth);
        if(curdepth > 0 && direction == 0) //No more children or second spouse
          clearbit(glob_map, curdepth);
        return;
      }
      
      individual->processed = @pass;
          
      if(  max_depth == 0 || max_depth >= curdepth  )
        output_pedigree_name(ofile, individual, curdepth, famc, fams, glob_map, curdepth ? "-":"", 0, 0, "", max_depth);
    
      while(  family )
      {
        mcount++;

        sprintf(buffer, "<b>m.</b>");
        if( marr = find_type(family, MARR) )
        {
          if( date = find_type(marr, DATE) )
             sprintf(&buffer[strlen(buffer)], " %s ", date->data);
          if( plac = find_type(marr, PLAC) )
            sprintf(buff2, "<b>,m. at</b> %s ", plac->data);
          else
            buff2[0] = '\0';
        }
        else
           buff2[0] = '\0';
        
        if( (husb = find_type(family, HUSB))
        && (husb_rec = find_hash(husb->data))
        && husb_rec != individual )
        {
          famc = find_type(individual, FAMC);
          output_pedigree_name(ofile, husb_rec, curdepth , famc, fams, glob_map, buffer, 0, 0, buff2, max_depth);
        }
        else if(  (wife = find_type(family, WIFE))
         && (wife_rec = find_hash(wife->data))
        && wife_rec != individual)
        {
          famc = find_type(individual, FAMC);
          output_pedigree_name(ofile, wife_rec, curdepth, famc, fams, glob_map,  buffer, 0, 0, buff2, max_depth);
        }

        if(curdepth > 0 && direction == 0) //No more children or second spouse
          clearbit(glob_map, curdepth);

        fams = find_next_this_type(individual, fams);
        child = find_type(family, CHIL);

        if(fams)
          setbit(glob_map, curdepth);

        if( ( max_depth == 0 || max_depth >= curdepth )
        && ((sex = find_type(individual, SEX)) && *sex->data == 'M') && child)
        {
          setbit(glob_map, curdepth + 1);
          print_bars(ofile, glob_map, curdepth + 1);
          print_lastbar(ofile, curdepth+1);
          fputc('\n', ofile);
          do
          {
            child_rec = find_hash(child->data);
            child = find_next_this_type(family, child);
            if(child_rec)
              output_decendants_info_of_name(ofile, child_rec, curdepth + 1, child  ? 1:0, glob_map , max_depth);
          }while(child);

          print_bars(ofile, glob_map, curdepth + 1);
          fputc('\n', ofile);
          clearbit(glob_map, curdepth + 1);
      
        }
        if(fams)
        {
          family = find_hash(fams->data);
          if(curdepth == 0 && family == 0)
            clearbit(glob_map, curdepth);
        }
        else
          family = 0;
      }         
      }
  end

