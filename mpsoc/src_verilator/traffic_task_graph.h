#ifndef TRAFFIC_TASK_GRAPH_H
#define TRAFFIC_TASK_GRAPH_H



#define SET_AUTO -1



#define MAX_LINE_LEN 1000
#define DEAFULT_INIT_WEIGHT		1
#define DEAFULT_MIN_PCK_SIZE	8 // must be larger than 1



typedef struct INDEX_INFO{
	unsigned int active_index;
	unsigned int total_index;
} index_t;



typedef struct TRAFFIC_TASK {
	char enable;
    unsigned int src;
    unsigned int dst; // ID of the destination endpoint (PE)
    unsigned int bytes;			
    unsigned int initial_weight;
    unsigned int min_pck_size;		//in flit
    unsigned int max_pck_size;		//in flit
   
    unsigned int avg_pck_size;		//in flit
    unsigned int estimated_total_pck_num;
    unsigned int burst_size;
    float injection_rate;
    unsigned int jnjct_var;
   
    unsigned int pck_sent;
    unsigned int byte_sent;
    unsigned int burst_sent;
} task_t;



typedef struct endpt {
     task_t task;
    struct endpt * next;
} endpt_t;



unsigned int total_active_routers=0;
unsigned int task_graph_total_pck_num=0;
unsigned int task_graph_min_pck_size=999999;
unsigned int task_graph_max_pck_size=0;

endpt_t * task_graph_data[NE];
index_t task_graph_abstract[NE];




void push(endpt_t ** head,  task_t task) {
    endpt_t * new_endpt;
    new_endpt =  (endpt_t *) malloc(sizeof(endpt_t));
    if( new_endpt == NULL){
       	printf("ERROR: cannot allocate memory in push function\n");
   	    exit(1);
   	}
    new_endpt->task=task;
    new_endpt->next = *head;
    *head = new_endpt;
}

int pop(endpt_t ** head) {
   // int retval = -1;
    endpt_t * next_endpt = NULL;

    if (*head == NULL) {
        return -1;
    }

    next_endpt = (*head)->next;
    //retval = (*head)->val;
    free(*head);
    *head = next_endpt;
	return 1;
    //return retval;
}


int remove_by_index(endpt_t ** head, int n) {
    int i = 0;
   // int retval = -1;
    endpt_t * current = *head;
    endpt_t * temp_endpt = NULL;

    if (n == 0) {
        return pop(head);
    }

    for (i = 0; i < n-1; i++) {
        if (current->next == NULL) {
            return -1;
        }
        current = current->next;
    }

    temp_endpt = current->next;
    //retval = temp_endpt->val;
    current->next = temp_endpt->next;
    free(temp_endpt);
    return 1;

}


int update_by_index(endpt_t * head,int loc,  task_t  task) {
    endpt_t * current = head;
	int i;
	for (i=0;i<loc && current != NULL;i++){
		current = current->next;
		
	}
	if(current == NULL) return 0;
	current->task=task;
    return 1;

}


int read(endpt_t * head, int loc,  task_t  * task ) {
    endpt_t * current = head;
	int i;
	for (i=0;i<loc && current != NULL;i++){
		current = current->next;
		
	}
	if(current == NULL) return 0;
	*task =  current->task;
    return 1;
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


int extract_traffic_data ( char * str,  task_t*  st)
{
	
	unsigned int src;
	unsigned int dst; // ID of the destination endpt (PE)
	unsigned int bytes;		
	unsigned int initial_weight;	
	unsigned int min_pck_size;		//in flit
	unsigned int max_pck_size;		//in flit
	unsigned int burst;
	float inject_rate;
	int jnjct_var;
	
	int n;
	n=sscanf( str, "%u,%u,%u,%u,%u,%u,%u,%f,%u",&src, &dst, &bytes, &initial_weight, &min_pck_size, &max_pck_size,&burst,&inject_rate,&jnjct_var);
	
	if (n<3) return 0;

	st->src	= src;
	st->dst=dst;
	st->bytes=bytes;	
	st->initial_weight=(n>3 && initial_weight >0 )? initial_weight :DEAFULT_INIT_WEIGHT;
	st->min_pck_size=  (n>4 && min_pck_size>1 )? min_pck_size : DEAFULT_MIN_PCK_SIZE;
	st->max_pck_size=  (n>5 && max_pck_size >= st->min_pck_size )? max_pck_size : st->min_pck_size;	
	st->burst_size =   (n>6 )? burst : SET_AUTO;
	st->injection_rate= (n>7 )? inject_rate : SET_AUTO;
	st->jnjct_var= (n>8 )?  jnjct_var : 20;
	//
	st->avg_pck_size=  (st->min_pck_size + st->max_pck_size)/2;
	st->estimated_total_pck_num = (bytes*8) /(st->avg_pck_size*Fpay);
	if(st->estimated_total_pck_num==0) st->estimated_total_pck_num= 1; 
	task_graph_total_pck_num=task_graph_total_pck_num+st->estimated_total_pck_num;
	if(task_graph_min_pck_size > st->min_pck_size ) task_graph_min_pck_size=  st->min_pck_size;
	if(task_graph_max_pck_size < st->max_pck_size ) task_graph_max_pck_size=  st->max_pck_size;

	st->pck_sent=0;
	st->byte_sent=0;
    st->burst_sent=0;
	
   return 1;
}

int calcualte_traffic_parameters(endpt_t * head[NE],index_t (* info)){
	int i,j;
	 task_t  task;
	
	unsigned int max_bytes=0,accum[NE];
	unsigned int min_total[NE];
	
	//find the maximum bytes that an IP sends
	for(i=0;i<NE;i++){

		info[i].active_index=-1;
		j=0;
		accum[i]=0;
		if(head[i]!=NULL){
			info[i].active_index=0;

			min_total[i] = -1;
			while(	read(head[i],j,&task)==1){
				accum[i]=accum[i]+task.bytes;
				if(  min_total[i] > task.estimated_total_pck_num) min_total[i] = task.estimated_total_pck_num;
				j++;
			}
			info[i].total_index=j;
			if(max_bytes < accum[i]) 	max_bytes=accum[i];
		}

	}
	
	
	for(i=0;i<NE;i++){

		j=0;
		if(head[i]!=NULL){
			while(	read(head[i],j,&task)==1){
				if(task.burst_size ==SET_AUTO) task.burst_size = task.estimated_total_pck_num/min_total[i];
				if(task.injection_rate ==SET_AUTO) task.injection_rate= (float)(200*accum[i] / (3*max_bytes));

				update_by_index(head[i],j,task);
				j++;
			}
		}
	}
	return 0;
}	





void load_traffic_file(char * file, endpt_t * head[NE], index_t (* info)){
	FILE * in;
	char * line = NULL;
   
     task_t st;
    char l[MAX_LINE_LEN]; 
    in = fopen(file,"rb");
    int n,i;
     
    if(in == NULL){
    	fprintf(stderr,"ERROR: cannot open %s file in read mode!\n",file);
    	exit(1);
	}

    for(i=0;i<NE;i++){
    			head[i]=NULL;
    }

		
	while (fgets(l,MAX_LINE_LEN, in) != NULL)  {
		line = removewhiteSpacses(l);
        if(line[0] != '%' && line[0] != 0 ) {
			n=extract_traffic_data(line, &st);
			if(n==0 || st.dst >=NE) continue;// the  destination address must be smaller than NC
		    push(&head[st.src],st);
		}	   
	}
	fclose(in);
	calcualte_traffic_parameters(head,info);
	for(i=0;i<NE;i++){
		if(info[i].total_index !=0) total_active_routers++;
	}
}




#endif
