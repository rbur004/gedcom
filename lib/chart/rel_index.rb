#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

#include "ged.h"
#include "croll.h"
#include "stringfunc.h"
#include "btree.h"
#include "rel_index.h"

extern int pass;

void output_pedigree_index( FILE *ofile, ged_type *rt , int depth)
{
btree_node_p root = 0;

	pass++;
	create_pedigree_index(&root, rt, depth, 0);
	dump_t_index_as_html(ofile, root);
}

void output_descendants_index( FILE *ofile, ged_type *rt , int depth)
{
btree_node_p root = 0;

	pass++;
	create_descendants_index(&root, rt, depth, 0);
	dump_t_index_as_html(ofile, root);
}


void create_pedigree_index
(
	btree_node_p *root,
	ged_type *rt,
	int depth,
	int current_depth
)
{
ged_type *famc;
ged_type *family;
ged_type *husb, *wife;
ged_type *husb_rec, *wife_rec;
ged_type *resn;

    if(rt) //we haven't been given a null pointer
    {

    	if(rt->processed == pass)
		{	//A loop has occured. 
			return;
		}
			
		if((resn = find_type(rt, RESN)) && strcmp(resn->data, PRIVACY) == 0)
			return;
			
    	if((famc = find_type(rt, FAMC))) //look for family record to get parent info from
			family = find_hash(famc->data); //get the family record
		else
			family = 0;
				
		rt->processed = pass;			//set pass number to stop loops during this pass

		if(depth == 0 || current_depth <= depth )
		{
			if(  family 
		 	&& (husb = find_type(family, HUSB))
		 	&& (husb_rec = find_hash(husb->data))) //has a locatable father record
			{
				create_pedigree_index(root, husb_rec, depth, current_depth+1);
			}
		}
		//process this record.
		*root = add_index_name(*root, rt);

		if(depth == 0 || current_depth <= depth )
		{
			if(  family
		 	&& (wife = find_type(family, WIFE))
		 	&& (wife_rec = find_hash(wife->data))) //has a locatable mother record
			{
				create_pedigree_index(root,  wife_rec, depth, current_depth+1);
			}
		}

    }
}


void create_descendants_index
(
	btree_node_p *root,
	ged_type *rt,
	int depth,
	int current_depth
)
{
ged_type *fams;
ged_type *child;
ged_type *child_rec;
ged_type *family;
ged_type *husb, *wife;
ged_type *husb_rec, *wife_rec;
ged_type *resn;

    if(rt) 
    {
		if((resn = find_type(rt, RESN)) && strcmp(resn->data, PRIVACY) == 0)
			return;
			
    	if((fams = find_type(rt, FAMS))) 		//look for a family record
			family = find_hash(fams->data);		//retrieve that record
		else
			family = 0;
					
    	if(rt->processed == pass)
		{	//A loop has occured.
			return;
		}
			
		rt->processed = pass; //set so we can detect loops
					
		*root = add_index_name(*root, rt);
		
		while(  family ) //may have children from different spouses
		{
			if( (husb = find_type(family, HUSB))
		 	&& (husb_rec = find_hash(husb->data))
			&& husb_rec != rt )
			{
				*root = add_index_name(*root, husb_rec);
			}
			else if(  (wife = find_type(family, WIFE))
			 && (wife_rec = find_hash(wife->data))
		 	&& wife_rec != rt)
			{
				*root = add_index_name(*root, wife_rec);
			}

			fams = find_next_this_type(rt, fams);
			
			child = find_type(family, CHIL);

			if(child && (depth == 0 ||  current_depth <= depth))
			{
				do
				{
					child_rec = find_hash(child->data); //look for this childs record
					child = find_next_this_type(family, child); //check for other children
					if(child_rec)	//process this childs descendants
						create_descendants_index(root,  child_rec, depth, current_depth + 1); 
				} while(child); //look if more children

			}
			
			if(fams)
				family = find_hash(fams->data); //retrieve next family record of this person
			else
				family = 0;
		}					
    }
}
