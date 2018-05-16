#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>




#include <ctype.h>
#include <stdint.h>

#include <inttypes.h>


#include <verilated.h>          // Defines common routines
#include "Vrouter.h"               // From Verilating "router.v"
#include "Vnoc.h"
#include "Vtraffic.h"
#include "parameter.h"



#ifndef NC 
#define  NC		(NX*NY)
#endif
#define  RATIO_INIT		2

#define SYNTHETIC 0
#define CUSTOM 1 
#define DISABLE -1

#include "traffic_task_graph.h"




//Vrouter *router;
Vrouter			*router[NC];                     // Instantiation of module
Vnoc		 	*noc;
Vtraffic		*traffic[NC];


char * TRAFFIC;
unsigned char FIXED_SRC_DST_PAIR;
unsigned char  Xw=0,Yw=0;
unsigned long int main_time = 0;     // Current simulation time
unsigned int saved_time = 0; 
unsigned int total_pck_num=0;
unsigned int sum_clk_h2h,sum_clk_h2t;
double 		 sum_clk_per_hop;
const int  CC=(C==0)? 1 : C;

unsigned int total_pck_num_per_class[CC]={0};
unsigned int sum_clk_h2h_per_class[CC]={0};
unsigned int sum_clk_h2t_per_class[CC]={0};
double 		 sum_clk_per_hop_per_class[CC]={0};

unsigned int rsvd_core_total_pck_num[NC]= {0};
unsigned int rsvd_core_worst_delay[NC] =  {0};
unsigned int sent_core_total_pck_num[NC]= {0};
unsigned int sent_core_worst_delay[NC] =  {0};
unsigned int random_var[NC] = {100};

unsigned int clk_counter;
unsigned int count_en;
unsigned int total_router;

int reset,clk;

char all_done=0;

unsigned int flit_counter =0;

int ratio=RATIO_INIT;
double first_avg_latency_flit,current_avg_latency_flit;

double sc_time_stamp ();
int pow2( int );





#if (STND_DEV_EN)
	#include <math.h>
	double 	     sum_clk_pow2=0;
	double 	     sum_clk_pow2_per_class[C]={0};
	double standard_dev( double , unsigned int, double);
#endif

void update_noc_statistic (
	int
);


void pck_dst_gen (
    unsigned int,
	unsigned int,
	unsigned int,
	unsigned int*,
	unsigned int*
);

unsigned char pck_class_in_gen(
	 unsigned int

);




void print_statistic (char *);
void print_parameter();
void reset_all_register();
unsigned int rnd_between (unsigned int, unsigned int );







int TRAFFIC_TYPE=SYNTHETIC;
int PACKET_SIZE=5;
int MIN_PACKET_SIZE=5;
int MAX_PACKET_SIZE=5;
int MAX_PCK_NUM;
int MAX_SIM_CLKs;

int C0_p=100, C1_p=0, C2_p=0, C3_p=0;


int  HOTSPOT_NUM;
typedef struct HOTSPOT_NODE {
	int  ip_num;
	char send_enable;
	int  percentage; // x10	
} hotspot_st;

hotspot_st * hotspots;





void  usage(){
	printf(" ./simulator -f [Traffic Pattern file]\n\nor\n");


	printf(" ./simulator -t [Traffic Pattern]  -s  [MIN_PCK_SIZE] -m [MAX_PCK_SIZE] -n  [MAX_PCK_NUM]  c	[MAX SIM CLKs]   -i [INJECTION RATIO] -p [class traffic ratios (%%)]  -h[HOTSPOT info] \n");
	printf("      Traffic Pattern: \"HOTSPOT\" \"RANDOM\" \"TORNADO\" \"BIT_REVERSE\"  \"BIT_COMPLEMENT\"  \"TRANSPOSE1\"   \"TRANSPOSE2\"\n");
	printf("      MIN_PCK_SIZE: Minimum packet size in flit. The injected packet size is randomly selected between minimum and maximum packet size\n ");
	printf("      MAX_PCK_SIZE: Maximum packet size in flit. The injected packet size is randomly selected between minimum and maximum packet size\n ");

	printf("      MAX_PCK_NUM: total number of sent packets. Simulation will stop when total of sent packet by all nodes reach this number\n");
	printf("      MAX_SIM_CLKs: simulation clock limit. Simulation will stop when simulation clock number reach this value \n");
	printf("      INJECTION_RATIO: packet injection ratio");
	printf("      class traffic ratios %%: The percentage of traffic injected for each class. represented in string whit each class ratio is separated by comma. \"n0,n1,n2..\" \n");
	printf("      hotspot traffic info: represented in a string with following format:  \"HOTSPOT PERCENTAGE,HOTSPOT NUM,HOTSPOT CORE 1,HOTSPOT CORE 2,HOTSPOT CORE 3,HOTSPOT CORE 4,HOTSPOT CORE 5, ENABLE HOTSPOT CORES SEND \"   \n");
}


int parse_string ( char * str, int * array)
{
    int i=0; 
    char *pt;
    pt = strtok (str,",");
    while (pt != NULL) {
        int a = atoi(pt);
        array[i]=a;
        i++;
        pt = strtok (NULL, ",");
    }
   return i; 
}

void update_hotspot(char * str){
	 int i;
	 int array[1000];
	 int p;
	 int acuum=0;
	 hotspot_st * new_node;
	 p= parse_string (str, array);
	 if (p<4){
			printf("Error in hotspot traffic parameters \n");
			exit(1);
	 }
	 HOTSPOT_NUM=array[0];
	 if (p<1+HOTSPOT_NUM*3){
			printf("Error in hotspot traffic parameters \n");
			exit(1);
	 }
	 new_node =  (hotspot_st *) malloc( HOTSPOT_NUM * sizeof(hotspot_st));
	 if( new_node == NULL){
       	printf("Error: cannot allocate memory for hotspot traffic\n");
   	    exit(1);
   	 }
	 for (i=1;i<3*HOTSPOT_NUM; i+=3){
		new_node[i/3]. ip_num = array[i];
	    new_node[i/3]. send_enable=array[i+1];
	    new_node[i/3]. percentage =  acuum + array[i+2];
	    acuum= new_node[i/3]. percentage;									
		 
	 }	 
	 if(acuum> 1000){
		 	printf("Warning: The hotspot traffic summation %f exceed than 100 percent.  \n", (float) acuum /10);
   	   
	 } 
	
	 hotspots=new_node;
}
	
			 
			 
			 
		


void processArgs (int argc, char **argv )
{
   char c;
   int p;
   int array[10];
   float f;

   /* don't want getopt to moan - I can do that just fine thanks! */
   opterr = 0;
   if (argc < 2)  usage();	
   while ((c = getopt (argc, argv, "t:s:m:n:c:i:p:h:f:")) != -1)
      {
	 switch (c)
	    {
	 	case 'f':
	 		TRAFFIC_TYPE=CUSTOM;
	 		TRAFFIC=(char *) "CUSTOM from file";
	 		load_traffic_file(optarg,task_graph_data,task_graph_abstract);
	 		MAX_PCK_NUM=task_graph_total_pck_num;
	 		break;
	    case 't':  
			TRAFFIC=optarg;
			total_active_routers=-1;
			break;
		case 's':
			MIN_PACKET_SIZE=atoi(optarg);
			break;
		case 'm':
			MAX_PACKET_SIZE=atoi(optarg);
			break;
		case 'n':
			 MAX_PCK_NUM=atoi(optarg);
			 break;
		case 'c':
			 MAX_SIM_CLKs=atoi(optarg);
			 break;
		case 'i':
			 f=atof(optarg);
			 f*=(MAX_RATIO/100);
			 ratio= (int) f;
			 break;
		case 'p':
			p= parse_string (optarg, array);
		    C0_p=array[0];
		    C1_p=array[1];
		    C2_p=array[2];
		    C3_p=array[3];
			break; 
		
		case 'h':
		
			update_hotspot(optarg);

			 
			 break; 
		
			 
			 
	    case '?':
	       if (isprint (optopt))
		  fprintf (stderr, "Unknown option `-%c'.\n", optopt);
	       else
		  fprintf (stderr,
			   "Unknown option character `\\x%x'.\n",
			   optopt);
	    default:
	       usage();
	       exit(1);
	    }
      }
   PACKET_SIZE=(MIN_PACKET_SIZE+MAX_PACKET_SIZE)/2;// average packet size
}


int main(int argc, char** argv) {
	char change_injection_ratio=0,inject_done;
	int i,j,x,y;//,report_delay_counter=0;
	char file_name[100];
	char deafult_out[] = {"result"};
	char * out_file_name;
	unsigned int dest_x, dest_y;
	int flit_out_all_size = sizeof(router[0]->flit_out_all)/sizeof(router[0]->flit_out_all[0]);
	while((0x1<<Xw) < NX)Xw++; //log2
	while((0x1<<Yw) < NY)Yw++;
	
	
	Verilated::commandArgs(argc, argv);   // Remember args
	
	for(i=0;i<NC;i++)	router[i] 	= new Vrouter;             // Create instance
	noc								= new Vnoc;
	for(i=0;i<NC;i++)	traffic[i]  = new Vtraffic;
	
	processArgs ( argc,  argv );
	
	
	FIXED_SRC_DST_PAIR = strcmp (TRAFFIC,"RANDOM") &  strcmp(TRAFFIC,"HOTSPOT") & strcmp(TRAFFIC,"random") & strcmp(TRAFFIC,"hot spot") & strcmp(TRAFFIC,"CUSTOM from file");
	

	/********************
	*	initialize input
	*********************/

	reset=1;
	reset_all_register();
	noc->start_i=0;
 

	for(x=0;x<NX;x++)for(y=0;y<NY;y++){

					i=(y*NX)+x;
					random_var[i] = 100;
					router[i]->current_x		= x;
					router[i]->current_y		= y;
					traffic[i]->current_x		= x;
					traffic[i]->current_y		= y;
					traffic[i]->start=0;
					traffic[i]->pck_class_in=  pck_class_in_gen( i);
					pck_dst_gen ( x,y,i, &dest_x, &dest_y);
					traffic[i]->dest_x= dest_x;
					traffic[i]->dest_y=dest_y;
					traffic[i]->stop=0;
					if(TRAFFIC_TYPE==SYNTHETIC){
						traffic[i]->pck_size_in=PACKET_SIZE;
						traffic[i]->avg_pck_size_in=PACKET_SIZE;
						traffic[i]->ratio=ratio;							
						traffic[i]->init_weight=1;
					}


	}
	//traffic[35]->init_weight=10;

 

	main_time=0;
	print_parameter();
	if(strcmp(TRAFFIC,"CUSTOM from file")) printf("\n\n\n Flit injection ratio per router is =%f \n",(float)ratio*100/MAX_RATIO);
	//printf("\n\n\n delay= %u clk",router->delay);
	while (!Verilated::gotFinish()) {
	   
		if (main_time-saved_time >= 10 ) {
			reset = 0;
		}

		if(main_time == saved_time+21){ count_en=1; noc->start_i=1;}//for(i=0;i<NC;i++) traffic[i]->start=1;}
		if(main_time == saved_time+26) noc->start_i=0;// for(i=0;i<NC;i++) traffic[i]->start=0;
		  
			if ((main_time % 4) == 0) {
			clk = 1;       // Toggle clock
			if(count_en) clk_counter++;
			inject_done= ((total_pck_num >= MAX_PCK_NUM) || (clk_counter>= MAX_SIM_CLKs) || total_active_routers == 0);
			//if(inject_done) printf("clk_counter=========%d\n",clk_counter);
			for(y=0;y<NY;y++)for(x=0;x<NX;x++)
			{
				i=(y*NX)+x;
				// a packet has been received
				if(traffic[i]->update & ~reset){
					update_noc_statistic (i) ;
					
				}
				// the header flit has been sent out
				if(traffic[i]->hdr_flit_sent ){
					traffic[i]->pck_class_in=  pck_class_in_gen( i);
					sent_core_total_pck_num[i]++;
					if(!FIXED_SRC_DST_PAIR){
						pck_dst_gen ( x,y,i, &dest_x, &dest_y);
						traffic[i]->dest_x= dest_x;
						traffic[i]->dest_y=dest_y;
					}
				}

				if(traffic[i]->flit_out_wr==1) flit_counter++;

			}//for
			if(inject_done) {
				for(x=0;x<NX;x++)for(y=0;y<NY;y++) if(traffic[(y*NX)+x]->pck_number>0) total_router   	= 	total_router +1;

				printf(" simulation clock cycles:%d\n",clk_counter);
				printf(" total received flits:%d\n",flit_counter);
				print_statistic(out_file_name);
				change_injection_ratio = 1;
				for(i=0;i<NC;i++) {
					router[i]->final();
					traffic[i]->final();
				}               	
				noc->final();
				return 0;
			}



		}//if
		else
		{

			clk = 0;
			noc->ni_flit_in_wr =0;
			
			for(x=0;x<NX;x++)for(y=0;y<NY;y++){
				i=(y*NX)+x;


				router[i]->flit_in_we_all	= noc->router_flit_out_we_all[i];
				router[i]->credit_in_all	= noc->router_credit_out_all[i];
				router[i]->congestion_in_all	= noc->router_congestion_out_all[i];
				//router[i]->iport_weight_in_all	= noc->router_iport_weight_out_all[i];

				for(j=0;j<flit_out_all_size;j++)router[i]->flit_in_all[j] 	= noc->router_flit_out_all[i][j];


				noc->router_flit_in_we_all[i]	=	router[i]->flit_out_we_all ;
				noc->router_credit_in_all[i]	=	router[i]->credit_out_all;
				noc->router_congestion_in_all[i]=	router[i]->congestion_out_all;
				//noc->router_iport_weight_in_all[i]=	router[i]->iport_weight_out_all;

				for(j=0;j<flit_out_all_size;j++) noc->router_flit_in_all[i][j]	= router[i]->flit_out_all[j] ;

				traffic[i]->flit_in  = noc->ni_flit_out [i];
				traffic[i]->credit_in= noc->ni_credit_out[i];
			

				noc->ni_credit_in[i] = traffic[i]->credit_out;
				noc->ni_flit_in [i]  = traffic[i]->flit_out;

				if(traffic[i]->flit_out_wr) noc->ni_flit_in_wr = noc->ni_flit_in_wr | ((vluint64_t)1<<i);

				traffic[i]->flit_in_wr= ((noc->ni_flit_out_wr >> i) & 0x01);

			
			}//for
		

		}//else
		//if(main_time > 20 && main_time < 30 ) traffic->start=1; else traffic->start=0;
		//if(main_time == saved_time+25) router[0]->flit_in_we_all=0;
		//if((main_time % 250)==0) printf("router->all_done =%u\n",router->all_done);
		
		
		noc-> clk = clk; 
		noc-> reset = reset;

		 
		for(i=0;i<NC;i++)	{
			traffic[i]->start=  ((noc->start_o >>i)&  0x01);
			traffic[i]->reset= reset;
			traffic[i]->clk	= clk;
			router[i]->reset= reset;
			router[i]->clk= clk ;

		}

		
		noc->eval(); 
		

		for(i=0;i<NC;i++) {
				router[i]->eval();
				traffic[i]->eval();

		}




		//router[0]->eval();            // Evaluate model
		//printf("clk=%x\n",router->clk );

		main_time++;  
		//getchar();   

		
	}
	for(i=0;i<NC;i++) {
		router[i]->final();
		traffic[i]->final();
	}               // Done simulating
	noc->final(); 

}




/*************
 * sc_time_stamp 
 * 
 * **********/



double sc_time_stamp () {       // Called by $time in Verilog
	return main_time;
}

int pow2( int num){
	int pw;
	pw= (0x1 << num);
	return pw;
}



/**********************************
 *
 * 	update_noc_statistic
 *
 *
 *********************************/



void update_noc_statistic (
		
		int 			core_num
)
{

	unsigned int   	clk_num_h2h =traffic[core_num]->time_stamp_h2h;
	unsigned int    clk_num_h2t =traffic[core_num]->time_stamp_h2t;
    unsigned int    distance=traffic[core_num]->distance;
    unsigned int  	class_num=traffic[core_num]->pck_class_out;
    unsigned int    src_x=traffic[core_num]->src_x;
    unsigned int    src_y=traffic[core_num]->src_y;

    unsigned int    src = (src_y*NX)+src_x;

						


	total_pck_num+=1;
	
	if((total_pck_num & 0Xffff )==0 ) printf(" packet sent total=%d\n",total_pck_num);
	
	
	sum_clk_h2h+=clk_num_h2h;
	sum_clk_h2t+=clk_num_h2t;
#if (STND_DEV_EN)
	sum_clk_pow2+=(double)clk_num_h2h * (double) clk_num_h2h;
	sum_clk_pow2_per_class[class_num]+=(double)clk_num_h2h * (double) clk_num_h2h;
#endif
			        		
	sum_clk_per_hop+= ((double)clk_num_h2h/(double)distance);
	total_pck_num_per_class[class_num]+=1;
	sum_clk_h2h_per_class[class_num]+=clk_num_h2h ;
	sum_clk_h2t_per_class[class_num]+=clk_num_h2t ;
	sum_clk_per_hop_per_class[class_num]+= ((double)clk_num_h2h/(double)distance);

	rsvd_core_total_pck_num[core_num]=rsvd_core_total_pck_num[core_num]+1;

	if (rsvd_core_worst_delay[core_num] < clk_num_h2t) rsvd_core_worst_delay[core_num] = (strcmp (AVG_LATENCY_METRIC,"HEAD_2_TAIL")==0)?  clk_num_h2t :  clk_num_h2h;
    if (sent_core_worst_delay[src] < clk_num_h2t) sent_core_worst_delay[src] = (strcmp (AVG_LATENCY_METRIC,"HEAD_2_TAIL")==0)?  clk_num_h2t :  clk_num_h2h;


}

/*************************
 *
 *		update
 *
 *
 ************************/





void print_statistic (char * out_file_name){
	double avg_latency_per_hop,  avg_latency_flit, avg_latency_pck, avg_throughput,min_avg_latency_per_class;
	int i;
#if (STND_DEV_EN)
	double	std_dev;
#endif
					char file_name[100];
					avg_throughput= ((double)(flit_counter*100)/total_router )/clk_counter;
					printf(" Total active routers: %d \n",total_router);
					printf(" Avg throughput is: %f (flits/clk/node %%)\n",    avg_throughput);
	                avg_latency_flit   = (double)sum_clk_h2h/total_pck_num;
	                avg_latency_pck	   = (double)sum_clk_h2t/total_pck_num;
	                if(ratio==RATIO_INIT) first_avg_latency_flit=avg_latency_flit;
#if (STND_DEV_EN)
	                std_dev= standard_dev( sum_clk_pow2,total_pck_num, avg_latency_flit);
	               // sprintf(file_name,"%s_std.txt",out_file_name);
	                //update_file( file_name,avg_throughput,std_dev);

#endif
	                avg_latency_per_hop    = (double)sum_clk_per_hop/total_pck_num;
	                printf	 ("\nall : \n");
	              //  sprintf(file_name,"%s_all.txt",out_file_name);
	                //update_file(file_name ,ratio,avg_latency );
if(strcmp (AVG_LATENCY_METRIC,"HEAD_2_TAIL")==0){
		  	printf(" Total number of packet = %d \n average latency per hop = %f \n average latency = %f\n",total_pck_num,avg_latency_per_hop,avg_latency_pck);
	              // update_file(file_name ,avg_throughput,avg_latency_pck);
	               
}else{
			 printf(" Total number of packet = %d \n average latency per hop = %f \n average latency = %f\n",total_pck_num,avg_latency_per_hop,avg_latency_flit);
	             //   update_file(file_name ,avg_throughput,avg_latency_flit);
	              
}
	                //fwrite(fp,"%d,%f,%f,%f,",total_pck_num,avg_latency_per_hop,avg_latency,max_latency_per_hop);
	                min_avg_latency_per_class=1000000;
	                for(i=0;i<C;i++){
	                	avg_throughput		 = (total_pck_num_per_class[i]>0)? ((double)(total_pck_num_per_class[i]*PACKET_SIZE*100)/total_router )/clk_counter:0;
						avg_latency_flit 	 = (total_pck_num_per_class[i]>0)? (double)sum_clk_h2h_per_class[i]/total_pck_num_per_class[i]:0;
						avg_latency_pck	   	 = (total_pck_num_per_class[i]>0)? (double)sum_clk_h2t_per_class[i]/total_pck_num_per_class[i]:0;
						avg_latency_per_hop  = (total_pck_num_per_class[i]>0)? (double)sum_clk_per_hop_per_class[i]/total_pck_num_per_class[i]:0;
if(strcmp (AVG_LATENCY_METRIC,"HEAD_2_TAIL")==0){
						 printf	 ("\nclass : %d  \n",i);
	                    printf	(" Total number of packet  = %d \n avg_throughput = %f \n average latency per hop = %f \n average latency = %f\n",total_pck_num_per_class[i],avg_throughput,avg_latency_per_hop,avg_latency_pck);
   	                    //sprintf(file_name,"%s_c%u.txt",out_file_name,i);
   	                   // update_file( file_name,avg_throughput,avg_latency_pck );
}else{

printf	 ("\nclass : %d  \n",i);
	                    printf	(" Total number of packet  = %d \n avg_throughput = %f \n average latency per hop = %f \n average latency = %f\n",total_pck_num_per_class[i],avg_throughput,avg_latency_per_hop,avg_latency_flit);
	                   // sprintf(file_name,"%s_c%u.txt",out_file_name,i);
	                   // update_file( file_name,avg_throughput,avg_latency_flit );


}
	                    if(min_avg_latency_per_class > avg_latency_flit) min_avg_latency_per_class=avg_latency_flit;

#if (STND_DEV_EN)
	                    std_dev= (total_pck_num_per_class[i]>0)?  standard_dev( sum_clk_pow2_per_class[i],total_pck_num_per_class[i], avg_latency_flit):0;
	                   // sprintf(file_name,"%s_std%u.txt",out_file_name,i);
	                   // update_file( file_name,avg_throughput,std_dev);

#endif


	                 }//for
	                current_avg_latency_flit=min_avg_latency_per_class;

	for (i=0;i<NC;i++) {
		printf	 ("\n\nCore %d\n",i);
			printf	 ("\n\ttotal number of received packets: %u\n",rsvd_core_total_pck_num[i]);
			printf	 ("\n\tworst-case-delay of received pckets (clks): %u\n",rsvd_core_worst_delay[i] );
			printf	 ("\n\ttotal number of sent packets: %u\n",traffic[i]->pck_number);
			printf	 ("\n\tworst-case-delay of sent pckets (clks): %u\n",sent_core_worst_delay[i] );
	}



}

void print_parameter (){

		printf ("Router parameters: \n");
		printf ("\tTopology: %s\n",TOPOLOGY);
		printf ("\tRouting algorithm: %s\n",ROUTE_NAME);
	 	printf ("\tVC_per port: %d\n", V);
		printf ("\tBuffer_width: %d\n", B);
	    printf ("\tRouter num in row: %d \n",NX);
	    printf ("\tRouter num in column: %d \n",NY);
	    printf ("\tNumber of Class: %d\n", C);
	    printf ("\tFlit data width: %d \n", Fpay);
	    printf ("\tVC reallocation mechanism: %s \n",  VC_REALLOCATION_TYPE);
	    printf ("\tVC/sw combination mechanism: %s \n", COMBINATION_TYPE);
	    printf ("\troute-subfunction: %s \n", ROUTE_SUBFUNC );
	    printf ("\tAVC_ATOMIC_EN:%d \n", AVC_ATOMIC_EN);
	    printf ("\tCongestion Index:%d \n",CONGESTION_INDEX);
	    printf ("\tADD_PIPREG_AFTER_CROSSBAR:%d\n",ADD_PIPREG_AFTER_CROSSBAR);
	    printf ("\tSSA_EN enabled:%s \n",SSA_EN);
	    printf ("\tSwitch allocator arbitration type:%s \n",SWA_ARBITER_TYPE);


	printf ("\nSimulation parameters\n");
#if(DEBUG_EN)
    printf ("\tDebuging is enabled\n");
#else
    printf ("\tDebuging is disabled\n");
#endif
	if(strcmp (AVG_LATENCY_METRIC,"HEAD_2_TAIL")==0)printf ("\tOutput is the average latency on sending the packet header until receiving tail\n");
	else printf ("\tOutput is the average latency on sending the packet header until receiving header flit at destination node\n");
	printf ("\tTraffic pattern:%s\n",TRAFFIC);
	if(C>0) printf ("\ttraffic percentage of class 0 is : %d\n", C0_p);
	if(C>1) printf ("\ttraffic percentage of class 1 is : %d\n", C1_p);
	if(C>2) printf ("\ttraffic percentage of class 2 is : %d\n", C2_p);
	if(C>3) printf ("\ttraffic percentage of class 3 is : %d\n", C3_p);
	if(strcmp (TRAFFIC,"HOTSPOT")==0){
		//printf ("\tHot spot percentage: %u\n", HOTSPOT_PERCENTAGE);
	    printf ("\tNumber of hot spot cores: %d\n", HOTSPOT_NUM);

	}
	    //printf ("\tTotal packets sent by one router: %u\n", TOTAL_PKT_PER_ROUTER);
		printf ("\tSimulation timeout =%d\n", MAX_SIM_CLKs);
		printf ("\tSimulation ends on total packet num of =%d\n", MAX_PCK_NUM);
	    printf ("\tPacket size (min,max,average) in flits: (%u,%u,%u)\n",MIN_PACKET_SIZE,MAX_PACKET_SIZE,PACKET_SIZE);
	    printf ("\tPacket injector FIFO width in flit:%u \n",TIMSTMP_FIFO_NUM);
}





/************************
 *
 * 	reset system
 *
 *
 * *******************/

void reset_all_register (void){
	int i;



	 total_router=0;
	 total_pck_num=0;
	 sum_clk_h2h=0;
	 sum_clk_h2t=0;
#if (STND_DEV_EN)
	 sum_clk_pow2=0;
#endif

	 sum_clk_per_hop=0;
	 count_en=0;
	 clk_counter=0;

	 for(i=0;i<C;i++)
	 {
		 total_pck_num_per_class[i]=0;
	     sum_clk_h2h_per_class[i]=0;
	     sum_clk_h2t_per_class[i]=0;
	 	 sum_clk_per_hop_per_class[i]=0;
#if (STND_DEV_EN)
	 	 sum_clk_pow2_per_class[i]=0;
#endif

	 }  //for
	 flit_counter=0;
}


 

/***********************
 *
 * 	standard_dev
 *
 * ******************/

#if (STND_DEV_EN)


double standard_dev( double sum_pow2, unsigned int  total_num, double average){
	double std_dev;

	std_dev = sum_pow2/(double)total_num;
	std_dev -= (average*average);
	std_dev = sqrt(std_dev);

	return std_dev;

}

#endif



/**********************
 *
 *	pck_class_in_gen
 *
 * *****************/

unsigned char  pck_class_in_gen(
	 unsigned int  core_num

) {

	unsigned char pck_class_in;
	unsigned char  rnd=rand()%100;

	pck_class_in= 	  ( rnd <    C0_p		)?  0:
    				  ( rnd <   (C0_p+C1_p)	)?	1:
    				  ( rnd <   (C0_p+C1_p+C2_p))?2:3;



    return pck_class_in;
}


/**********************************

        pck_dst_gen

*********************************/




void pck_dst_gen_2D (
    unsigned int current_x,
	unsigned int current_y,
	unsigned int core_num,
	unsigned int *dest_x,
	unsigned int *dest_y
){


	unsigned int rnd=0,nc=NX*NY;
	unsigned int rnd100=0;
	unsigned int max_percent=100/HOTSPOT_NUM;
	int i;

	traffic[core_num]->pck_size_in=rnd_between(MIN_PACKET_SIZE,MAX_PACKET_SIZE);

	if((strcmp (TRAFFIC,"RANDOM")==0) || (strcmp (TRAFFIC,"random")==0)){

		do{
			rnd=rand()%nc;
		}while (rnd==core_num); // get a random IP core, make sure its not same as sender core

       (*dest_y) = (rnd / NX );
	   (*dest_x) = (rnd % NX );


	}
	
	else if ((strcmp(TRAFFIC,"HOTSPOT")==0) || (strcmp (TRAFFIC,"hot spot")==0)){

		unsigned int rnd1000=0;
		int i;

	
		do{
			rnd=rand()%nc;
		}while (rnd==core_num); // get a random IP core, make sure its not same as sender core

		rnd1000=rand()%1000; // generate a random number between 0 & 1000
		
		for (i=0;i<HOTSPOT_NUM; i++){
			if ( hotspots[i].send_enable == 0 && core_num ==hotspots[i].ip_num){
				rnd = core_num; // turn off the core
				(*dest_y) = (rnd / NX );
				(*dest_x) = (rnd % NX );
				return;
			}
		}
		
		for (i=0;i<HOTSPOT_NUM; i++){
			if (rnd1000 < hotspots[i].percentage && core_num !=hotspots[i].ip_num) {
				rnd = hotspots[i].ip_num;
				(*dest_y) = (rnd / NX );
				(*dest_x) = (rnd % NX );
				return;
			}
			
		}
		(*dest_y) = (rnd / NX );
		(*dest_x) = (rnd % NX );
		return;		


	} else if(( strcmp(TRAFFIC ,"TRANSPOSE1")==0)|| (strcmp (TRAFFIC,"transposed 1")==0)){

		 (*dest_x) = NX-current_y-1;
		 (*dest_y) = NY-current_x-1;



	} else if(( strcmp(TRAFFIC ,"TRANSPOSE2")==0)|| (strcmp (TRAFFIC,"transposed 2")==0)){
		(*dest_x)   = current_y;
		(*dest_y)   = current_x;



	} else if(( strcmp(TRAFFIC ,"BIT_REVERSE")==0)|| (strcmp (TRAFFIC,"bit reverse")==0)){
		unsigned int joint_addr= (current_x<<Xw)+current_y;
		unsigned int reverse_addr=0;
		unsigned int pos=0;
		for(i=0; i<(Xw+Yw); i++){//reverse the address
			 pos= (((Xw+Yw)-1)-i);
			 reverse_addr|= ((joint_addr >> pos) & 0x01) << i;
                   // reverse_addr[i]  = joint_addr [((Xw+Yw)-1)-i];
		}
		(*dest_x)   = reverse_addr>>Yw;
		(*dest_y)   = reverse_addr&(0xFF>> (8-Yw));




	 } else if(( strcmp(TRAFFIC ,"BIT_COMPLEMENT") ==0)|| (strcmp (TRAFFIC,"bit complement")==0)){

		 (*dest_x)    = (~current_x) &(0xFF>> (8-Xw));
		 (*dest_y)    = (~current_y) &(0xFF>> (8-Yw));


	  }  else if(( strcmp(TRAFFIC ,"TORNADO") == 0)|| (strcmp (TRAFFIC,"tornado")==0)){
		//[(x+(k/2-1)) mod k, (y+(k/2-1)) mod k],
		 (*dest_x)    = ((current_x + ((NX/2)-1))%NX);
		 (*dest_y)    = ((current_y + ((NY/2)-1))%NY);


     }  else if( strcmp(TRAFFIC ,"CUSTOM") == 0){
		//[(x+(k/2-1)) mod k, (y+(k/2-1)) mod k],
		if(current_x ==0 && current_y == 0 ){
		 (*dest_x)    =  NX-1;
		 (*dest_y)    =  NY-1;
		}else{// make it invalid
		 (*dest_x)    =  current_x;
		 (*dest_y)    =  current_y;

		}

     }  

	 else {
		 printf ("traffic %s is an unsupported traffic pattern\n",TRAFFIC);
		 (*dest_x)    =  current_x;
		 (*dest_y)    =  current_y;

	 }

}




void pck_dst_gen_1D (
    unsigned int current_x,
	unsigned int core_num,
	unsigned int *dest_x

){


	unsigned int rnd=0,nc=NX;
	unsigned int rnd100=0;
	unsigned int max_percent=100/HOTSPOT_NUM;
	int i;
	
	traffic[core_num]->pck_size_in=rnd_between(MIN_PACKET_SIZE,MAX_PACKET_SIZE);

	if((strcmp (TRAFFIC,"RANDOM")==0) || (strcmp (TRAFFIC,"random")==0)){

		do{
			rnd=rand()%nc;
		}while (rnd==core_num); // get a random IP core, make sure its not same as sender core

	   (*dest_x) = (rnd % NX );
		return;

	}
	
	if ((strcmp(TRAFFIC,"HOTSPOT")==0) || (strcmp (TRAFFIC,"hot spot")==0)){

		unsigned int rnd1000=0;
		int i;

	
		do{
			rnd=rand()%nc;
		}while (rnd==core_num); // get a random IP core, make sure its not same as sender core

		rnd1000=rand()%1000; // generate a random number between 0 & 1000
		
		for (i=0;i<HOTSPOT_NUM; i++){
			//printf("%u==0 && %u == %u\n", hotspots[i].send_enable , core_num , hotspots[i].ip_num);
			if ( hotspots[i].send_enable == 0 && core_num ==hotspots[i].ip_num){
				rnd = core_num; // turn off the core
				(*dest_x) = (rnd % NX );
				return;
			}
		}
		
		for (i=0;i<HOTSPOT_NUM; i++){
			//printf("%u<%u && %u |= %u\n", rnd1000 , hotspots[i].percentage , core_num ,hotspots[i].ip_num);
			if (rnd1000 < hotspots[i].percentage && core_num !=hotspots[i].ip_num) {
				rnd = hotspots[i].ip_num;
				(*dest_x) = (rnd % NX );
				return;
			}
			
		}
	(*dest_x) = (rnd % NX );
		return;

	} 
	
	
	if(( strcmp(TRAFFIC ,"TRANSPOSE1")==0)|| (strcmp (TRAFFIC,"transposed 1")==0)){
	
		 //(*dest_x) = (current_x<4)? NX-current_x-1: current_x;
		  (*dest_x) =  NX-current_x-1;
		// (*dest_y) = NY-current_x-1;
		return;


	} 
	if(( strcmp(TRAFFIC ,"TRANSPOSE2")==0)|| (strcmp (TRAFFIC,"transposed 2")==0)){
		 (*dest_x) = NX-current_x-1;
	//	(*dest_x)   = current_y;
	//	(*dest_y)   = current_x;
		return;

	} 
	
	if(( strcmp(TRAFFIC ,"BIT_REVERSE")==0)|| (strcmp (TRAFFIC,"bit reverse")==0)){

		unsigned int reverse_addr=0;
		unsigned int pos=0;
		for(i=0; i<(Xw); i++){//reverse the address
			 pos= (((Xw)-1)-i);
			 reverse_addr|= ((current_x >> pos) & 0x01) << i;
                   // reverse_addr[i]  = joint_addr [((Xw+Yw)-1)-i];
		}
		(*dest_x)   = reverse_addr;
		return;

	 } 
	 
	 if(( strcmp(TRAFFIC ,"BIT_COMPLEMENT") ==0)|| (strcmp (TRAFFIC,"bit complement")==0)){

		 (*dest_x)    = (~current_x) &(0xFF>> (8-Xw));
		 return;
		 //(*dest_y)    = (~current_y) &(0xFF>> (8-Yw));


	 }  
	 
	 if(( strcmp(TRAFFIC ,"TORNADO") == 0)|| (strcmp (TRAFFIC,"tornado")==0)){
		//[(x+(k/2-1)) mod k, (y+(k/2-1)) mod k],
		 (*dest_x)    = ((current_x + ((NX/2)-1))%NX);
		// (*dest_y)    = ((current_y + ((NY/2)-1))%NY);
		return;

     } 
     
     if( strcmp(TRAFFIC ,"CUSTOM") == 0){
		//[(x+(k/2-1)) mod k, (y+(k/2-1)) mod k],
		if(current_x ==0  ){
		 (*dest_x)    =  NX-1;
		// (*dest_y)    =  NY-1;
		}else{// make it invalid
		 (*dest_x)    =  current_x;
		 //(*dest_y)    =  current_y;

		}
		return;
     }

	
		 printf ("traffic %s is an unsupported traffic pattern\n",TRAFFIC);
		 (*dest_x)    =  current_x;
	

}

unsigned int rnd_between (unsigned int a, unsigned int b){
	unsigned int rnd,diff,min;
	if(a==b) return a;
	diff= (a<b) ?  b-a+1 : a-b+1;
	min= (a<b) ?  a : b;
	rnd = (rand() % diff) +  min;
	return rnd;
}

void update_injct_var(unsigned int src,  unsigned int injct_var){
	//printf("before%u=%u\n",src,random_var[src]);
	random_var[src]= rnd_between(100-injct_var, 100+injct_var);
	//printf("after=%u\n",random_var[src]);
}

unsigned int pck_dst_gen_task_graph ( unsigned int src){
	 task_t  task;
	float f,v;




	int index = task_graph_abstract[src].active_index;

	if(index == DISABLE){
		traffic[src]->ratio=0;
		traffic[src]->stop=1;
		 return src; //disable sending
	}

	if(	read(task_graph_data[src],index,&task)==0){
		traffic[src]->ratio=0;
		traffic[src]->stop=1;
		 return src; //disable sending

	}

	if(sent_core_total_pck_num[src] & 0xFF){//sent 255 packets
			//printf("uu=%u\n",task.jnjct_var);
			update_injct_var(src, task.jnjct_var);

		}

	task_graph_total_pck_num++;
	task.pck_sent = task.pck_sent +1;
	task.burst_sent= task.burst_sent+1;
	task.byte_sent = task.byte_sent + (task.avg_pck_size * (Fpay/8) );

	traffic[src]->pck_class_in=  pck_class_in_gen(src);
	traffic[src]->avg_pck_size_in=task.avg_pck_size;
	traffic[src]->pck_size_in=rnd_between(task.min_pck_size,task.max_pck_size);

	f=  task.injection_rate;
	v= random_var[src];
	f*= (v /100);
	if(f>100) f= 100;
	f=  f * MAX_RATIO / 100;

	traffic[src]->ratio=(unsigned int)f;
	traffic[src]->init_weight=task.initial_weight;




	if (task.burst_sent >= task.burst_size){
		task.burst_sent=0;
		task_graph_abstract[src].active_index=task_graph_abstract[src].active_index+1;
		if(task_graph_abstract[src].active_index>=task_graph_abstract[src].total_index) task_graph_abstract[src].active_index=0;

	}


	update_by_index(task_graph_data[src],index,task);

	if (task.byte_sent  >= task.bytes){ // This task is done remove it from the queue
				remove_by_index(&task_graph_data[src],index);
				task_graph_abstract[src].total_index = task_graph_abstract[src].total_index-1;
				if(task_graph_abstract[src].total_index==0){ //all tasks are done turned off the core
					task_graph_abstract[src].active_index=-1;
					traffic[src]->ratio=0;
					traffic[src]->stop=1;
					if(total_active_routers!=0) total_active_routers--;
					return src;
				}
				if(task_graph_abstract[src].active_index>=task_graph_abstract[src].total_index) task_graph_abstract[src].active_index=0;
	}

	return task.dst;




}




void pck_dst_gen (
    unsigned int current_x,
	unsigned int current_y,
	unsigned int core_num,
	unsigned int *dest_x,
	unsigned int *dest_y
){
	
	if(TRAFFIC_TYPE==CUSTOM){
		int dest = 	pck_dst_gen_task_graph ( core_num);
		 (*dest_y) = (dest / NX );
		 (*dest_x) = (dest % NX );	
		// printf ("%d->%d (%d,%d)\n",core_num,dest,(*dest_y),(*dest_x) );	
		return;
		
	}	
	
	
	if((strcmp (TOPOLOGY,"MESH")==0)||(strcmp (TOPOLOGY,"TORUS")==0)){
		pck_dst_gen_2D (
		    current_x,
			current_y,
			core_num,
			dest_x,
			dest_y
		);
		return;
	}

	dest_y=0;
	pck_dst_gen_1D (
			current_x,
			core_num,
			dest_x);

}




