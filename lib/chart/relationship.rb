#define RELATION_C
/*
 * Construction of pedigree charts
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ged.h"
#include "croll.h"
#include "chart.h"
#include "pathnames.h"
#include "bit.h"
#include "relationship.h"

#define IGNORE (ged_type *) 0xFFFFFFFFFFFFFFFF

static void Clear_trace_1(ged_type *rt)
{
ged_type *famc, *family, *husb, *husb_rec, *wife, *wife_rec;
			
	free_rel_list_X(&rt->rel_child_1); //clear pointer
	
	if( (famc = find_type(rt, FAMC)) 				//look for a family record
	 && (family = find_hash(famc->data)) != 0)		//retrieve that record
	{
		if( (husb = find_type(family, HUSB)) 	//find the father
	 	&& (husb_rec = find_hash(husb->data)))	//retrieve the record
		{
			Clear_trace_1(husb_rec);
		}
		if(  (wife = find_type(family, WIFE))	//find the Mother
		 && (wife_rec = find_hash(wife->data)))	//retrieve the record
		{
			Clear_trace_1(wife_rec);
		}
	}
}

static void Clear_trace_2(ged_type *rt)
{
ged_type *famc, *family, *husb, *husb_rec, *wife, *wife_rec;

	free_rel_list_X(&rt->rel_child_2); //clear pointer
	
	if( (famc = find_type(rt, FAMC)) 				//look for a family record
	 && (family = find_hash(famc->data)) != 0)		//retrieve that record
	{
		if( (husb = find_type(family, HUSB)) 	//find the father
	 	&& (husb_rec = find_hash(husb->data)))	//retrieve the record
		{
			Clear_trace_2(husb_rec);
		}
		if(  (wife = find_type(family, WIFE))	//find the Mother
		 && (wife_rec = find_hash(wife->data)))	//retrieve the record
		{
			Clear_trace_2(wife_rec);
		}
	}
}


static void trace_indi_1(ged_type *rt, ged_type *srt, ged_type *child, int level)
{
ged_type *famc, *family, *husb, *husb_rec, *wife, *wife_rec;
rel_list_type *rl;
//ged_type *name;

//	if(name = find_type(rt, NAME))
//		printf("trace_indi_1:%d %s\n", level, name->data);

	if(rt == 0)
		return;
		
	if(in_rel_list_X(rt->rel_child_1, child, 0, level))
		return; //we have a loop as this parent and child path have been recorded
		
	add_to_rel_list_X(&rt->rel_child_1, child, 0, level++);//record the path we took to get here
	
	if( (famc = find_type(rt, FAMC)) 				//look for a family record
	 && (family = find_hash(famc->data)) != 0)		//retrieve that record
	{
		if(  (wife = find_type(family, WIFE)))	//find the Mother
			wife_rec = find_hash(wife->data);	//retrieve the record
		else
			wife_rec = 0;
		if( (husb = find_type(family, HUSB)) 	//find the father
	 	&& (husb_rec = find_hash(husb->data)))	//retrieve the record
		{
			trace_indi_1(husb_rec, wife_rec, rt, level);
		}
		else
			husb_rec = 0;
		if( wife_rec )
		{
			trace_indi_1(wife_rec, husb_rec, rt, level);
		}
	}
}

static void trace_indi_2(ged_type *rt, ged_type *srt, ged_type *child, int level)
{
ged_type *famc, *family, *husb, *husb_rec, *wife, *wife_rec;
rel_list_type *rl1, *rl2;
int add_them;
//ged_type *name;

//	if(name = find_type(rt, NAME))
//		printf("trace_indi_2:%d %s\n", level, name->data);

	if(rt == 0)
		return;
		
	if(in_rel_list_X(rt->rel_child_2, child, 0, level))
		return; //we have a loop as this parent and child path have been recorded
	
	add_to_rel_list_X(&rt->rel_child_2, child, 0, level++);//record the path we took to get here
	
	if(rt->rel_child_1 != 0)
	{	//This person has a link back to the first individual.
		add_them = 0;
		for(rl1 =  rt->rel_child_1; rl1 != 0; rl1 = rl1->next)
		{
			if(rl1->rt != child) 
			{
				add_them = 1;	//we don't think this is a common direct relative of rt_1
				break;
			}
		}
		if(add_them)
			add_to_rel_list(rt, srt); //we have a match but it may not be the only or shortest
									  // link and we may have to remove it later as it may
									  // be a direct relative of both parties
	}
	
	if( (famc = find_type(rt, FAMC)) 				//look for a family record
	 && (family = find_hash(famc->data)) != 0)		//retrieve that record
	{
		if(  (wife = find_type(family, WIFE)))	//find the Mother
			wife_rec = find_hash(wife->data);	//retrieve the record
		else
			wife_rec = 0;
			
		if( (husb = find_type(family, HUSB)) 	//find the father
	 	&& (husb_rec = find_hash(husb->data)))	//retrieve the record
		{
			trace_indi_2(husb_rec, wife_rec, rt, level);
		}
		else
			husb_rec = 0;
			
		if( wife_rec )
		{
			trace_indi_2(wife_rec, husb_rec, rt, level);
		}
	}
}

static void relation_chart
(
	FILE *ofile, 
	ged_type *rt,
	int curdepth,
	unsigned int *glob_map, ged_type *rt_1, ged_type *rt_2,
	int max_depth
)
{
ged_type *fams;
ged_type *famc;
rel_list_type *rl, *rl_tmp;
extern int pass;

	if(rt)
	{
		pass++;
		if(rt_1 == rt_2)
		{
	    	fams = find_type(rt, FAMS); //look for a spouse and family			
			famc = find_type(rt, FAMC);
			output_pedigree_name(ofile, rt, curdepth, famc, fams, glob_map, "-", 0, 0, "", max_depth);
			return;
		}
		if(rt != rt_1)
			rt_1->processed = pass;
		if(rt != rt_2)
			rt_2->processed = pass;
		output_decendants_info(ofile, rt, 0, 0, glob_map, 1 , max_depth);
	}
}



static rel_list_type *rel_list;

static void init_rel_list() //the list should start empty
{
	rel_list = 0;
}

static void add_to_rel_list(ged_type *rt, ged_type *srt)
{
	if(in_rel_list_X(rel_list, rt, IGNORE, -1) 
	|| in_rel_list_X(rel_list, srt, rt, -1))
		return; //don't add twice for the same spouse combination
	add_to_rel_list_X(&rel_list, rt, srt, -1);
}		

static void add_to_rel_list_X(rel_list_type **X, ged_type *rt, ged_type *srt, int level)
{
rel_list_type *rl;
rel_list_type *rl1;
rel_list_type *rl2;

	if((rl = (rel_list_type *)malloc(sizeof(rel_list_type))) == 0) //get memory for a list member
	{
		perror("add_to_rel_list(): unable to malloc rel_list element");
		return;
	}

	rl->rt = rt; 		//set pointer to data
	rl->srt = srt; 		//set pointer to data to spouse record
	rl->level = level;	//set number of generation through this link
	rl->direct = 0;


	//add to list in lowest to highest order
	if(rl1 = *X)
	{ //list in not empty
		if(rl1->level > level) 
		{ //it should be added as the first list element
			rl->next = rl1; //insert at head
			*X = rl;
		} 
		else
		{ //find the place to add it
			for(rl2=rl1->next; rl2 != 0; rl1=rl2, rl2=rl2->next) 
			{
				if(rl2->level > level)
					break;
			}
			rl->next = 0;
			rl1->next = rl;
		}
	}
	else
	{ //is the only element in the list
		*X = rl;
		rl->next = 0;
	}
}		

static void process_rel_list(FILE *fout, ged_type *rt_1, ged_type *rt_2, int maxdepth) //return the lists memory to the pool
{
rel_list_type *rl, *rl1, *rl2;
unsigned int glob_map[8];
int i;
int level1, level2;
int valid;
ged_type *name1, *name2;
//ged_type *name3, *name4;

	fprintf(fout, "<HTML><TITLE>Rel</TITLE><NAME=\"IndexWindow\">\n<BODY><HR>\n<PRE>\n");

	for(i = 0; i < 8; i++)
		glob_map[i] = 0;

	fprintf(fout, "Finding Relationship between indi_1");
	if(name1 = find_type(rt_2, NAME))
		fprintf(fout, " %s<br> and ", name1->data);
	else
		fprintf(fout, " Unknown<br> and ");
	if(name2 = find_type(rt_1, NAME))
		fprintf(fout, "indi_2 %s<br>\n", name2->data);
	else
		fprintf(fout, "indi_2 Unknown<br>\n");

	if(rel_list == 0)
		fprintf(fout, "Individuals are not related by blood<br>\n");
	else
	{
		for(rl = rel_list; rl != 0; rl = rl->next)
		{
			valid = 0;
			for(rl1 =  rl->rt->rel_child_1; rl1 != 0; rl1 = rl1->next) //paths to rl_1
			{	
				for(rl2 =  rl->rt->rel_child_2; rl2 != 0; rl2 = rl2->next) //paths to rl_2
				{	//if the path from through child rl1->rt is also a valid path to rl_2 
					//and the child rl2->rt is also a valid path to rl1 then skip it
					if(in_rel_list_X(rl->rt->rel_child_2, rl1->rt, 0, -1)
					&& in_rel_list_X(rl->rt->rel_child_1, rl2->rt, 0, -1)) 
					{
						//if(name && name2 && (name3 = find_type(rl1->rt, NAME)) && (name4 = find_type(rl2->rt, NAME)))
						//{
							//fprintf(fout, "Child %s ancestor of %s is also in the valid path list of %s<br>\n",
							//				name3->data, name1->data, name2->data);
							//fprintf(fout, "And Child %s ancestor of %s is also in the valid path list of %s<br>\n",
							//				name4->data, name2->data, name1->data);
						//}
						continue;
					}
					valid = 1;
					level1 = rl1->level;
					level2 = rl2->level;
					if(level1 == 0)
					{
						if(level2 == 0)
							fprintf(fout, "Both individuals are the same person<br>\n");
						else if(level2 == 1)
							fprintf(fout, "indi1 is child of indi2<br>\n");
						else if(level2 == 2)
							fprintf(fout, "indi1 is grand child of indi2<br>\n");
						else if(level2 == 3)
							fprintf(fout, "indi1 is great grand child of indi2<br>\n");
						else if(level2 > 3)
							fprintf(fout, "indi1 is great x %d grand child of indi2<br>\n", level2 - 2);
					}
					else if(level2 == 0)
					{
						if(level1 == 1)
							fprintf(fout, "indi1 is a parent of indi2<br>\n");
						else if(level1 == 2)
							fprintf(fout, "indi1 is grandparent of indi2<br>\n");
						else if(level1 == 3)
							fprintf(fout, "indi1 is great grandparent of indi2<br>\n");
						else if(level1 > 3)
							fprintf(fout, "indi1 is great x %d grandparent of indi2<br>\n", level1 - 2);
					}
					else if(level1 == 1)
					{
						if(level2 == 1)
							fprintf(fout, "indi1 is a sibling of indi2<br>\n");
						else if (level2 == 2)
							fprintf(fout, "indi1 is a nephew/niece of indi2<br>\n");
						else if (level2 == 3)
							fprintf(fout, "indi1 is a great nephew/niece of indi2<br>\n");
						else if (level2 > 3)
							fprintf(fout, "indi1 is a great x %d nephew/niece of indi2<br>\n", level1);
					}
					else if(level2 == 1)
					{
						if (level1 == 2)
							fprintf(fout, "indi1 is an uncle/aunt of indi2<br>\n");
						else if (level1 == 3)
							fprintf(fout, "indi1 is a great uncle/aunt of indi2<br>\n");
						else if (level1 > 3)
							fprintf(fout, "indi1 is a great x %d uncle/aunt of indi2<br>\n", level2);
					}
					else
					{
					int diff = level1 - level2;
						if (diff > 0)
							fprintf(fout, "indi1 and indi2 are %d cousins %d removed<br>\n", 
								level2 - 1, diff);
						else if (diff < 0)
							fprintf(fout, "indi1 and indi2 are %d cousins %d removed<br>\n", 
								level1 - 1, -diff);
						else
							fprintf(fout, "indi1 and indi2 are %d cousins<br>\n", level1 - 1);
					}
				}
			}
			if(valid)
			{
				relation_chart(fout, rl->rt, 0,  glob_map, rt_1, rt_2, maxdepth);
				fprintf(fout,"<p>\n");
			}
		}
	}
	fprintf(fout,"</pre><b>Go to the Tree's </b><A HREF=\"http://www.burrowes.org/FamilyTree/\"  ><b>Entry Page</b></A>.<p>\n");
	fprintf(fout,"<hr>Maintained by <A HREF=\"mailto:rob@cs.auckland.ac.nz\">Rob Burrowes</A>.<br>\n");
	fprintf(fout,"Rob's <A HREF=\"http://www.burrowes.org/~rob/\"  >Home Page</A>\n");
	fprintf(fout, "</BODY></HTML>\n");

}

static void free_rel_list() //return the lists memory to the pool
{
	free_rel_list_X(&rel_list);
}

static void free_rel_list_X(rel_list_type **X) //return the lists memory to the pool
{
rel_list_type *rl, *rl_tmp;
	for(rl = *X; rl != 0; rl = rl_tmp)
	{
		rl_tmp = rl->next;
		free(rl);
	}
	*X = 0;
}

static void remove_from_rel_list(ged_type *rt, ged_type *srt)
{
rel_list_type *rl, *rl_tmp;

	if(rel_list)
	{
		if(rel_list->rt == rt && rel_list->srt == srt)
		{
			rl_tmp = rel_list;
			rel_list = rel_list->next;
			free (rl_tmp);
		}
		else 
		{
			for(rl = rel_list; rl->next != 0; rl = rl->next)
			{
				if(rl->next->rt == rt && rl->next->srt == srt)
				{
					rl_tmp = rl->next;
					rl->next = rl->next->next;
					free (rl_tmp);
					return;
				}
			}
		}
	}
}

int in_rel_list(rel_list_type *X, ged_type *rt)
{
rel_list_type *rl;

	for(rl = X; rl != 0; rl = rl->next)
	{
		if(rt == rl->rt)
			return 1;
	}
	return 0;
}

rel_list_type * in_rel_list_X(rel_list_type *X, ged_type *rt, ged_type *srt, int level) //return the lists memory to the pool
{
rel_list_type *rl;

	for(rl = X; rl != 0; rl = rl->next)
	{
		if((rt == IGNORE || rt == rl->rt)
		 && (srt == IGNORE || srt == rl->srt) 
		 && (level == -1 || level == rl->level))
			return rl;
	}
	return 0;
}


void find_relationship
(
	FILE *fout,
	ged_type *rt_1,
	ged_type *rt_2, 
	int maxdepth
)
{
ged_type *famc, *family, *husb, *husb_rec, *wife, *wife_rec;
rel_list_type *rl1;

	if(rt_1 == 0 || rt_2 == 0)
		return; //we don't have valid start points

	init_rel_list();
	
	rt_1->rel_child_1 = (rel_list_type *)0; 
	rt_1->rel_child_2 = (rel_list_type *)0; 
	rt_2->rel_child_1 = (rel_list_type *)0; 	
	rt_2->rel_child_2 = (rel_list_type *)0; 	

	if(rt_1 == rt_2) //don't need to proceed further if they are the same individual
	{
		add_to_rel_list(rt_1, 0); 
	}
	else
	{
		if( (famc = find_type(rt_1, FAMC)) 				//look for a family record
		 && (family = find_hash(famc->data)) != 0)	//retrieve that record
		{
			
			//Don't need to add this as it can't be duplicated.					
			add_to_rel_list_X(&rt_1->rel_child_1, 0, 0, 0);
			
			if(  (wife = find_type(family, WIFE)))	//find the Mother
				wife_rec = find_hash(wife->data);	//retrieve the record
			else
				wife_rec = 0;
			if( (husb = find_type(family, HUSB)) 	//find the father
		 	&& (husb_rec = find_hash(husb->data)))	//retrieve the record
			{
				trace_indi_1(husb_rec, wife_rec, rt_1, 1);
			}
			else
				husb_rec = 0;
			if( wife_rec )	//retrieve the record
			{
				trace_indi_1(wife_rec, husb_rec, rt_1, 1);
			}

			//Search the second individual's tree only if there is a valid tree for rt_1.
			
			//Don't need to add this as it can't be duplicated.					
			add_to_rel_list_X(&rt_2->rel_child_2, 0, 0, 0);
					
			if(rt_2->rel_child_1 != 0) //will thus be a direct ancestor.
			{
				add_to_rel_list(rt_2, 0);
				//we have a match but it may not be the only or shortest link
				//continue as one of their ancestors may be related in another way.
			}
			
			if( (famc = find_type(rt_2, FAMC)) 				//look for a family record
			 && (family = find_hash(famc->data)) != 0)	//retrieve that record
			{
				if(  (wife = find_type(family, WIFE)))	//find the Mother
					wife_rec = find_hash(wife->data);	//retrieve the record
				else
					wife_rec = 0;
					
				if( (husb = find_type(family, HUSB)) 	//find the father
			 	&& (husb_rec = find_hash(husb->data)))	//retrieve the record
				{
					trace_indi_2(husb_rec, wife_rec, rt_2, 1);
				}
				else
					husb_rec = 0;
					
				if( wife_rec )	//retrieve the record
				{
					trace_indi_2(wife_rec, husb_rec, rt_2, 1);
				}
			}
		}
	}

	process_rel_list(fout, rt_1, rt_2, maxdepth);
	free_rel_list();

	Clear_trace_1(rt_1);
	Clear_trace_2(rt_2);
}
