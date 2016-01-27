#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "plot_command.h"

#define NUM_POINTS 5

#define MAX_INDEX	12


int count_index_num (char *);
int get_index_names (char [][30] ,char * );

void usage (){
	printf("\nUsage: ./plot in.sv out.eps x_axis_label  y_axis_label key_pos   \n");
	printf("  in.sv : input file contains the plotting data:\n");
	printf(" \t #name:first_graph_name\n");
	printf(" \t first_graph_x1 first_graph_y1 \n \t first_graph_x2 first_graph_y2\n\t . \n\t .\n");
	printf(" \t first_graph_xn first_graph_yn \n \n\n");
	printf(" \t #name:second_graph_name\n");
	printf(" \t second_graph_x1 second_graph_y1 \n \t . \n \t . \n\n");
	printf("  y_axis_label: this label will be shown for y axis data in graph\n");
	printf("  x_axis_label: this label will be shown for x axis data in graph\n");
	printf("  out.eps : output file name\n");
	printf("  key_pos : Gnuplot key position. e.g. \"left bottom\"\n");


}



//int plot(char in_file_name[], char out_file_name[])
int main (int argc, char *argv[])
{
 printf("argc=%d\n",argc);
if(argc!= 6) {usage();  return;}
 char * in_file_name =argv[1];
 char * out_file_name=argv[2];
 char * x_lable	     =argv[3];
 char * y_lable	     =argv[4];
 char * key_pos		= argv[5];

 int i, index_num;
  
char  label [MAX_INDEX][30];

for (i=0; i<MAX_INDEX; i++) sprintf(label [i],"Index%u",i);




char plot_cmd[3000]={};


   // double xvals[NUM_POINTS] = {1.0, 2.0, 3.0, 4.0, 5.0};
  //  double yvals[NUM_POINTS] = {5.0 ,3.0, 1.0, 3.0, 5.0};
    //FILE * temp = fopen("data.temp", "w");
    /*Opens an interface that one can use to send commands as if they were typing into the
     *     gnuplot command line.  "The -persistent" keeps the plot open even after your
     *     C program terminates.
     */
FILE * pipe = popen ("gnuplot -persistent", "w");

 
 
 index_num=count_index_num (in_file_name);
 if(index==0)return 1;
 if(get_index_names(label,in_file_name)) return 1;
 
 
  //  sprintf(plot_cmd,"plot '%s' index 0 with linespoints ls 1 title '%s', \"\" index 1 with linespoints ls 2 title '%s', \"\" index 2  with linespoints ls 3 title '%s', \"\" index 3 with linespoints ls 4 title '%s'",in_file_name,label1,label2,label3,label4);
    sprintf(plot_cmd,"plot '%s' index 0 with linespoints ls 1 title '%s'", in_file_name,label[1]);
    for (i=1; i < index_num; i++){
    	sprintf(plot_cmd,"%s , \"\" index %d with linespoints ls %d title '%s'  ",plot_cmd,i,i+1,label[i+1]);	
    }	
   	i=0;
    while (commandsForGnuplot[i]!=NULL)
    {
    	fprintf(pipe, "%s \n", commandsForGnuplot[i]); //Send commands to gnuplot one by one.
    	i++;
    }

    //set ylable title
    fprintf(pipe, "set ylabel \"%s\"\n   ",y_lable);
    fprintf(pipe, "set xlabel \"%s\"\n   ",x_lable);
    fprintf(pipe, "set key %s \n",key_pos);
    fprintf(pipe, "%s \n",plot_cmd);
	
	fflush(pipe);    
	fclose(pipe);
	rename("temp.eps",out_file_name);
    return 0;
}


typedef enum { false = 0, true } bool;

bool isEmptyLine(const char *s) {
  static const char *emptyline_detector = " \t\n";

  return strspn(s, emptyline_detector) == strlen(s);
}


int count_index_num (char * file_name){
	FILE * in;
	char line [1000];
	int index =1;
	bool last_result = false;
	in= fopen (file_name,"r");
	if(in==NULL){printf ("Error: failed to open %s file in read mode\n",file_name); return 0;}
	while (fgets ( line, sizeof line, in )!=NULL){
		
		if ( isEmptyLine(line) == false && last_result == true ) index++;
		last_result = isEmptyLine(line);
		//printf("%d\t\t %s\n",index,line);
		
	}
	fclose(in);
	return index;
}

char out[100];
char * check_format(char * ch){
	
	int i =0;
	while((*ch)!= 0){
		if((*ch)=='_') {out[i]= '\\'; i++;}	
		out[i] = *ch;
		ch++;
		i++;
	}
	out[i] = 0;
	return out;
}


 int get_index_names (char label[MAX_INDEX][30] ,char * file_name){
	FILE * in;
	char line [1000];
	char * ch;
	in= fopen (file_name,"r");
	if(in==NULL){printf ("Error: failed to open %s file in read mode\n",file_name); return 1;}
	int index =1;
	while (fgets ( line, sizeof line, in )!=NULL){
			if(strncmp(line,"#name:",6)==0) {
				ch=strtok(line,":");
				ch=strtok(NULL,"\n");
				ch = check_format(ch);
				//strcpy(label[index],ch);
				sprintf(label[index],"%s",ch);
				index++;
				
				
			}
	}
	 
	 fclose(in);
	 return 0;

	 
}
