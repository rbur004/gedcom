#btree for holding sorted indexes of names in our transmission
#Should look at replacing this with either this code packaged as a gem
#or with someone else's btree code.

class Btree_data
  
  attr_accessor :name, :individual_record
  
  def initialize(name, individual_record)
    @name, @individual_record = name, individual_record
  end 
  
end
  
class Btree_node
  
  attr_accessor :node_data
  
  def initialize(data = nil)
  	@balance;    #-1, if right subtree is deeper than the left subtree
  				       # 0, if the right and left sub-trees are the same height
  				       # 1, if the left sub-tree is deeper than the right sub-tree
  	@data = data  #Btree_data class.
  	@left = nil  # left sub-tree of words alphabetically before this nodes word
  	@right = nil #Right sub-tree of words alphabetically after this nodes word
  end
end 

  #Balanced binary tree methods
class Btree
  def initialize
    @root = nil #no nodes in the tree as yet.
  end

  balance_LL (a)
  #The Left hand branch of the right node is deeper than its Right branch
  	b = a.left;    
  	a.left, b.right = b.right, a

  	b.balance = 0
  	a.balance = 0

  	return b
  end

  balance_LR (a)
  #The Right hand branch of the right node is deeper than its left branch
  	b = a->left
  	c = b->right
	
  	a.left = c.right
  	b.right = c.left
	
  	c->left = b
  	c->right = a
	
  	case c.balance
  	when 1 
  		b.balance = 0
  		a.balance = -1
  	when 0
  		b.balance = 0
  		a.balance = 0
  	when -1
  		b.balance = 1
  		a.balance = 0
  	else
  		raise "balance_LR: Balance #{c->balance} error"
  	end
  	c->balance = 0;
	
  	return c
  end

  static btree_node_p rotate_right (btree_node_p tree)
  // The Left hand branch is deeper than the Right
  {
  		switch (tree->left->balance)
  		{
  		case 1: //tree is deeper on the left of the left child node
  				return balance_LL(tree);
  		case 0: //the left child tree is balanced and we just wasted our time calling the function
  				return tree;
  		case -1: //tree is deeper on the right of the left child node
  				return balance_LR(tree);
  		default:
  			printf("rotate_right: Balance %d error\n", tree->left->balance);
  			exit(1);
  		}
  }

  static btree_node_p balance_RR (btree_node_p A)
  //The Right hand branch of the right node is deeper than its left branch
  {
  btree_node_p B;

  		B = A->right;
  		A->right = B->left;
  		B->left = A;

  		B->balance = 0;
  		A->balance = 0;

  		return B;
  }

static btree_node_p balance_RL (btree_node_p A)
//The Left hand branch of the right node is deeper than its Right branch
{
btree_node_p B, C;

		B = A->right;
		C = B->left;

		A->right = C->left;
		B->left = C->right;

		C->right = B;
		C->left = A;

		switch (C->balance)
		{
		case -1: 
				B->balance = 0;
				A->balance = 1;
				break;
		case 0: 
				B->balance = 0;
				A->balance = 0;
				break;
		case 1: 
				B->balance = -1;
				A->balance = 0;
				break;
		default:
			printf("balance_RL: Balance %d error\n", C->balance);
			exit(1);
		}
		C->balance = 0;

		return C;
}

static btree_node_p rotate_left (btree_node_p tree)
//The right hand branch is deeper than the left
{

		switch (tree->right->balance)
		{
		case 1:  //tree is deeper on the left of the right child node
				return balance_RL(tree);
		case 0: //the right child tree is balanced and we just wasted our time calling the function
				return tree;
		case -1:  //tree is deeper on the right of the right child node
				return balance_RR(tree);
		default:
			printf("rotate_left: Balance %d error\n", tree->right->balance);
			exit(1);
		}
}

char *extract_surname
(
	tree_data *node, 
	char *surname
)
{
char *s;
ged_type *name = node->name;
char *q, *p;

	if(name)
	{
		if(p = strchr(name->data, '/'))
		{
			if((q = strchr(++p, '/')) == 0)
				q = p + strlen(p);
			for(s = surname; p != q; p++)
				if(isspace(*p))
					*s++ = '.';
				else
					*s++ = *p;
			*s = '\0';
			for(--s; *s == '.'; *s-- = '\0'); //remove trailing spaces
		}
		else
			surname[0] = '\0';
	}
	else
		surname[0] = '\0';
	return surname;
}

static char *extract_firstnames
(
	tree_data *node, 
	char *firstnames
)
{
char *f;
ged_type *name = node->name;
char *q, *p;

	if(name)
	{
		//Locate the surname
		if((q = strchr(name->data, '/')) == 0)
			q = &name->data[strlen(name->data)];
		
		//copy firstname.
		for(f = firstnames, p = name->data; p != q;)
			if(isspace(*p))
			{
				*f++ = '.';
				p++;
			}
			else
				*f++ = *p++;
		*f = '\0';
		
		for(--f; *f == '.'; *f-- = '\0'); //remove trailing spaces
	}
	else
		firstnames[0] = '\0';
	return firstnames;
}

static int cmp_node(tree_data *d1, tree_data *d2) 
{
// must return -1 if d1 < d2
//				0 if d1 == d2
//				1 if d1 > d2
char name1[128], name2[128];
int i;

	extract_surname(d1, name1);
	i = strlen(name1);
	name1[i++] = ' ';
	extract_firstnames(d1, &name1[i]);
	extract_surname(d2, name2);
	i = strlen(name2);
	name2[i++] = ' ';
	extract_firstnames(d2, &name2[i]);
	return strcasecmp(name1, name2);
}

static btree_node_p add_node( btree_node_p tree, tree_data *data)
{
btree_node_p new_node;

	if(tree == 0) 
	{	//there is no tree or we are adding to a subtree at a leaf node
		if((new_node = malloc(sizeof(btree_node))) == 0)
		{
			printf("add_node: no memory\n");
			exit(1);
		}
		new_node->data = data;
		new_node->balance = 0;	//nothing below us
		new_node->left = 0;	
		new_node->right = 0;
		return new_node; 		//add the new node to the tree
	}
	else //this isn't a leaf node and we may need to rotate the tree to balance it.
	{
		switch( cmp_node(data, tree->data) )
		{
		case -1:  // New word is before , alphabetically, the one in this node
			tree->left = add_node(tree->left, data); //add node to the left side is data < tree->data
			switch( tree->balance )
			{
			case 1: 
					return rotate_right(tree); //unbalanced so fix and return balanced tree
			case 0: 
					tree->balance = 1;	//because we just added to the left side
					return tree;		//Pass back the head of the tree (or subtree)
			case -1: 
					tree->balance = 0;	//Balanced because right side already had 1 extra
					return tree;		//Pass back the head of the tree (or subtree)
			default:
				printf("add_node left: Balance %d error\n", tree->balance);
				exit(1);
			}
		case 0:		//Treat a match as being after, We can have duplicates in this tree
		case 1:  	// New word is after the one, alphabetically, in this node
			tree->right = add_node(tree->right, data); //add node to the right side is data >= tree->data
			switch ( tree->balance )
			{
			case -1: 
					return rotate_left(tree); //unbalanced so fix and return balanced tree
			case 0: 
					tree->balance = -1; //because we just added to the right side
					return tree;		//Pass back the head of the tree (or subtree)
			case 1: 
					tree->balance = 0; //Balanced because left side already had 1 extra
					return tree;	   //Pass back the head of the tree (or subtree)
			default:
				printf("add_node right: Balance %d error\n", tree->balance);
				exit(1);
			}
		default:
			printf("cmp: error\n");
			exit(1);
		}
	}
}

//static int surname_count = 0;

void output_form(FILE *fp)
{
	fprintf(fp, "<FORM METHOD=GET  ACTION=\"/search\">\n");

    fprintf(fp, "Surname Search <INPUT NAME=\"Surname\" TYPE=text SIZE=\"48\">");

	fprintf(fp, "<P><INPUT TYPE=submit> </FORM><br><hr>\n");
	fprintf(fp, "<p><FORM METHOD=GET  ACTION=\"/search\">\n");

    fprintf(fp, "General Search <INPUT NAME=\"Match\" TYPE=text SIZE=\"48\">");

	fprintf(fp, "<P><INPUT TYPE=submit> </FORM><br>\n");
}

void dump_by_match
(
	FILE *fp, 
	char *match_me
)
{
char buff[32];
char buff2[32];
ged_type *name;
ged_type *fams;
ged_type *famc;
ged_type *chr;
ged_type *birt;
ged_type *death;
ged_type *date;
ged_type *g;
char firstnames[128], surname[128];
int mcount;
int b_date, d_date, chr_date;
char *p;
char *s;
tree_data *node;
int j;

	if(*match_me == '\0')
		return;
		
	if((node = malloc(sizeof(tree_data))) == 0)
	{
		printf("create_index: Could alloc a node\n");
		return;
	}

	fprintf(fp, "<html>\n<title>Match of %s</title>\n<NAME=\"IndexWindow\">\n<body><H2>Surname Index</H2>\n", match_me);

	output_form(fp);
	for(j = 0; j < 26; j++)
		fprintf(fp, "<A HREF=\"/surname/index_%c.html\" >%c</A> \n", j+'A', j+'A');
	fprintf(fp, "<A HREF=\"/surname/index_?.html\" >?</A><br>\n");

	for(j = 0; j < 26; j++)
		fprintf(fp, "<A HREF=\"/surnamef/index_%c.html\" >%c</A> \n", j+'A', j+'A');
	fprintf(fp, "<A HREF=\"/surnamef/index_?.html\" >?</A> <b>No Surname INDEX</b><p>\n");
	fprintf(fp, "<p>\n<pre><KBD>\n");

	for(g = head_INDI.next_this_type;g != &head_INDI; g=g->next_this_type) //for each INDI record
	{
		if(name = find_type(g, NAME))
		{
			do //Add under all names person has gone by.
			{
				node->name = name;
				node->indi = g;
				extract_surname(node, surname);
				extract_firstnames(node, firstnames);
				
				if(strcasestr(surname, match_me) || strcasestr(firstnames, match_me))
				{		

					strip_ats(buff, g->data);	
					fprintf(fp, "%-16.16s <A href=\"/html/%s\"  >%-24.24s</a>",
					surname,  buff, firstnames);
				    if((birt = find_type(g, BIRT)) && (date = find_type(birt, DATE)))
				    {
				    	if(b_date = return_year(date->data)) //Yes one ='s
				    		fprintf(fp, " <b>b.</b>%4.4d", b_date);
				    	else
				    		fprintf(fp, "       ");
				    }
				    else if((chr = find_type(g, CHR)) && (date = find_type(chr, DATE)))
				    {
				    	if(chr_date = return_year(date->data)) //Yes one ='s
				    		fprintf(fp, " <b>c.</b>%4.4d", chr_date);
				    	else
				    		fprintf(fp, "       ");
				     }
				     else 	
				    	fprintf(fp, "       ");

				    if((death = find_type(g, DEAT)) && (date = find_type(death, DATE)))
				    {
				    	if(d_date = return_year(date->data)) //Yes one ='s
				    		fprintf(fp, " <b>d.</b>%4.4d", d_date);
				    	else
				    		fprintf(fp, "       ");
					}
				    else
				    	fprintf(fp, "       ");
			 
					
					if(famc = find_type(g, FAMC))
					{
						strip_ats(buff, famc->data);
						strip_ats(buff2, g->data);
						fprintf(fp, " <A href=\"/html/%s.html#%s\"  ><b>Fam.</b></A>",  buff, buff2);
					}
					else
						fprintf(fp, " <b>      </b>");
					if(fams = find_type(g, FAMS))
					{
						mcount = 1;
						strip_ats(buff, fams->data);
						fprintf(fp, " <A href=\"/html/%s.html\"   ><b>M%d.</b></A>",  buff, mcount++);
						while(fams = find_next_this_type(g, fams))
						{
							strip_ats(buff, fams->data);
							fprintf(fp, " <A href=\"/html/%s.html\"   ><b>M%d.</b></A>",  buff, mcount++);
						}
					}

					//Add Ancestor and Descendant links.
					strip_ats(buff, g->data);
					fprintf(fp, " <a href=\"/TA10/%s\"  ><b>Anc.</b></a>  ", buff);
					fprintf(fp, "<a href=\"/TD10/%s\"  ><b>Des.</b></a>  ", buff);

					fprintf(fp, "\n");
				}

			}while(name = find_next_this_type(g, name));
		}
	}
	fprintf(fp, "<p></KBD></pre><b>Go to the Tree's </b><A HREF=\"http://www.burrowes.org/FamilyTree/\" ><b>Entry Page</b></A>.<p>\n");
	fprintf(fp, "<hr>Maintained by <A HREF=\"mailto:rob@cs.auckland.ac.nz\">Rob Burrowes</A>.<br>\n");
	fprintf(fp, "Rob's <A HREF=\"http://www.burrowes.org/~rob/\" >Home Page</A>\n");
	fprintf(fp, "</body></html>\n");
		
}

static void dump_tree_body
(
	FILE *fp, 
	btree_node_p tree, 
	char *filename, 
	int surname_or_full, 
	char *last_surname,
	int no_surname
)
{
char buff[32];
char buff2[32];
ged_type *fams;
ged_type *famc;
ged_type *birt;
ged_type *chr;
ged_type *death;
ged_type *date;
char firstnames[128], surname[128];
int mcount;
int b_date, d_date, chr_date;
char *p;
int firstname;

	if(tree == 0)
		return;
	else
	{
		dump_tree_body(fp, tree->left, filename, surname_or_full, last_surname, no_surname);
		
		if(no_surname)
		{
			firstname = 1;
			extract_firstnames(tree->data, surname); //fudge it by using the firstname.
		}
		else
		{
			firstname = 0;
			extract_surname(tree->data, surname);
		}
			
		if(strcasecmp(last_surname, surname) != 0)
		{
			if(surname_or_full & 0x4) //only want this surname
			{
				//fprintf(fp, "\"%s\" != \"%s\"\n", last_surname, surname);
				dump_tree_body(fp, tree->right, filename, surname_or_full, last_surname, no_surname);
				return;
			}
				
			fprintf(fp, "<A NAME=\"%s\"></A>\n", surname);
			strcpy(last_surname, surname);
			//surname_count++;
			
			if(surname_or_full & 0x1)
				fprintf(fp, "<A HREF=\"/search?%s=%s\"  >%s</A><br>\n", firstname ? "Firstname":"Surname", surname, surname);
		}
				
		
		if( surname_or_full & 0x2 )
		{
			if(no_surname == 1)
				surname[0] = '\0';
				
			fprintf(fp, "%-16.16s <A href=\"/html/%s\"  >%-24.24s</a>",
			surname, tree->data->indi->data,
			extract_firstnames(tree->data, firstnames));
		
		    if((birt = find_type(tree->data->indi, BIRT)) && (date = find_type(birt, DATE)))
		    {
		    	if(b_date = return_year(date->data)) //Yes one ='s
		    		fprintf(fp, " <b>b.</b>%4.4d", b_date);
		    	else
		    		fprintf(fp, "       ");
		    }
		    else if((chr = find_type(tree->data->indi, CHR)) && (date = find_type(chr, DATE)))
		    {
		    	if(chr_date = return_year(date->data)) //Yes one ='s
		    		fprintf(fp, " <b>c.</b>%4.4d", chr_date);
		    	else
		    		fprintf(fp, "       ");
		    }
		    else
		 	fprintf(fp, "       ");

		    if((death = find_type(tree->data->indi, DEAT)) && (date = find_type(death, DATE)))
		    {
		    	if(d_date = return_year(date->data)) //Yes one ='s
		    		fprintf(fp, " <b>d.</b>%4.4d", d_date);
		    	else
		    		fprintf(fp, "       ");
			}
		    else
		    	fprintf(fp, "       ");
	 
			
			if(famc = find_type(tree->data->indi, FAMC))
			{
				strip_ats(buff, famc->data);
				strip_ats(buff2, tree->data->indi->data);
				fprintf(fp, " <A href=\"/html/%s.html#%s\"  ><b>Fam.</b></A>",  buff, buff2);
			}
			else
				fprintf(fp, " <b>      </b>");
			if(fams = find_type(tree->data->indi, FAMS))
			{
				mcount = 1;
				strip_ats(buff, fams->data);
				fprintf(fp, " <A href=\"/html/%s.html\"   ><b>M%d.</b></A>",  buff, mcount++);
				while(fams = find_next_this_type(tree->data->indi, fams))
				{
					strip_ats(buff, fams->data);
					fprintf(fp, " <A href=\"/html/%s.html\"   ><b>M%d.</b></A>",  buff, mcount++);
				}
			}

			//Add Ancestor and Descendant links.
			strip_ats(buff, tree->data->indi->data);
			fprintf(fp, " <a href=\"/TA10/%s\"  ><b>Anc.</b></a>  ", buff);
			fprintf(fp, "<a href=\"/TD10/%s\"  ><b>Des.</b></a>  ", buff);

			fprintf(fp, "\n");
		}

		dump_tree_body(fp, tree->right, filename, surname_or_full, last_surname, no_surname);
	}		
}

static int char_to_index(char c)
{
char t;

	if((t = toupper(c)) < 'A' || t > 'Z')
		return 26;		//Add to '?' list
	else
		return t - 'A';	//calculate index
}

static int surname_char(char *name)
{
char *p;
char t;

	if((p = strchr(name, '/')) && *++p != '/')
		return char_to_index(*p);	
	else
		return 27 + char_to_index(*name);	//use firstname to classify it
}


void dump_Surname_as_html(FILE *fp, char letter, int no_surname)
{
int j;
int i = char_to_index(letter);
char buff[16];
char last_surname[128];
char *s;

	if(i != 26)	
		letter = i + 'A';
	else
		letter = '?';
	
	if(no_surname)
	{
		i += 27;
		s = "f";
	}
	else
		s = "";
	
	//generate Index file for each letter
	last_surname[0] = '\0'; //ready for cmp.
	
	fprintf(fp, "<html>\n<title>Surname index%s_%c.html</title>\n<NAME=\"IndexWindow\">\n<body><H2>Surname Index</H2>\n", s, letter);

	output_form(fp);
	for(j = 0; j < 26; j++)
		fprintf(fp, "<A HREF=\"/surname/index_%c.html\" >%c</A> \n", j+'A', j+'A');
	fprintf(fp, "<A HREF=\"/surname/index_?.html\" >?</A><br>\n");

	for(j = 0; j < 26; j++)
		fprintf(fp, "<A HREF=\"/surnamef/index_%c.html\" >%c</A> \n", j+'A', j+'A');
	fprintf(fp, "<A HREF=\"/surnamef/index_?.html\" >?</A> <b>No Surname INDEX</b><p>\n");
	//fprintf(fp, "<A HREF=\"/index/index_%c.html\">Full Index</A>\n", letter);
	fprintf(fp, "<p>\n");

	sprintf(buff, "index%s_%c.html", s,  letter); 
	dump_tree_body(fp, root[i], buff, 0x1, last_surname, no_surname);

	fprintf(fp, "<p><b>Go to the Tree's </b><A HREF=\"http://www.burrowes.org/FamilyTree/\" ><b>Entry Page</b></A>.<p>\n");
	fprintf(fp, "<hr>Maintained by <A HREF=\"mailto:rob@cs.auckland.ac.nz\">Rob Burrowes</A>.<br>\n");
	fprintf(fp, "Rob's <A HREF=\"http://www.burrowes.org/~rob/\" >Home Page</A>\n");
	fprintf(fp, "</body></html>\n");
		
}

void dump_index_as_html(FILE *fp, char letter, int no_surname)
{
int j;
int i = char_to_index(letter);
char buff[16];
char last_surname[128];
char *s;
	
	if(i != 26)	
		letter = i + 'A';
	else
		letter = '?';
	
	//generate Index file for the letter
	last_surname[0] = '\0'; //ready for cmp.
	
	if(no_surname)
	{
		i += 27;
		s = "f";
	}
	else
		s = "";
	
	fprintf(fp, "<html>\n<title>index%s_%c.html</title>\n<NAME=\"IndexWindow\">\n<body><H2>Full Index</H2>\n",s, letter);
	
	output_form(fp);
	for(j = 0; j < 26; j++) //Splash indexes across top of the page
		fprintf(fp, "<A HREF=\"/index/index_%c.html\"  >%c</A> \n", j+'A', j+'A');
	fprintf(fp, "<A HREF=\"/index/index_?.html\"  >?</A>\n");
	fprintf(fp, "<A HREF=\"/surname/index_%c.html\"  >To Surname Only Index</A><br>\n", letter);

	for(j = 0; j < 26; j++) //Splash no surname indexes across top of the page
		fprintf(fp, "<A HREF=\"/indexf/index_%c.html\"  >%c</A> \n", j+'A', j+'A');
	fprintf(fp, "<A HREF=\"/indexf/index_?.html\"  >?</A> <b>No Surname INDEX</b><p>\n");
	

	fprintf(fp, "<p>\n<pre><KBD>\n");
	sprintf(buff, "index%s_%c.html", s, letter); 
	dump_tree_body(fp, root[i], buff, 0x2, last_surname, no_surname);

	fprintf(fp, "</KBD></pre><b>Go to the Tree's </b><A HREF=\"http://www.burrowes.org/FamilyTree/\" ><b>Entry Page</b></A>.<p>\n");
	fprintf(fp,"<hr>Maintained by <A HREF=\"mailto:rob@cs.auckland.ac.nz\">Rob Burrowes</A>.<br>\n");
	fprintf(fp, "Rob's <A HREF=\"http://www.burrowes.org/~rob/\" >Home Page</A>\n");
	fprintf(fp, "</body></html>\n");
}

void dump_t_index_as_html(FILE *fp, btree_node_p r)
{
char buff[16];
char last_surname[128];
	
	
	//fprintf(fp, "<html>\n<title>index.html</title>\n<NAME=\"IndexWindow\">\n<body>\n");
	
	last_surname[0] = '\0';
	
	fprintf(fp, "<p>\n<pre><KBD>\n");
	sprintf(buff, "index.html"); 
	dump_tree_body(fp, r, buff, 0x2, last_surname, 0);

	//fprintf(fp, "</KBD></pre><b>Go to the Tree's </b><A HREF=\"http://www.burrowes.org/FamilyTree/\" ><b>Entry Page</b></A>.<p>\n");
	//fprintf(fp,"<hr>Maintained by <A HREF=\"mailto:rob@cs.auckland.ac.nz\">Rob Burrowes</A>.<br>\n");
	//fprintf(fp, "Rob's <A HREF=\"http://www.burrowes.org/~rob/\" >Home Page</A>\n");
	//fprintf(fp, "</body></html>\n");
}

void dump_shortindex_as_html(FILE *fp,  char *thesurname, int no_surname)
{
int j;
char name_buff[128];
char letter = thesurname[0];
int i = char_to_index(letter);
char buff[32];
char *s;
char *p = 0;
	
	if(i != 26)	
	{
		if(strncasecmp("de.", thesurname, 3) != 0)
			sprintf(name_buff, "de.%s", thesurname);
		else
		{
			p = strrchr(thesurname, '.');
			sprintf(name_buff, "%s", ++p);
		}
		letter = i + 'A';
	}
	else
	{
		name_buff[0] = '\0';
		letter = '?';
	}
	
	if(no_surname)
	{
		i += 27;
		s = "f";
	}
	else
		s = "";
	
	fprintf(fp, "<html>\n<title>%s Index%s</title> <NAME=\"IndexWindow\"> \n<body><H2>%s Index</H2>\n",thesurname, s, thesurname);
	
	output_form(fp);
	for(j = 0; j < 26; j++) //Splash indexes across top of the page
		fprintf(fp, "<A HREF=\"/surname/index_%c.html\" >%c</A> \n", j+'A', j+'A');
	fprintf(fp, "<A HREF=\"/surname/index_?.html\" >?</A><br>\n");

	for(j = 0; j < 26; j++) //Splash no surname indexes across top of the page
		fprintf(fp, "<A HREF=\"/surnamef/index_%c.html\" >%c</A> \n", j+'A', j+'A');
	fprintf(fp, "<A HREF=\"/surnamef/index_?.html\" >?</A> <b>No Surname INDEX</b>\n");
	
	//fprintf(fp, "<A HREF=\"/index/index_%c.html\" >Full Index</A>\n", letter);
	

	fprintf(fp, "<p>\n<pre><KBD>\n");
	sprintf(buff, "index%s_%c.html", s, letter); 
	if(no_surname == 0 && p == 0 && name_buff[0] != '\0')
		dump_tree_body(fp, root[char_to_index(name_buff[0])], buff, 0x6, name_buff, no_surname);
	dump_tree_body(fp, root[i], buff, 0x6, thesurname, no_surname);
	if(no_surname == 0 && p != 0 && name_buff[0] != '\0')
		dump_tree_body(fp, root[char_to_index(name_buff[0])], buff, 0x6, name_buff, no_surname);

	fprintf(fp, "</KBD></pre><b>Go to the Tree's </b><A HREF=\"http://www.burrowes.org/FamilyTree/\" ><b>Entry Page</b></A>.<p>\n");
	fprintf(fp,"<hr>Maintained by <A HREF=\"mailto:rob@cs.auckland.ac.nz\">Rob Burrowes</A>.<br>\n");
	fprintf(fp, "Rob's <A HREF=\"http://www.burrowes.org/~rob/\" >Home Page</A>\n");
	fprintf(fp, "</body></html>\n");
}


void create_index()
{
ged_type *g;
ged_type *name;
ged_type *resn;
int index;
int i;
tree_data *node;

	for(i = 0; i < 26; i++)
		root[i] = 0;
		
	for(g = head_INDI.next_this_type; g != &head_INDI; g=g->next_this_type)
	{
		if((resn = find_type(g, RESN)) && strcmp(resn->data, PRIVACY) == 0)
			continue;
		if(name = find_type(g, NAME))
		{
			do //Add under all names person has gone by.
			{
				if((node = malloc(sizeof(tree_data))) == 0)
				{
					printf("create_index: Could alloc a node\n");
					return;
				}
				node->name = name;
				node->indi = g;
				index = surname_char(name->data); 			 //decide which letter to index under
				root[index] = add_node( root[index], node ); //Add node to that index
			}while(name = find_next_this_type(g, name));
		}
	}
	//dump_tree_as_html();
}

btree_node_p add_index_name(btree_node_p root, ged_type *rt)
{
ged_type *name;
tree_data *node;

		if(name = find_type(rt, NAME))
		{
			do //Add under all names person has gone by.
			{
				if((node = malloc(sizeof(tree_data))) == 0)
				{
					printf("add_index_name: Couldn't alloc a node\n");
					return root;
				}
				node->name = name;
				node->indi = rt;
				root = add_node( root, node ); //Add node to that index
			}while(name = find_next_this_type(rt, name));
		}
		return root;
}
