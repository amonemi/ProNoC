#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <limits.h>
#include <ctype.h>
#include <stdint.h>
#include <inttypes.h>
#include <verilated.h>          // Defines common routines

#include "Vtraffic.h"
#include "Vpck_inj.h"
#include <thread>
#include <vector>
#include <atomic>


#include <cstdint>
#include <cstdlib>
#include <iostream>

#include "simulator.h"

int main(int argc, char** argv) {
	char change_injection_ratio=0;
	int i,j,x,y;//,report_delay_counter=0;

	char deafult_out[] = {"result"};
	NEw=Log2(NE);
	for(i=0;i<NE;i++)   custom_traffic_table[i]=INJECT_OFF; //off
	Verilated::commandArgs(argc, argv);   // Remember args
	processArgs ( argc,  argv );

	if (class_percentage==NULL) {
			class_percentage =   (int *) malloc(sizeof(int));
			class_percentage[0]=100;
	}


	Vrouter_new();
	if( TRAFFIC_TYPE == NETRACE)	for(i=0;i<NE;i++)	pck_inj[i]  = new Vpck_inj;
	else                            for(i=0;i<NE;i++)	traffic[i]  = new Vtraffic;


	if( TRAFFIC_TYPE == NETRACE) netrace_init(netrace_file);

	FIXED_SRC_DST_PAIR = strcmp (TRAFFIC,"RANDOM") &  strcmp(TRAFFIC,"HOTSPOT") & strcmp(TRAFFIC,"random") & strcmp(TRAFFIC,"hot spot") & strcmp(TRAFFIC,"TASK");


	/********************
	*	initialize input
	*********************/

	reset=1;
	reset_all_register();
	start_i=0;
	topology_init();
	if( TRAFFIC_TYPE == NETRACE) pck_inj_init();
	else 	traffic_gen_init();
	main_time=0;
	print_parameter();
	if( thread_num>1) initial_threads();

	while (!Verilated::gotFinish()) {

		if (main_time-saved_time >= 10 ) {
			reset = 0;
		}

		if(main_time == saved_time+21){ count_en=1; start_i=1;}
		if(main_time == saved_time+23) start_i=0;

		if(TRAFFIC_TYPE==NETRACE) netrace_posedge_event();
		else traffic_clk_posedge_event();
		//The valus of all registers and input ports valuse change @ posedge of the clock. Once clk is deasserted,  as multiple modules are connected inside the testbench we need several eval for propogating combinational logic values
		//between modules when the clock .
		for (i=0;i<SMART_MAX+2;i++) {
			if(TRAFFIC_TYPE==NETRACE) netrace_clk_negedge_event( );
			else traffic_clk_negedge_event( );
		}

		if(simulation_done){
			if( TRAFFIC_TYPE == NETRACE) netrace_final_report();
			else traffic_gen_final_report();
			sim_final_all();
			return 0;
		}

		main_time++;

	}//Simulating is done

	sim_final_all();
	return 0;

}


#define __FILENAME__ (__FILE__ + SOURCE_PATH_SIZE)

void  usage(char * bin_name){
	printf("Usage:\n"
" %s -t <synthetic Traffic Pattern name> [synthetic Traffic options]\n"
" %s -f <Task file> [Task options] or\n"
" %s -F <netrace file> [Netrace options] \n\n"
"synthetic Traffic options:\n"
"  -t <Traffic Pattern>        \"HOTSPOT\", \"RANDOM\", \"BIT_COMPLEMENT\" , \"BIT_REVERSE\",\n "
"                              \"TORNADO\", \"TRANSPOSE1\", \"TRANSPOSE2\", \"SHUFFEL\", \"CUSTOM\"\n"
"  -m <Packet size info>       packet size format  Random-Range or Random-discrete:\n"
"                              Random-Range : \"R,MIN,MAX\" : The injected packets' size in flits are\n"
"                                 randomly selected in range MIN <= PCK_size <=MAX \n"
"                              Random-discrete: \"D,S1,S2,..Sn,P,P1,P2,P3,...Pn\": Si are the discrete\n"
"                                 set of numbers representing packet size. The injected packet size is\n"
"                                 randomly selected among these discrete values according to associated\n"
"                                 probability values.\n"
"  -c <sim_end_clk_num>        Simulation will stop when simulation clock number reach this value\n"
"  -n <sim_end_pck_num>        Simulation will stop when total of sent packets to the noc reaches this number\n"
"  -i <injection ratio>        flit injection ratio in percentage\n"
"  -p <class traffic ratios>   The percentage of traffic injected for each class. represented in string\n"
"                              each class ratio is separated by comma. \"n0,n1,n2..\" \n"
"  -h <HOTSPOT traffic format> represented in a string with following format:\n"
"                              total number of hotspot nodes, first hotspot node ID, first hotspot node\n"
"                              send enable(1 or 0),first hotspot node percentage x10,second hotspot node ...\n"
"  -H <custom traffic pattern> custom traffic pattern: represented in a string with following format:\n"
"                              \"SRC1,DEST1, SRC2,DEST2, .., SRCn, DESTn\"   \n"
"  -T <thread-num>             total number of threads. The default is one (no-thread).   \n"
//"  -Q                          Quick (fast) simulation. ignore evaluating non-active routers \n"
"                              to speed up simulation time"	
"\nTrace options:\n"
"  -f <Task file>              path to the task file. any custom task file can be generated using ProNoC gui\n"
"  -c <sim_end_clk_num>        Simulation will stop when simulation clock number reach this value \n"
"  -T <thread-num>             total number of threads. The default is one (no-thread).   \n"
//"  -Q                          Quick (fast) simulation. ignore evaluating non-active routers \n"
"                              to speed up simulation time"	
"\nNetrace options:\n"
"  -F <Netrace file>           path to the task file. any custom task file can be generated using ProNoC gui\n"
"  -n <sim_end_pck_num>        Simulation will stop when total of sent packets to the NoC reaches this number\n"
"  -d                          ignore dependencies\n"
"  -r <start region>           start region\n"
"  -l                          reader throttling\n"
"  -v <level>                  Verbosity level. 0: off, 1:display a live number of injected packet,\n"
"                              3: print injected/ejected packets details, default is 1\n"
"  -T <thread-num>             total number of threads. The default is one (no-thread).   \n"
"  -s <speed-up-num>		   the speed-up-num  is the ratio of netrace frequency to pronoc.The higher value\n"
"                              results in higher injection ratio to the NoC. Default is one" 
//"  -Q                          Quick (fast) simulation. ignore evaluating non-active routers \n"
"                              to speed up simulation time"	,						   
bin_name,bin_name,bin_name
);

}



void netrace_processArgs (int argc, char **argv )
{
   char c;

   /* don't want getopt to moan - I can do that just fine thanks! */
   opterr = 0;
   if (argc < 2)  usage(argv[0]);
   while ((c = getopt (argc, argv, "F:dr:lv:T:n:s:")) != -1)
   {
	 switch (c)
	 {
	 	case 'F':
	 		TRAFFIC_TYPE=NETRACE;
	 		TRAFFIC=(char *) "NETRACE";
	 		netrace_file = optarg;
	 		break;
	 	case 'd':
	 		ignore_dependencies=1;
	 		break;
	 	case 'r':
			start_region=atoi(optarg);
	 		break;
	 	case 'l':
	 		reader_throttling=1;
	 		break;
	 	case 'v':
	 		verbosity= atoi(optarg);
	 		break;
	 	case  'T':
			thread_num = atoi(optarg);
			break;
	 	case 'n':
	 		end_sim_pck_num=atoi(optarg);
	 		break;
	 	case 's':
	 		netrace_speed_up=atoi(optarg);

	 		break;
	 	case '?':
	 	    if (isprint (optopt))
	 	    	fprintf (stderr, "Unknown option `-%c'.\n", optopt);
	 		else
	 		    fprintf (stderr,  "Unknown option character `\\x%x'.\n",  optopt);
	     default:
	 	       usage(argv[0]);
	 	       exit(1);
	  }
	}
}



void synthetic_task_processArgs (int argc, char **argv )
{
   char c;
   int p;
   int array[10];
   float f;

   /* don't want getopt to moan - I can do that just fine thanks! */
   opterr = 0;
   if (argc < 2)  usage(argv[0]);
   while ((c = getopt (argc, argv, "t:m:n:c:i:p:h:H:f:T:Q")) != -1)
      {
	 switch (c)
	    {
	 	case 'f':
	 		TRAFFIC_TYPE=TASK;
	 		TRAFFIC=(char *) "TASK";
	 		task_traffic_init(optarg);
	 		break;
	    case 't':
			TRAFFIC=optarg;
			total_active_routers=-1;
			break;
		case 's':
			MIN_PACKET_SIZE=atoi(optarg);
			break;
		case 'n':
			 end_sim_pck_num=atoi(optarg);
			 break;
		case 'c':
			 sim_end_clk_num=atoi(optarg);
			 break;
		case 'i':
			 f=atof(optarg);
			 f*=(MAX_RATIO/100);
			 ratio= (int) f;
			 break;
		case 'p':
			p= parse_string (optarg, array);
			if (p==0) {
				printf("Warning: class setting is ignored!\n");
				break;
			}
			class_percentage =   (int *) malloc( p * sizeof(int));
			for(int k=0;k<p;k++){
				class_percentage[k]=array[k];
			}
			if(p >1 && p>C){
				printf("Warning: the number of given class %u is larger than the number of message classes in ProNoC (C=%u)!\n",p,C);
			}
			break;
		case 'm':
			update_pck_size(optarg);

			break;
		case 'H':
			update_custom_traffic(optarg);
			break;
		case 'h':
			update_hotspot(optarg);
			break;
		case  'T':
			thread_num = atoi(optarg);
			break;
		case 'Q':
			//Quick_sim_en=1;
			fprintf (stderr, "Unknown option `-%c'.\n", optopt);
			usage(argv[0]);
			exit(1);
			break;
	    case '?':
	       if (isprint (optopt))
		  fprintf (stderr, "Unknown option `-%c'.\n", optopt);
	       else
		  fprintf (stderr, "Unknown option character `\\x%x'.\n", optopt);
	    default:
	       usage(argv[0]);
	       exit(1);
	    }
      }
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






unsigned int pck_dst_gen ( 	unsigned int core_num) {
	if(TRAFFIC_TYPE==TASK)	return  	pck_dst_gen_task_graph ( core_num);
	if((strcmp (TOPOLOGY,"MESH")==0)||(strcmp (TOPOLOGY,"TORUS")==0))	return  pck_dst_gen_2D (core_num);
	return pck_dst_gen_1D (core_num);
}



void update_hotspot(char * str){
	 int i;
	 int array[1000];
	 int p;
	 int acuum=0;
	 hotspot_st * new_node;
	 p= parse_string (str, array);
	 if (p<4){
		    fprintf(stderr,"ERROR: in hotspot traffic parameters. 4 value should be given as hotspot parameter\n");
			exit(1);
	 }
	 HOTSPOT_NUM=array[0];
	 if (p<1+HOTSPOT_NUM*3){
		    fprintf(stderr,"ERROR: in hotspot traffic parameters \n");
			exit(1);
	 }
	 new_node =  (hotspot_st *) malloc( HOTSPOT_NUM * sizeof(hotspot_st));
	 if( new_node == NULL){
		 fprintf(stderr,"ERROR: cannot allocate memory for hotspot traffic\n");
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

void update_custom_traffic (char * str){
	int i;
	int array[10000];
	int p;
	p= parse_string (str, array);
	for (i=0;i<p; i+=2){
		custom_traffic_table[array[i]] = array[i+1];
	}
}

void update_pck_size(char *str){
	int i;
	int array[1000];
	char substring[1000];
	int p;
	char *pt,*pt2;
	MIN_PACKET_SIZE=100000;
	MAX_PACKET_SIZE=1;


	pt = strtok (str,",");
	if(*pt=='R'){//random range
		p= parse_string (str+2, array);
		if(p<2){
			fprintf(stderr,"ERROR: Wrong Packet size format %s. It should be \"R,min,max\" : \n",str);
			exit(1);
		}

		MIN_PACKET_SIZE=array[0];
		MAX_PACKET_SIZE=array[1];
		AVG_PACKET_SIZE=(MIN_PACKET_SIZE+MAX_PACKET_SIZE)/2;// average packet size
	}else if(*pt=='D'){//random discrete
		pck_size_sel =  RANDOM_discrete;
		pt = strtok (str+2,"P");
		pt2 = strtok (NULL,"P");
		if (pt == NULL || pt2==NULL) {
			fprintf(stderr,"ERROR: Wrong Packet size format %s. It should be \"D,s1,s2..sn,P,p1,p2..pn\". missing letter \"P\" in format  \n",str);
			exit(1);
		}
		p= parse_string (pt, array);
		if (p==0){
			fprintf(stderr,"ERROR: Wrong Packet size format %s. It should be \"D,s1,s2..sn,P,p1,p2..pn\". missing si values after letter \"D\" \"P\" in format  \n",str);
			exit(1);
		}
		int in=p;
		//alocate mmeory for pck size
		discrete_size = (int*)malloc((p) * sizeof(int));
		discrete_prob = (int*)malloc((p) * sizeof(int));
		// Check if the memory has been successfully allocated
		if (discrete_size == NULL || discrete_prob==NULL) {
			printf("ERROR: Memory not allocated.\n");
			exit(1);
		}

		for (i=0; i<p; i++){

			//printf("I[%u]=%u,\n",i,array[i]);
			discrete_size[i] = array[i];
			if(MIN_PACKET_SIZE > array[i]) MIN_PACKET_SIZE = array[i];
			if(MAX_PACKET_SIZE < array[i]) MAX_PACKET_SIZE = array[i];
		}

		p= parse_string (pt2+1, array);
		int sum=0;
		AVG_PACKET_SIZE=0;
		for (i=0; i<p; i++){
			//printf("P[%u]=%u,\n",i,array[i]);
			if(i<in){
				 sum+=array[i];
				 discrete_prob[i]=sum;
				 AVG_PACKET_SIZE+=discrete_size[i] * array[i];

			}
		}
		AVG_PACKET_SIZE/=100;

		if(sum!=100){
			fprintf(stderr,"ERROR: The accumulatio of the first %u probebility values is %u which is not equal to 100\n",in,sum);
			exit(1);
		}

	}else {
		fprintf(stderr,"ERROR: Wrong Packet size format %s. It should start with one of \"D\" or \"R\" letter\n",str);
		exit(1);
	}
	p=(MAX_PACKET_SIZE-MIN_PACKET_SIZE)+1;
	rsv_size_array = (unsigned int*) calloc ( p , sizeof(int));
	if (rsv_size_array==NULL){
		 fprintf(stderr,"ERROR: cannot allocate memory for rsv_size_array\n");
		 exit(1);
	}

}


void task_traffic_init (char * str) {
	load_traffic_file(str,task_graph_data,task_graph_abstract);
	end_sim_pck_num=task_graph_total_pck_num;
	MIN_PACKET_SIZE = task_graph_min_pck_size;
	MAX_PACKET_SIZE = task_graph_max_pck_size;
	AVG_PACKET_SIZE=(MIN_PACKET_SIZE+MAX_PACKET_SIZE)/2;// average packet size
	int p=(MAX_PACKET_SIZE-MIN_PACKET_SIZE)+1;
	rsv_size_array = (unsigned int*) calloc ( p , sizeof(int));
	if (rsv_size_array==NULL){
		fprintf(stderr,"ERROR: cannot allocate (%d x int) memory for rsv_size_array. \n",p);
		 exit(1);
	}
}







void processArgs (int argc, char **argv ){
	int i;
	for( i = 1; i < argc; ++i ) {
		if( strcmp(argv[i], "-t") == 0 ) {
			synthetic_task_processArgs ( argc, argv );
			return;
		} else if( strcmp(argv[i], "-f") == 0 ) {
			synthetic_task_processArgs ( argc, argv );
			return;

		} else if( strcmp(argv[i], "-F") == 0 ) {
			netrace_processArgs (argc, argv );
			return;
		}
	}
	fprintf (stderr, "you should define one one of Synthetic,Task or nettrace based simulation. \n");
	usage(argv[0]);
	exit(1);
}


int get_new_pck_size(){
		if(pck_size_sel ==  RANDOM_discrete){
				int rnd = rand() % 100; // 0~99
				int i=0;
				while( rnd > discrete_prob[i] ) i++;
				return discrete_size [i];
		}
		//random range
		return rnd_between(MIN_PACKET_SIZE,MAX_PACKET_SIZE);
}






void traffic_gen_final_report(){
	int i;
	for (i=0;i<NE;i++) if(traffic[i]->pck_number>0) total_active_endp   	= 	total_active_endp +1;
	printf("\nsimulation results-------------------\n");
	printf("\tSimulation clock cycles:%d\n",clk_counter);
	printf("\n\tTotal injected packet in different size:\n");
	printf("\tflit_size,");
	for (i=0;i<=(MAX_PACKET_SIZE - MIN_PACKET_SIZE);i++){
		if(rsv_size_array[i]>0) printf("%u,",i+ MIN_PACKET_SIZE);
	}
	printf("\n\t#pck,");
	for (i=0;i<=(MAX_PACKET_SIZE - MIN_PACKET_SIZE);i++){
	   	if(rsv_size_array[i]>0) printf("%u,",rsv_size_array[i]);
	}
	printf("\n");

//	printf(" total received flits:%d\n",total_rsv_flit_number);
//	printf(" total sent flits:%d\n",total_sent_flit_number);
	print_statistic_new (clk_counter);

}


void traffic_gen_init( void ){
	int i;
	unsigned int dest_e_addr;
	for (i=0;i<NE;i++){
	    	random_var[i] = 100;
	    	traffic[i]->current_e_addr		= endp_addr_encoder(i);
	    	traffic[i]->start=0;
	    	traffic[i]->pck_class_in=  pck_class_in_gen( i);
	    	traffic[i]->pck_size_in=get_new_pck_size();
	    	dest_e_addr=pck_dst_gen (i);
	    	traffic[i]->dest_e_addr= dest_e_addr;
	    	if(dest_e_addr == INJECT_OFF) traffic[i]->stop=1;
	    	//printf("src=%u, des_eaddr=%x, dest=%x\n", i,dest_e_addr, endp_addr_decoder(dest_e_addr));
	    	if(inject_done) traffic[i]->stop=1;
	    	traffic[i]->start_delay=rnd_between(1,4*NE-2);
	    	if(TRAFFIC_TYPE==SYNTHETIC){
	    		//traffic[i]->avg_pck_size_in=AVG_PACKET_SIZE;
	    		traffic[i]->ratio=ratio;
	    		traffic[i]->init_weight=1;
	    	}
	}
}

void pck_inj_init (void){
	int i;
	for (i=0;i<NE;i++){
	   	pck_inj[i]->current_e_addr		= endp_addr_encoder(i);
	   //TODO mapping should be done according to number of NE and should be set by the user larer
	   	netrace_to_pronoc_map[i]=(int)((i* NE)/header->num_nodes);
	   	pck_inj[i]->pck_injct_in_ready= (0x1<<V)-1;
	   	pck_inj[i]->pck_injct_in_pck_wr=0;
		//pronoc_to_netrace_map[i]=i;

	}

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

/*
volatile int *  lock;
unsigned int  nr_per_thread=0;
unsigned int  ne_per_thread=0;

void thread_function (int n){
	int i; 
	unsigned int node=0;
	while(1){ 
		while(lock[n]==0) std::this_thread::yield();
		for(i=0;i<nr_per_thread;i++){
			node= (n * nr_per_thread)+i;
			if (node >= NR) break;
			single_router_eval(node);
		}	
		for(i=0;i<ne_per_thread;i++){
			node= (n * ne_per_thread)+i;
			if (node >= NE) break;
			if( TRAFFIC_TYPE == NETRACE)   pck_inj[node]->eval();
			else   traffic[node]->eval();
		}	
		
		//router1[n]->eval();
		//if( TRAFFIC_TYPE == NETRACE)   pck_inj[n]->eval();
		//else   traffic[n]->eval();
	
		lock[n]=0;
		if(n==0) break;//first thread is the main process 
	}
}
*/

class alignas(64) Vthread
{
    // Access specifier
    public:
	std::atomic<bool> ready;
    // Data Members
    int n;//thread num
	int nr_per_thread;
	int ne_per_thread;
    // Member Functions()
    //Parameterized Constructor
    
    
    void function ( ){
		int i; 
		unsigned int node=0;
		while(1){ 
			while(!ready) std::this_thread::yield();
			for(i=0;i<nr_per_thread;i++){
				node= (n * nr_per_thread)+i;
				if (node >= NR) break;
				//if(router_is_active[node] | (Quick_sim_en==0))
				single_router_eval(node);
			}	
			for(i=0;i<ne_per_thread;i++){
				node= (n * ne_per_thread)+i;
				if (node >= NE) break;
				if( TRAFFIC_TYPE == NETRACE)   pck_inj[node]->eval();
				else   traffic[node]->eval();
			}	
			
			//router1[n]->eval();
			//if( TRAFFIC_TYPE == NETRACE)   pck_inj[n]->eval();
			//else   traffic[n]->eval();
		
			ready=false;
			if(n==0) break;//first thread is the main process 
		}
	}
	
	Vthread(int x,int r,int e)
    {
       n=x; nr_per_thread=r; ne_per_thread=e;
       ready=false;
       if(n!=0) {
		 std::thread th {&Vthread::function,this};     
         th.detach();      
	   }
    }
	
	
};

Vthread ** thread;

void initial_threads (void){
	int i;
	//devide nodes equally between threads
	unsigned int  nr_per_thread=0;
	unsigned int  ne_per_thread=0;
	nr_per_thread = (NR % thread_num)?  (unsigned int)(NR/thread_num) + 1 :  (unsigned int)(NR/thread_num);
	ne_per_thread = (NE % thread_num)?  (unsigned int)(NE/thread_num) + 1 :  (unsigned int)(NE/thread_num);
	
	//std::vector<std::thread> threads(thread_num-1);
	//lock = new int[thread_num];
	//for(i=0;i<thread_num;i++) lock [i]=0;	
	
	//Dynamically Allocating Memory
	thread = (Vthread **) new Vthread * [thread_num]; 
	for(i=0;i<thread_num;i++) thread[i] = new Vthread(i,nr_per_thread,ne_per_thread) ;
	
	//initiates (thread_num-1) number of live thread	 
	//for(i=0;i<thread_num-1;i++) threads[i] = std::thread(&thread_function, (i+1));
	//for (auto& th : threads)    th.detach();
	
	unsigned maxThreads = std::thread::hardware_concurrency();
    printf("Thread is initiated as following:\n"
    "\tMax hardware supported threads:%u\n"
    "\tthread_num:%u\n"
    "\trouter per thread:%u\n"
    "\tendpoint per thread:%u\n"
    ,maxThreads,thread_num,nr_per_thread,ne_per_thread);
}




void sim_eval_all (void){
	int i;
	if(thread_num>1) {
		for(i=0;i<thread_num;i++) thread[i]->ready=true;
		//thread_function (0);		
		thread[0]->function();
		for(i=0;i<thread_num;i++)while(thread[i]->ready);
	}else{// no thread
		//routers_eval();
		for(i=0;i<NR;i++){
			//if(router_is_active[i] | (Quick_sim_en==0)) 
			single_router_eval(i);
		}
		if( TRAFFIC_TYPE == NETRACE) for(i=0;i<NE;i++) pck_inj[i]->eval();
		else for(i=0;i<NE;i++) traffic[i]->eval();
	}
}	

void sim_final_all (void){
	int i;
	routers_final();
	if( TRAFFIC_TYPE == NETRACE) for(i=0;i<NE;i++) pck_inj[i]->final();
	else for(i=0;i<NE;i++) traffic[i]->final();
	//noc->final(); 
}	

void connect_clk_reset_start_all(void){
	int i;
	//noc-> clk = clk; 
	//noc-> reset = reset;
	if( TRAFFIC_TYPE == NETRACE) {
		for(i=0;i<NE;i++)	{
			pck_inj[i]->reset= reset;
			pck_inj[i]->clk	= clk;
		}
	}else {
		for(i=0;i<NE;i++)	{
			start_o[i]=start_i;
			traffic[i]->start= start_o[i];
			traffic[i]->reset= reset;
			traffic[i]->clk	= clk;
		}
	}
	connect_routers_reset_clk();
}


void traffic_clk_negedge_event(void){
	int i;
	clk = 0;
	//for (i=0;i<NR;i++) router_is_active [i]=0;
	topology_connect_all_nodes ();
	
	for (i=0;i<NE;i++){
		if(inject_done) traffic[i]->stop=1;
	}
	connect_clk_reset_start_all();
	sim_eval_all();
}	




void traffic_clk_posedge_event(void) {
	int i;
	unsigned int dest_e_addr;
	clk = 1;       // Toggle clock
	if(count_en) clk_counter++;
	inject_done= ((total_sent_pck_num >= end_sim_pck_num) || (clk_counter>= sim_end_clk_num) || total_active_routers == 0);
	//if(inject_done) printf("clk_counter=========%d\n",clk_counter);
	total_rsv_flit_number_old=total_rsv_flit_number;
	for (i=0;i<NE;i++){
		// a packet has been received
		if(traffic[i]->update & ~reset){
			update_noc_statistic (i) ;
		}
		// the header flit has been sent out
		if(traffic[i]->hdr_flit_sent ){
			traffic[i]->pck_class_in=  pck_class_in_gen( i);
			sent_core_total_pck_num[i]++;
			traffic[i]->pck_size_in=get_new_pck_size();
			if(!FIXED_SRC_DST_PAIR){
				dest_e_addr=pck_dst_gen (i);
				traffic[i]->dest_e_addr= dest_e_addr;
				if(dest_e_addr == INJECT_OFF) traffic[i]->stop=1;
				//printf("src=%u, dest=%x\n", i,endp_addr_decoder(dest_e_addr));
			}
		}

			if(traffic[i]->flit_out_wr==1){
				total_sent_flit_number++;
				#if (C>1)
					sent_stat [i][traffic[i]->flit_out_class].flit_num++;
				#else
					sent_stat [i].flit_num++;
				#endif
			}
			if(traffic[i]->flit_in_wr==1){
				total_rsv_flit_number++;
				#if (C>1)
					rsvd_stat [i][traffic[i]->pck_class_out].flit_num++;
				#else
					rsvd_stat [i].flit_num++;
				#endif
			}
			if(traffic[i]->hdr_flit_sent==1){
				total_sent_pck_num++;
				#if (C>1)
					sent_stat [i][traffic[i]->flit_out_class].pck_num++;
				#else
					sent_stat [i].pck_num++;
				#endif
			}

		}//for


			if(inject_done){
				if(total_rsv_flit_number_old == total_rsv_flit_number){
						ideal_rsv_cnt++;
						if(ideal_rsv_cnt >= 100){
							print_statistic( );
							fprintf(stderr,"ERROR: The number of sent (%u) & received flits (%u) were not equal at the end of simulation\n",total_sent_flit_number, total_rsv_flit_number);
							exit(1);
						}
				}
				if(total_sent_flit_number == total_rsv_flit_number ) simulation_done=1;
			}
	connect_clk_reset_start_all();
	sim_eval_all();
			
}			


/**********************************
 *
 * 	update_noc_statistic
 *
 *
 *********************************/



void update_statistic_at_ejection (
	int	core_num,
	unsigned int   	clk_num_h2h,
	unsigned int    clk_num_h2t,
	unsigned int    distance,
	unsigned int  	class_num,
	unsigned int 	src  	){

	total_rsv_pck_num+=1;

	if( TRAFFIC_TYPE != NETRACE){

	//old st
	if((total_rsv_pck_num & 0Xffff )==0 ) printf(" packet sent total=%d\n",total_rsv_pck_num);
	sum_clk_h2h+=clk_num_h2h;
	sum_clk_h2t+=clk_num_h2t;
#if (STND_DEV_EN)
	sum_clk_pow2+=(double)clk_num_h2h * (double) clk_num_h2h;
	sum_clk_pow2_per_class[class_num]+=(double)clk_num_h2h * (double) clk_num_h2h;
#endif			        		
	sum_clk_per_hop+= ((double)clk_num_h2h/(double)distance);
	//printf("sum_clk_per_hop(%f)+= clk_num_h2h(%u)/distance(%u)\n",sum_clk_per_hop,clk_num_h2h,distance);
	total_rsv_pck_num_per_class[class_num]+=1;
	sum_clk_h2h_per_class[class_num]+=clk_num_h2h ;
	sum_clk_h2t_per_class[class_num]+=clk_num_h2t ;
	sum_clk_per_hop_per_class[class_num]+= ((double)clk_num_h2h/(double)distance);
	rsvd_core_total_pck_num[core_num]=rsvd_core_total_pck_num[core_num]+1;

		if (rsvd_core_worst_delay[core_num] < clk_num_h2t) rsvd_core_worst_delay[core_num] = (strcmp (AVG_LATENCY_METRIC,"HEAD_2_TAIL")==0)?  clk_num_h2t :  clk_num_h2h;
		if (sent_core_worst_delay[src] < clk_num_h2t) sent_core_worst_delay[src] = (strcmp (AVG_LATENCY_METRIC,"HEAD_2_TAIL")==0)?  clk_num_h2t :  clk_num_h2h;

		if( traffic[core_num]->pck_size_o >= MIN_PACKET_SIZE && traffic[core_num]->pck_size_o <=MAX_PACKET_SIZE){
		  if(rsv_size_array!=NULL) 	rsv_size_array[traffic[core_num]->pck_size_o-MIN_PACKET_SIZE]++;
		}
	}
    //new one TODO remove old st

	if(verbosity==0 &&  TRAFFIC_TYPE == NETRACE) if((total_rsv_pck_num & 0X1FFFF )==0 ) printf(" packet sent total=%d\n",total_rsv_pck_num);
    unsigned int latency = (strcmp (AVG_LATENCY_METRIC,"HEAD_2_TAIL")==0)? clk_num_h2t :  clk_num_h2h;
    #if(C>1)

    	rsvd_stat[core_num][class_num].pck_num ++;
    	rsvd_stat[core_num][class_num].sum_clk_h2h +=clk_num_h2h;
    	rsvd_stat[core_num][class_num].sum_clk_h2t +=clk_num_h2t;
    	rsvd_stat[core_num][class_num].sum_clk_per_hop+= ((double)clk_num_h2h/(double)distance);
    	if (rsvd_stat[core_num][class_num].worst_latency < latency ) rsvd_stat[core_num][class_num].worst_latency =latency;
    	if (rsvd_stat[core_num][class_num].min_latency==0          ) rsvd_stat[core_num][class_num].min_latency   =latency;
    	if (rsvd_stat[core_num][class_num].min_latency   > latency ) rsvd_stat[core_num][class_num].min_latency   =latency;
    	if (sent_stat[src     ][class_num].worst_latency < latency ) sent_stat[src     ][class_num].worst_latency =latency;
    	if (sent_stat[src     ][class_num].min_latency==0          ) sent_stat[src     ][class_num].min_latency   =latency;
    	if (sent_stat[src     ][class_num].min_latency   > latency ) sent_stat[src     ][class_num].min_latency   =latency;

		#if (STND_DEV_EN)
        	rsvd_stat[core_num][class_num].sum_clk_pow2 += (double)clk_num_h2h * (double) clk_num_h2h;
		#endif
	#else
    	rsvd_stat[core_num].pck_num ++;
        rsvd_stat[core_num].sum_clk_h2h +=(double)clk_num_h2h;
        rsvd_stat[core_num].sum_clk_h2t +=(double)clk_num_h2t;
        rsvd_stat[core_num].sum_clk_per_hop+= ((double)clk_num_h2h/(double)distance);
        if (rsvd_stat[core_num].worst_latency < latency ) rsvd_stat[core_num].worst_latency=latency;
        if (rsvd_stat[core_num].min_latency==0          ) rsvd_stat[core_num].min_latency  =latency;
        if (rsvd_stat[core_num].min_latency   > latency ) rsvd_stat[core_num].min_latency  =latency;
        if (sent_stat[src     ].worst_latency < latency ) sent_stat[src     ].worst_latency=latency;
        if (sent_stat[src     ].min_latency==0          ) sent_stat[src     ].min_latency  =latency;
        if (sent_stat[src     ].min_latency   > latency ) sent_stat[src     ].min_latency  =latency;

		#if (STND_DEV_EN)
        	rsvd_stat[core_num].sum_clk_pow2 += (double)clk_num_h2h * (double) clk_num_h2h;
		#endif
	#endif





}

void update_noc_statistic (	int	core_num){
	unsigned int   	clk_num_h2h =traffic[core_num]->time_stamp_h2h;
	unsigned int    clk_num_h2t =traffic[core_num]->time_stamp_h2t;
    unsigned int    distance=traffic[core_num]->distance;
    unsigned int  	class_num=traffic[core_num]->pck_class_out;
    unsigned int    src_e_addr=traffic[core_num]->src_e_addr;
    unsigned int 	src = endp_addr_decoder (src_e_addr);

    update_statistic_at_ejection ( core_num,	clk_num_h2h,  clk_num_h2t,  distance,  	class_num, 	src);


}

avg_st_t finilize_statistic (unsigned long int total_clk, statistic_t rsvd_stat){

	 avg_st_t avg_statistic;
	 avg_statistic.avg_throughput= ((double)(rsvd_stat.flit_num*100)/NE )/total_clk;
	 avg_statistic.avg_latency_flit    = rsvd_stat.sum_clk_h2h/rsvd_stat.pck_num;
	 avg_statistic.avg_latency_pck	   = rsvd_stat.sum_clk_h2t/rsvd_stat.pck_num;
	 avg_statistic.avg_latency_per_hop = ( rsvd_stat.pck_num==0)? 0 : rsvd_stat.sum_clk_per_hop/rsvd_stat.pck_num;
	 avg_statistic.avg_pck_siz        = ( rsvd_stat.pck_num==0)? 0 : (double)(rsvd_stat.flit_num / rsvd_stat.pck_num);
	 #if (STND_DEV_EN)
	 	 avg_statistic.std_dev =standard_dev( rsvd_stat.sum_clk_pow2,rsvd_stat.pck_num, avg_statistic.avg_latency_flit);
	 #endif
	 return avg_statistic;
}

template<typename T>
	void myout(T value)
	{
	   std::cout << value << std::endl;
	}
template<typename First, typename ... Rest>
	void myout(First first, Rest ... rest)
	{
	   std::cout << first << ",";
	   myout(rest...);
	}

void print_st_single (unsigned long int total_clk, statistic_t rsvd_stat, statistic_t sent_stat){



	avg_st_t avg;
	avg=finilize_statistic (total_clk,  rsvd_stat);

	myout(
			sent_stat.pck_num,
			rsvd_stat.pck_num,
			sent_stat.flit_num,
			rsvd_stat.flit_num,
			sent_stat.worst_latency,
			rsvd_stat.worst_latency,
			sent_stat.min_latency,
			rsvd_stat.min_latency,
			avg.avg_latency_per_hop,
			avg.avg_latency_flit,
			avg.avg_latency_pck,
			avg.avg_throughput,
			avg.avg_pck_siz,
			#if (STND_DEV_EN)
			avg.std_dev
			#endif
	);
//	printf("\n");

}


void merge_statistic (statistic_t * merge_stat, statistic_t stat_in){
	merge_stat->pck_num+=stat_in.pck_num;
	merge_stat->flit_num+=stat_in.flit_num;
	if(merge_stat->worst_latency <  stat_in.worst_latency) merge_stat->worst_latency= stat_in.worst_latency;
	if(merge_stat->min_latency   == 0                       ) merge_stat->min_latency  = stat_in.min_latency;
	if(merge_stat->min_latency   > stat_in.min_latency  && stat_in.min_latency!=0   ) merge_stat->min_latency  = stat_in.min_latency;
	merge_stat->sum_clk_h2h      +=stat_in.sum_clk_h2h    ;
	merge_stat->sum_clk_h2t      +=stat_in.sum_clk_h2t    ;
	merge_stat->sum_clk_per_hop  +=stat_in.sum_clk_per_hop;
	#if (STND_DEV_EN)
		merge_stat->sum_clk_pow2 +=stat_in.sum_clk_pow2;
    #endif

}

void print_statistic_new (unsigned long int total_clk){
	int i;
	printf("\n\t#node,"
			"sent_stat.pck_num,"
			"rsvd_stat.pck_num,"
			"sent_stat.flit_num,"
			"rsvd_stat.flit_num,"
			"sent_stat.worst_latency,"
			"rsvd_stat.worst_latency,"
			"sent_stat.min_latency,"
			"rsvd_stat.min_latency,"
			"avg_latency_per_hop,"
			"avg_latency_flit,"
			"avg_latency_pck,"
			"avg_throughput(%%),"
			"avg_pck_size,"
			#if (STND_DEV_EN)
			"avg.std_dev"
			#endif
			"\n");



#if(C>1)
	int c;
	statistic_t sent_stat_class [NE];
	statistic_t rsvd_stat_class [NE];
	statistic_t sent_stat_per_class [C];
	statistic_t rsvd_stat_per_class [C];

	memset (&rsvd_stat_class,0,sizeof(statistic_t)*NE);
	memset (&sent_stat_class,0,sizeof(statistic_t)*NE);
	memset (&rsvd_stat_per_class,0,sizeof(statistic_t)*C);
	memset (&sent_stat_per_class,0,sizeof(statistic_t)*C);


	for (i=0; i<NE;i++){
		for (c=0; c<C;c++){
			merge_statistic (&rsvd_stat_class[i],rsvd_stat[i][c]);
			merge_statistic (&sent_stat_class[i],sent_stat[i][c]);
			merge_statistic (&rsvd_stat_per_class[c],rsvd_stat[i][c]);
			merge_statistic (&sent_stat_per_class[c],sent_stat[i][c]);
		}
	}




#else
	#define sent_stat_class  sent_stat
	#define rsvd_stat_class  rsvd_stat
#endif





	statistic_t rsvd_stat_total, sent_stat_total;
	memset (&rsvd_stat_total,0,sizeof(statistic_t));
	memset (&sent_stat_total,0,sizeof(statistic_t));
	for (i=0; i<NE;i++){
		merge_statistic (&rsvd_stat_total,rsvd_stat_class[i]);
		merge_statistic (&sent_stat_total,sent_stat_class[i]);
	}
	printf("\ttotal,");
	print_st_single (total_clk, rsvd_stat_total,sent_stat_total);

#if(C>1)
	for (c=0; c<C;c++){
		printf("\ttotal_class%u,",c);
		print_st_single (total_clk, rsvd_stat_per_class[c],sent_stat_per_class[c]);
	}
#endif

    for (i=0; i<NE;i++){
    	printf("\t%u,",i);
    	print_st_single (total_clk, rsvd_stat_class[i],sent_stat_class[i] );
    }
}



void print_statistic (void){
	double avg_latency_per_hop,  avg_latency_flit, avg_latency_pck, avg_throughput,min_avg_latency_per_class;
	int i;
#if (STND_DEV_EN)
	double	std_dev;
#endif

	avg_throughput= ((double)(total_sent_flit_number*100)/total_active_endp )/clk_counter;
	printf(" Total active Endpoint: %d \n",total_active_endp);
	printf(" Avg throughput is: %f (flits/clk/Total active Endpoint %%)\n",    avg_throughput);
	avg_latency_flit   = (double)sum_clk_h2h/total_rsv_pck_num;
	avg_latency_pck	   = (double)sum_clk_h2t/total_rsv_pck_num;
	if(ratio==RATIO_INIT) first_avg_latency_flit=avg_latency_flit;
#if (STND_DEV_EN)
	std_dev= standard_dev( sum_clk_pow2,total_rsv_pck_num, avg_latency_flit);
	printf(" standard_dev = %f\n",std_dev);
#endif
    avg_latency_per_hop    = (double)sum_clk_per_hop/total_rsv_pck_num;
    printf("\nall : \n");
  	printf(" Total number of packet = %d \n average latency per hop = %f \n",total_rsv_pck_num,avg_latency_per_hop);
  	printf(" average packet latency = %f \n average flit latency = %f \n",avg_latency_pck, avg_latency_flit);
    min_avg_latency_per_class=1000000;
    printf(" Total injected packet in different size:\n");
    for (i=0;i<=(MAX_PACKET_SIZE - MIN_PACKET_SIZE);i++){
    	if(rsv_size_array[i]>0) printf("\t %u flit_sized pck = %u\n",i+ MIN_PACKET_SIZE, rsv_size_array[i]);
    }
    printf("\n");

    for(i=0;i<C;i++){
           	avg_throughput		 = (total_rsv_pck_num_per_class[i]>0)? ((double)(total_rsv_pck_num_per_class[i]*AVG_PACKET_SIZE*100)/total_active_endp )/clk_counter:0;
			avg_latency_flit 	 = (total_rsv_pck_num_per_class[i]>0)? (double)sum_clk_h2h_per_class[i]/total_rsv_pck_num_per_class[i]:0;
			avg_latency_pck	   	 = (total_rsv_pck_num_per_class[i]>0)? (double)sum_clk_h2t_per_class[i]/total_rsv_pck_num_per_class[i]:0;
			avg_latency_per_hop  = (total_rsv_pck_num_per_class[i]>0)? (double)sum_clk_per_hop_per_class[i]/total_rsv_pck_num_per_class[i]:0;
			printf ("\nclass : %d  \n",i);
	        printf (" Total number of packet = %d \n avg_throughput = %f \n average latency per hop = %f \n ",total_rsv_pck_num_per_class[i],avg_throughput,avg_latency_per_hop);
            printf (" average packet latency = %f \n average flit latency = %f \n",avg_latency_pck,avg_latency_flit);
            if(min_avg_latency_per_class > avg_latency_flit) min_avg_latency_per_class=avg_latency_flit;

#if (STND_DEV_EN)
            std_dev= (total_rsv_pck_num_per_class[i]>0)?  standard_dev( sum_clk_pow2_per_class[i],total_rsv_pck_num_per_class[i], avg_latency_flit):0;
            printf(" standard_dev = %f\n",std_dev);
#endif
	}//for
	current_avg_latency_flit=min_avg_latency_per_class;
	for (i=0;i<NE;i++) {
		printf	 ("\n\nEnd_point %d\n",i);
		printf	 ("\n\ttotal number of received packets: %u\n",rsvd_core_total_pck_num[i]);
		printf	 ("\n\tworst-case-delay of received packets (clks): %u\n",rsvd_core_worst_delay[i] );
		printf	 ("\n\ttotal number of sent packets: %u\n",traffic[i]->pck_number);
		printf	 ("\n\tworst-case-delay of sent packets (clks): %u\n",sent_core_worst_delay[i] );
	}

	print_statistic_new (clk_counter);


}


void print_parameter (){
		printf ("NoC parameters:---------------- \n");
		printf ("\tTopology: %s\n",TOPOLOGY);
		printf ("\tRouting algorithm: %s\n",ROUTE_NAME);
	 	printf ("\tVC_per port: %d\n", V);
	 	printf ("\tNon-local port buffer_width per VC: %d\n", B);
	 	printf ("\tLocal port buffer_width per VC: %d\n", LB);
if((strcmp (TOPOLOGY,"MESH")==0)||(strcmp (TOPOLOGY,"TORUS")==0)){
	    printf ("\tRouter num in row: %d \n",T1);
	    printf ("\tRouter num in column: %d \n",T2);
	    printf ("\tEndpoint num per router: %d\n",T3);
}else if ((strcmp (TOPOLOGY,"RING")==0)||(strcmp (TOPOLOGY,"LINE")==0)){
		printf ("\tTotal Router num: %d \n",T1);
		printf ("\tEndpoint num per router: %d\n",T3);
}
else if ((strcmp (TOPOLOGY,"TREE")==0)||(strcmp (TOPOLOGY,"FATTREE")==0)){
		printf ("\tK: %d \n",T1);
		printf ("\tL: %d \n",T2);
} else{ //CUSTOM
	    printf ("\tTotal Endpoints number: %d \n",T1);
		printf ("\tTotal Routers number: %d \n",T2);
}
	    printf ("\tNumber of Class: %d\n", C);
	    printf ("\tFlit data width: %d \n", Fpay);
	    printf ("\tVC reallocation mechanism: %s \n",  VC_REALLOCATION_TYPE);
	    printf ("\tVC/sw combination mechanism: %s \n", COMBINATION_TYPE);
	    printf ("\tAVC_ATOMIC_EN:%d \n", AVC_ATOMIC_EN);
	    printf ("\tCongestion Index:%d \n",CONGESTION_INDEX);
	    printf ("\tADD_PIPREG_AFTER_CROSSBAR:%d\n",ADD_PIPREG_AFTER_CROSSBAR);
	    printf ("\tSSA_EN enabled:%s \n",SSA_EN);
	    printf ("\tSwitch allocator arbitration type:%s \n",SWA_ARBITER_TYPE);
	    printf ("\tMinimum supported packet size:%d flit(s) \n",MIN_PCK_SIZE);
	    printf ("\tLoop back is enabled:%s",SELF_LOOP_EN);
	    printf ("\tNumber of multihop bypass (SMART max):%d \n",SMART_MAX);
	printf ("NoC parameters:---------------- \n");
	printf ("\nSimulation parameters-------------\n");
#if(DEBUG_EN)
    printf ("\tDebuging is enabled\n");
#else
    printf ("\tDebuging is disabled\n");
#endif
	//if(strcmp (AVG_LATENCY_METRIC,"HEAD_2_TAIL")==0)printf ("\tOutput is the average latency on sending the packet header until receiving tail\n");
	//else printf ("\tOutput is the average latency on sending the packet header until receiving header flit at destination node\n");
	printf ("\tTraffic pattern:%s\n",TRAFFIC);
	size_t n = sizeof(class_percentage)/sizeof(class_percentage[0]);
	for(int p=0;p<n; p++){
		printf ("\ttraffic percentage of class %u is : %d\n",p,  class_percentage[p]);
	}
	if(strcmp (TRAFFIC,"HOTSPOT")==0){
		//printf ("\tHot spot percentage: %u\n", HOTSPOT_PERCENTAGE);
	    printf ("\tNumber of hot spot cores: %d\n", HOTSPOT_NUM);

	}
	    //printf ("\tTotal packets sent by one router: %u\n", TOTAL_PKT_PER_ROUTER);
		if(sim_end_clk_num!=0) printf ("\tSimulation timeout =%d\n", sim_end_clk_num);
		if(end_sim_pck_num!=0) printf ("\tSimulation ends on total packet num of =%d\n", end_sim_pck_num);
		if(TRAFFIC_TYPE!=NETRACE){
			printf ("\tPacket size (min,max,average) in flits: (%u,%u,%u)\n",MIN_PACKET_SIZE,MAX_PACKET_SIZE,AVG_PACKET_SIZE);
			printf ("\tPacket injector FIFO width in flit:%u \n",TIMSTMP_FIFO_NUM);
		}
		if( TRAFFIC_TYPE == SYNTHETIC) printf("\tFlit injection ratio per router is =%f (flits/clk/Total Endpoint %%)\n",(float)ratio*100/MAX_RATIO);
		printf ("Simulation parameters-------------\n");
}





/************************
 *
 * 	reset system
 *
 *
 * *******************/

void reset_all_register (void){
	int i;
	 total_active_endp=0;
	 total_rsv_pck_num=0;
	 total_sent_pck_num=0;
	 sum_clk_h2h=0;
	 sum_clk_h2t=0;
	 ideal_rsv_cnt=0;
#if (STND_DEV_EN)
	 sum_clk_pow2=0;
#endif

	 sum_clk_per_hop=0;
	 count_en=0;
	 clk_counter=0;

	 for(i=0;i<C;i++)
	 {
		 total_rsv_pck_num_per_class[i]=0;
	     sum_clk_h2h_per_class[i]=0;
	     sum_clk_h2t_per_class[i]=0;
	 	 sum_clk_per_hop_per_class[i]=0;
#if (STND_DEV_EN)
	 	 sum_clk_pow2_per_class[i]=0;
#endif

	 }  //for
	 total_sent_flit_number=0;


}


 

/***********************
 *
 * 	standard_dev
 *
 * ******************/

#if (STND_DEV_EN)
/************************
 * std_dev = sqrt[(B-A^2/N)/N]  = sqrt [(B/N)- (A/N)^2] = sqrt [B/N - mean^2]
 * A = sum of the values
 * B = sum of the squarded values 
 * *************/

double standard_dev( double sum_pow2, unsigned int  total_num, double average){
	double std_dev;
	
	/*
	double  A, B, N;
	N= total_num;
	A= average * N;
	B= sum_pow2;

	A=(A*A)/N;
	std_dev = (B-A)/N;
	std_dev = sqrt(std_dev);
*/	
	if(total_num==0) return 0;

	std_dev = sum_pow2/(double)total_num; //B/N
	std_dev -= (average*average);// (B/N) - mean^2
	std_dev = sqroot(std_dev);// sqrt [B/N - mean^2]

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
	int c=0;
	int sum=class_percentage[0];
	size_t n = sizeof(class_percentage)/sizeof(class_percentage[0]);
	for(;;){
		if( rnd < sum) return c;
		if( c==n-1 ) return c;
		c++;
		sum+=class_percentage[c];
	}
	return 0;
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
		 return INJECT_OFF; //disable sending
	}

	if(	read(task_graph_data[src],index,&task)==0){
		traffic[src]->ratio=0;
		traffic[src]->stop=1;
		 return INJECT_OFF; //disable sending

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
	//traffic[src]->avg_pck_size_in=task.avg_pck_size;
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
					return INJECT_OFF;
				}
				if(task_graph_abstract[src].active_index>=task_graph_abstract[src].total_index) task_graph_abstract[src].active_index=0;
	}

	return endp_addr_encoder(task.dst);
}






