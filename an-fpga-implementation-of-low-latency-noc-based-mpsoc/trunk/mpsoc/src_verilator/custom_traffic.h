#ifndef CUSTOM_TRAFFIC_h
#define CUSTOM_TRAFFIC_h


#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "parameter.h"

#define  NC		(NX*NY)
#define DISABLE -1
#define MAX_FILE_LINE  50000
#define	MAX_LINE_LEN	5000


struct TRAFFIC_PATTERN {
    unsigned int src;			// ID of the source node (PE)
    unsigned int dst;			// ID of the destination node (PE)
    float pir;			//1~100 %
    unsigned int avg_pck_size;		//in flit
    unsigned int min_pck_size;		//in flit
    unsigned int max_pck_size;		//in flit
    unsigned int total_pck_num;		
    unsigned int initial_weight;

    unsigned int packet_sent;
}TrafficTable[MAX_FILE_LINE];

int active_location [NC+1];


int global_index=0;
unsigned int total_pck_num_custom=0;



void addTO(
    struct TRAFFIC_PATTERN  st
){

	TrafficTable[global_index++]=st;
	TrafficTable[global_index].src=-1;
	total_pck_num_custom+=st.total_pck_num;
}



struct TRAFFIC_PATTERN extract_traffic_data ( char * str, int * n)
{
   struct TRAFFIC_PATTERN  st;
   *n=sscanf( str, "%u,%u,%f,%u,%u,%u,%u,%u",
		&st.src,
		&st.dst,
		&st.pir,
		&st.avg_pck_size,
		&st.min_pck_size,
		&st.max_pck_size,
		&st.total_pck_num,
		&st.initial_weight);
   return st;
}


char* removewhiteSpacses (char * oldstr ) {
	char *newstr = (char*) malloc(strlen(oldstr)+1);
	char *np = newstr, *op = oldstr;
	do {
	   if (*op != ' ' && *op != '\t')
		   *np++ = *op;
	} while (*op++);
	return newstr;
}


int compare ( const void *pa, const void *pb )
{
    const int *a = (const int *) pa;
    const int *b = (const int *) pb;
    return a[0] - b[0];
}


int load_traffic_file(char * file){
	FILE * in;
	char * line = NULL;
    size_t len = 0;
    ssize_t read;
   
    struct TRAFFIC_PATTERN file_data[MAX_FILE_LINE];
    struct TRAFFIC_PATTERN  sorted[MAX_FILE_LINE];
    char l[MAX_LINE_LEN]; 
    
    struct TRAFFIC_PATTERN  st;
    int index=0,i=0,n=0;
    
    for (i = 0; i < NC; i++) {
		active_location[i] =  DISABLE ;
	}
    
    in = fopen(file,"rb");
    
    
    
    if(in == NULL)
	{
    	printf("Error: cannot open %s file in read mode!\n",file);
	    exit(1);
	}
	
	
	
	while (fgets(l,MAX_LINE_LEN, in) != NULL)  {
	
	
	//while ((read = getline(&line, &len, in)) != -1) {
	   line = removewhiteSpacses(l);
       //printf("%s", line);
       
       if(line[0] != '%' && line[0] != 0 ) {
    	   st=extract_traffic_data(line,&n);
    	   if(st.dst >=NC) continue;// the  destination address must be smaller than NC
		   file_data[index]= st;
		   index++;
		   
		   if(index>MAX_FILE_LINE){
			perror("error: MAX_FILE_LINE is smaller than the file line number\n");   
			}	   
			//addTO(data);
		}
		
    }
   
   // qsort(file_data, index, sizeof file_data[0], compare);
  
    //sort
    int j,m=0;
    for (i=0;i<NC;i++){
		  for (j=0;j<index;j++){
			if(file_data[j].src==i){
				sorted[m]=file_data[j];
				m++;
			}
		}
	}
   
    j=-1;
    int src;
	for (i=0; i< index ; i++){ // the  source address must be smaller than NC
			src= sorted[i].src;
			if(src >= NC) continue;
			addTO(sorted[i]);
			
			if(j!=src){
				  active_location[src]=i;
				  j=src;
				 
			}
	}
   

    
    
    fclose(in);
   
    
    return index;
    
}

#endif


