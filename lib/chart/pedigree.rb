/*
 * Construction of pedigree charts
 */
 
class 


 PEDIGREE_WIDTH 3 
int  pass = 0;  //have we looped

static void print_lastbar(FILE *ofile, int depth);
static void print_lastspace(FILE *ofile);

void output_pedigree( FILE *ofile, ged_type *rt , int max_depth)
{
int *widths, i;
ged_type *name;
char *title;
unsigned int glob_map[8];

	for(i = 0; i < 8; i++)
		glob_map[i] = 0;

	if(name = find_type(rt, NAME))
		title = name->data;
	else
		title = "unknown";
      
	//compute_pedigree_widths(rt, depth, widths);
	fprintf(ofile, "<HTML><TITLE>%s Ances.</TITLE><NAME=\"IndexWindow\">\n<BODY><HR>\n<PRE>\n", title);
	pass++;
	output_pedigree_info(ofile, rt, 0, 0, glob_map, 0, max_depth);
	output_pedigree_index(ofile, rt, max_depth );
	fprintf(ofile,"</pre><b>Go to the Tree's </b><A HREF=\"http://www.burrowes.org/FamilyTree/\"  ><b>Entry Page</b></A>.<p>\n");
	fprintf(ofile,"<hr>Maintained by <A HREF=\"mailto:rob@cs.auckland.ac.nz\">Rob Burrowes</A>.<br>\n");
	fprintf(ofile,"Rob's <A HREF=\"http://www.burrowes.org/~rob/\"  >Home Page</A>\n");
	fprintf(ofile, "</BODY></HTML>\n");
}

void output_pedigree_info
(
	FILE *ofile, 
	ged_type *rt,
	int curdepth,
	int direction,
	unsigned int *glob_map,
	char *child_marker,
	int max_depth
)
{
ged_type *famc;
ged_type *fams;
ged_type *family;
ged_type *husb, *wife;
ged_type *husb_rec, *wife_rec;

    if(rt) 
    {

    	if((famc = find_type(rt, FAMC)))
			family = find_hash(famc->data);
		else
			family = 0;
		fams = find_type(rt, FAMS);
				
    	if(rt->processed == pass)
		{	//A loop has occured. Print the record with a * and return
			output_pedigree_name(ofile, rt, curdepth, famc, fams, glob_map, "*", child_marker, 1, "", max_depth);
			if(direction)
				setbit(glob_map,curdepth);	//IF you are male parent then set this level bit
			else
				clearbit(glob_map,curdepth);	//below female parent we don't want the bit set
			print_bars(ofile, glob_map, curdepth); 
			if(isbitset(glob_map, curdepth))
				print_lastbar(ofile, curdepth);
			else
				print_lastspace(ofile);
			fputc( '\n', ofile);
			clearbit(glob_map,curdepth);		//below this level we don't want the bit set
			return;
		}
			
		rt->processed = pass;			

		if( ( max_depth == 0 || max_depth >= curdepth )
		 && family 
		 && (husb = find_type(family, HUSB))
		 && (husb_rec = find_hash(husb->data)))
		{
			output_pedigree_info(ofile, husb_rec, curdepth + 1, 1, glob_map, rt->data, max_depth);
		}

			
		output_pedigree_name(ofile, rt, curdepth, famc, fams, glob_map, "", child_marker, 1, "", max_depth);

		if(direction)
			setbit(glob_map, curdepth);	//IF you are male parent then set this level bit
		else
			clearbit(glob_map, curdepth);	//below female parent we don't want the bit set

		if( ( max_depth == 0 || max_depth >= curdepth )
		 && family
		 && (wife = find_type(family, WIFE))
		 && (wife_rec = find_hash(wife->data)))
		{
			setbit(glob_map, curdepth+1); //set the next level line drawing bit
			print_bars(ofile, glob_map, curdepth + 1); 
			print_lastbar(ofile, curdepth+1);
			fputc( '\n', ofile); 
			output_pedigree_info(ofile, wife_rec, curdepth + 1, 0, glob_map, rt->data, max_depth);
		}
		else
		{
			print_bars(ofile, glob_map, curdepth); 
			if(isbitset(glob_map, curdepth))
				print_lastbar(ofile, curdepth);
			else
				print_lastspace(ofile);
			fputc( '\n', ofile);
		} 

		clearbit(glob_map, curdepth);	//below this level we don't want the bit set
										//Not That it will be printed anyway.
    }
}






