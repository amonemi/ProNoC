#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

#include <verilated.h>          // Defines common routines
#include "Vrouter.h"               // From Verilating "router.v"
#include "Vnoc.h"
#include "Vtraffic.h"




#include "parameter.h"
//#include "traffic_tabel.h"


#define  NC		(NX*NY)
#define  RATIO_INIT		2

unsigned char FIXED_SRC_DST_PAIR;

unsigned char  Xw=0,Yw=0;




//Vrouter *router;
Vrouter			*router[NC];                     // Instantiation of module
Vnoc		 	*noc;
Vtraffic		*traffic[NC];

unsigned long int main_time = 0;     // Current simulation time
unsigned int saved_time = 0; 


unsigned int total_pck_num=0;
unsigned int sum_clk_h2h,sum_clk_h2t;

double 		 sum_clk_per_hop;
unsigned int total_pck_num_per_class[C]={0};
unsigned int sum_clk_h2h_per_class[C]={0};
unsigned int sum_clk_h2t_per_class[C]={0};
double 		 sum_clk_per_hop_per_class[C]={0};
unsigned int clk_counter;
unsigned int count_en;
unsigned int total_router;


char all_done=0;

unsigned int flit_counter =0;

char ratio=RATIO_INIT;
double first_avg_latency_flit,current_avg_latency_flit;

double sc_time_stamp ();
int pow2( int );



int reset,clk;

#if (STND_DEV_EN)
	#include <math.h>
	double 	     sum_clk_pow2=0;
	double 	     sum_clk_pow2_per_class[C]={0};
	double standard_dev( double , unsigned int, double);
#endif

void update_noc_statistic (
	unsigned int,
	unsigned int,
    unsigned int,
    unsigned int
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
int update_ratio();





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
	FIXED_SRC_DST_PAIR = strcmp (TRAFFIC,"RANDOM") &  strcmp(TRAFFIC,"HOTSPOT") & strcmp(TRAFFIC,"TABEL");


	if(argc == 2)   out_file_name= argv[1];
	else 		  out_file_name= deafult_out;
	//printf("argc=%u\n",argc);
	//remove old files
	sprintf(file_name,"%s_all.txt",out_file_name);
	remove("result_all.txt");
	for(i=0;i<C;i++){
		sprintf(file_name,"%s_c%u.txt",out_file_name,i);
		remove(file_name);
	}


	Verilated::commandArgs(argc, argv);   // Remember args
	
	for(i=0;i<NC;i++)	router[i] 	= new Vrouter;             // Create instance
	noc								= new Vnoc;
	for(i=0;i<NC;i++)	traffic[i]  = new Vtraffic;

	
	/********************
	*	initialize input
	*********************/

	reset=1;
	reset_all_register();
	noc->start_i=0;

	for(x=0;x<NX;x++)for(y=0;y<NY;y++){
					i=(y*NX)+x;
					router[i]->current_x		= x;
					router[i]->current_y		= y;
					traffic[i]->current_x		= x;
					traffic[i]->current_y		= y;
					traffic[i]->start=0;
					traffic[i]->pck_size_in=PACKET_SIZE;
					traffic[i]->avg_pck_size_in=PACKET_SIZE;
					traffic[i]->ratio=ratio;
					traffic[i]->pck_class_in=  pck_class_in_gen( i);
					pck_dst_gen ( x,y,i, &dest_x, &dest_y);
					traffic[i]->dest_x= dest_x;
					traffic[i]->dest_y=dest_y;
					traffic[i]->stop=0;

	}
	



	main_time=0;
	print_parameter();
	printf("\n\n\n Flit injection ratio per router is =%d \n",ratio);
	//printf("\n\n\n delay= %u clk",router->delay);
	while (!Verilated::gotFinish()) {
	   
		if (main_time-saved_time >= 10 ) {
			reset = 0;
		}

		if(main_time == saved_time+21){ count_en=1; noc->start_i=1;}//for(i=0;i<NC;i++) traffic[i]->start=1;}
		if(main_time == saved_time+26) noc->start_i=0;// for(i=0;i<NC;i++) traffic[i]->start=0;
		if(change_injection_ratio==1 && clk == 0 ){
			change_injection_ratio=0;
			saved_time=main_time;
			reset=1;
			reset_all_register();
			if(update_ratio()){ printf("\n\nEnd of simulation!\n");return 0;}
			for(i=0;i<NC;i++) traffic[i]->ratio=ratio;
			printf("\n\n\n Flit injection ratio per router is =%d \n",ratio);
		}
		


		if ((main_time % 4) == 0) {
			clk = 1;       // Toggle clock
			if(count_en) clk_counter++;
			inject_done= ((total_pck_num >= MAX_PCK_NUM) || (clk_counter>= MAX_SIM_CLKs));
			//if(inject_done) printf("clk_counter=========%d\n",clk_counter);
			for(x=0;x<NX;x++)for(y=0;y<NY;y++)
			{
				i=(y*NX)+x;
				// a packet has been received
				if(traffic[i]->update & ~reset){
					update_noc_statistic (
						traffic[i]->time_stamp_h2h,
						traffic[i]->time_stamp_h2t,
						traffic[i]->distance,
						traffic[i]->pck_class_out
					) ;
				}
				// the header flit has been sent out
				if(traffic[i]->hdr_flit_sent ){
					traffic[i]->pck_class_in=  pck_class_in_gen( i);
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
				for(j=0;j<flit_out_all_size;j++)router[i]->flit_in_all[j] 	= noc->router_flit_out_all[i][j];


				noc->router_flit_in_we_all[i]	=	router[i]->flit_out_we_all ;
				noc->router_credit_in_all[i]	=	router[i]->credit_out_all;
				noc->router_congestion_in_all[i]=	router[i]->congestion_out_all;
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
		unsigned int   	clk_num_h2h,
		unsigned int    clk_num_h2t,
        unsigned int    distance,
        unsigned int  	class_num
)
{


        		total_pck_num+=1;
        		//if((total_pck_num & 0Xffff )==0 ) printf("total_pck_num=%d\n",total_pck_num);
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




	}

/*************************
 *
 *		update
 *
 *
 ************************/








void update_file( char * fp,double ratio, double avg_latency ){
	FILE * out;
	out = fopen (fp,"a");
	if(out==NULL) {printf("can not update %s file", fp); return;}
	fprintf(out,"%f %f\n",ratio,avg_latency);
	fclose(out);
}



void print_statistic (char * out_file_name){
	double avg_latency_per_hop,  avg_latency_flit, avg_latency_pck, avg_throughput,min_avg_latency_per_class;
	int i;
#if (STND_DEV_EN)
	double	std_dev;
#endif
					char file_name[100];
					avg_throughput= ((double)(total_pck_num*PACKET_SIZE*100)/total_router )/clk_counter;
					printf(" Total active routers: %d \n",total_router);
					printf(" Avg throughput is: %f (flits/clk/node %%)\n",    avg_throughput);
	                avg_latency_flit   = (double)sum_clk_h2h/total_pck_num;
	                avg_latency_pck	   = (double)sum_clk_h2t/total_pck_num;
	                if(ratio==RATIO_INIT) first_avg_latency_flit=avg_latency_flit;
#if (STND_DEV_EN)
	                std_dev= standard_dev( sum_clk_pow2,total_pck_num, avg_latency_flit);
	                sprintf(file_name,"%s_std.txt",out_file_name);
	                update_file( file_name,avg_throughput,std_dev);

#endif
	                avg_latency_per_hop    = (double)sum_clk_per_hop/total_pck_num;
	                printf	 ("\nall : \n");
	                sprintf(file_name,"%s_all.txt",out_file_name);
	                //update_file(file_name ,ratio,avg_latency );
if(strcmp (AVG_LATENCY_METRIC,"HEAD_2_TAIL")==0){
		  	printf(" Total number of packet = %d \n average latency per hop = %f \n average latency = %f\n",total_pck_num,avg_latency_per_hop,avg_latency_pck);
	                update_file(file_name ,avg_throughput,avg_latency_pck);
	               
}else{
			 printf(" Total number of packet = %d \n average latency per hop = %f \n average latency = %f\n",total_pck_num,avg_latency_per_hop,avg_latency_flit);
	                update_file(file_name ,avg_throughput,avg_latency_flit);
	              
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
   	                    sprintf(file_name,"%s_c%u.txt",out_file_name,i);
   	                    update_file( file_name,avg_throughput,avg_latency_pck );
}else{

printf	 ("\nclass : %d  \n",i);
	                    printf	(" Total number of packet  = %d \n avg_throughput = %f \n average latency per hop = %f \n average latency = %f\n",total_pck_num_per_class[i],avg_throughput,avg_latency_per_hop,avg_latency_flit);
	                    sprintf(file_name,"%s_c%u.txt",out_file_name,i);
	                    update_file( file_name,avg_throughput,avg_latency_flit );


	                   

}
	                    if(min_avg_latency_per_class > avg_latency_flit) min_avg_latency_per_class=avg_latency_flit;

#if (STND_DEV_EN)
	                    std_dev= (total_pck_num_per_class[i]>0)?  standard_dev( sum_clk_pow2_per_class[i],total_pck_num_per_class[i], avg_latency_flit):0;
	                    sprintf(file_name,"%s_std%u.txt",out_file_name,i);
	                    update_file( file_name,avg_throughput,std_dev);

#endif


	                 }//for
	                current_avg_latency_flit=min_avg_latency_per_class;




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




	printf ("Simulation parameters\n");
#if(DEBUG_EN)
	    printf ("\tDebuging is enabled\n");
#else
	    printf ("\tDebuging is disabled\n");
#endif
	if(strcmp (AVG_LATENCY_METRIC,"HEAD_2_TAIL")==0)printf ("\tOutput is the average latency on sending the packet head until receiving tail\n");
	else printf ("\tOutput is the average latency on sending the packet head until receiving the head\n");
	printf ("\tTraffic pattern:%s\n",TRAFFIC);
	if(C>0) printf ("\ttraffic percentage of class 0 is : %d\n", C0_p);
	if(C>1) printf ("\ttraffic percentage of class 1 is : %d\n", C1_p);
	if(C>2) printf ("\ttraffic percentage of class 2 is : %d\n", C2_p);
	if(C>3) printf ("\ttraffic percentage of class 3 is : %d\n", C3_p);
	if(strcmp (TRAFFIC,"HOTSPOT")==0){
		printf ("\tHot spot percentage: %u\n", HOTSPOT_PERCENTAGE);
	    printf ("\tNumber of hot spot cores: %d\n", HOTSOPT_NUM);

	}
	    //printf ("\tTotal packets sent by one router: %u\n", TOTAL_PKT_PER_ROUTER);
		printf ("\tSimulation timeout =%d\n", MAX_SIM_CLKs);
		printf ("\tSimulation ends on total packet num of =%d\n", MAX_PCK_NUM);
	    printf ("\tPacket size: %u flits\n",PACKET_SIZE);
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



/*******************************
 *
 *			update_ratio()
 *
 * *****************************/

int update_ratio(){
	//printf("current_avg_latency=%f\n",current_avg_latency_flit);
	if(current_avg_latency_flit <= (2*first_avg_latency_flit)) ratio+=2;
	else if(current_avg_latency_flit <= (4*first_avg_latency_flit)) ratio+=1;
	else return 1;
	return 0;
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
	int i;


	if(strcmp (TRAFFIC,"RANDOM")==0){

		do{
			rnd=rand()%nc;
		}while (rnd==core_num); // get a random IP core, make sure its not same as sender core

       (*dest_y) = (rnd / NX );
	   (*dest_x) = (rnd % NX );


	}
	else if (strcmp(TRAFFIC,"HOTSPOT")==0) {

		do{
				rnd=rand()%nc;
		}while (rnd==core_num); // get a random IP core, make sure its not same as sender core

		rnd100=rand()%100;

		if		(rnd100 < HOTSPOT_PERCENTAGE	&& core_num !=HOTSPOT_CORE_1 )	rnd = HOTSPOT_CORE_1;
		else if((HOTSOPT_NUM > 1)	&& (rnd100 >= 20 )	&& (rnd100 < (20+HOTSPOT_PERCENTAGE)) && core_num!=HOTSPOT_CORE_2 )  rnd = HOTSPOT_CORE_2;
		else if((HOTSOPT_NUM > 2)	&& (rnd100 >= 40)	&& (rnd100 < (40+HOTSPOT_PERCENTAGE)) && core_num!=HOTSPOT_CORE_3 )  rnd = HOTSPOT_CORE_3;
		else if((HOTSOPT_NUM > 3)	&& (rnd100 >= 60)	&& (rnd100 < (60+HOTSPOT_PERCENTAGE)) && core_num!=HOTSPOT_CORE_4 )  rnd = HOTSPOT_CORE_4;
		else if((HOTSOPT_NUM > 4)	&& (rnd100 >= 80)	&& (rnd100 < (80+HOTSPOT_PERCENTAGE)) && core_num!=HOTSPOT_CORE_5 )  rnd = HOTSPOT_CORE_5;



		 (*dest_y) = (rnd / NX );
		 (*dest_x) = (rnd % NX );


	} else if( strcmp(TRAFFIC ,"TRANSPOSE1")==0){

		 (*dest_x) = NX-current_y-1;
		 (*dest_y) = NY-current_x-1;



	} else if( strcmp(TRAFFIC ,"TRANSPOSE2")==0){
		(*dest_x)   = current_y;
		(*dest_y)   = current_x;


	} else if( strcmp(TRAFFIC ,"BIT_REVERSE")==0){
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




	 } else if( strcmp(TRAFFIC ,"BIT_COMPLEMENT") ==0){

		 (*dest_x)    = (~current_x) &(0xFF>> (8-Xw));
		 (*dest_y)    = (~current_y) &(0xFF>> (8-Yw));


     }  else if( strcmp(TRAFFIC ,"TORNADO") == 0){
		//[(x+(k/2-1)) mod k, (y+(k/2-1)) mod k],
		 (*dest_x)    = ((current_x + ((NX/2)-1))%NX);
		 (*dest_y)    = ((current_y + ((NY/2)-1))%NY);


     }  else if( strcmp(TRAFFIC ,"CUSTOM") == 0){
		//[(x+(k/2-1)) mod k, (y+(k/2-1)) mod k],
		if(current_x ==0 && current_y == 0 ){
		 (*dest_x)    =  NX-1;
		 (*dest_y)    =  NY-1;
		}else{// make it unvalid
		 (*dest_x)    =  current_x;
		 (*dest_y)    =  current_y;

		}

     }  

	 else printf ("traffic %s is an unsupported traffic pattern\n",TRAFFIC);

}




void pck_dst_gen_1D (
    unsigned int current_x,
	unsigned int core_num,
	unsigned int *dest_x

){


	unsigned int rnd=0,nc=NX;
	unsigned int rnd100=0;
	int i;


	if(strcmp (TRAFFIC,"RANDOM")==0){

		do{
			rnd=rand()%nc;
		}while (rnd==core_num); // get a random IP core, make sure its not same as sender core

	   (*dest_x) = (rnd % NX );


	}
	else if (strcmp(TRAFFIC,"HOTSPOT")==0) {

		do{
				rnd=rand()%nc;
		}while (rnd==core_num); // get a random IP core, make sure its not same as sender core

		rnd100=rand()%100;

		if		(rnd100 < HOTSPOT_PERCENTAGE	&& core_num !=HOTSPOT_CORE_1 )	rnd = HOTSPOT_CORE_1;
		else if((HOTSOPT_NUM > 1)	&& (rnd100 >= 20 )	&& (rnd100 < (20+HOTSPOT_PERCENTAGE)) && core_num!=HOTSPOT_CORE_2 )  rnd = HOTSPOT_CORE_2;
		else if((HOTSOPT_NUM > 2)	&& (rnd100 >= 40)	&& (rnd100 < (40+HOTSPOT_PERCENTAGE)) && core_num!=HOTSPOT_CORE_3 )  rnd = HOTSPOT_CORE_3;
		else if((HOTSOPT_NUM > 3)	&& (rnd100 >= 60)	&& (rnd100 < (60+HOTSPOT_PERCENTAGE)) && core_num!=HOTSPOT_CORE_4 )  rnd = HOTSPOT_CORE_4;
		else if((HOTSOPT_NUM > 4)	&& (rnd100 >= 80)	&& (rnd100 < (80+HOTSPOT_PERCENTAGE)) && core_num!=HOTSPOT_CORE_5 )  rnd = HOTSPOT_CORE_5;



		// (*dest_y) = (rnd / NX );
		 (*dest_x) = (rnd % NX );


	} else if( strcmp(TRAFFIC ,"TRANSPOSE1")==0){

		 (*dest_x) = NX-current_x-1;
		// (*dest_y) = NY-current_x-1;



//	} else if( strcmp(TRAFFIC ,"TRANSPOSE2")==0){
	//	(*dest_x)   = current_y;
	//	(*dest_y)   = current_x;


	} else if( strcmp(TRAFFIC ,"BIT_REVERSE")==0){

		unsigned int reverse_addr=0;
		unsigned int pos=0;
		for(i=0; i<(Xw); i++){//reverse the address
			 pos= (((Xw)-1)-i);
			 reverse_addr|= ((current_x >> pos) & 0x01) << i;
                   // reverse_addr[i]  = joint_addr [((Xw+Yw)-1)-i];
		}
		(*dest_x)   = reverse_addr;

	} else if( strcmp(TRAFFIC ,"BIT_COMPLEMENT") ==0){

		 (*dest_x)    = (~current_x) &(0xFF>> (8-Xw));
		 //(*dest_y)    = (~current_y) &(0xFF>> (8-Yw));


     }  else if( strcmp(TRAFFIC ,"TORNADO") == 0){
		//[(x+(k/2-1)) mod k, (y+(k/2-1)) mod k],
		 (*dest_x)    = ((current_x + ((NX/2)-1))%NX);
		// (*dest_y)    = ((current_y + ((NY/2)-1))%NY);


     }  else if( strcmp(TRAFFIC ,"CUSTOM") == 0){
		//[(x+(k/2-1)) mod k, (y+(k/2-1)) mod k],
		if(current_x ==0  ){
		 (*dest_x)    =  NX-1;
		// (*dest_y)    =  NY-1;
		}else{// make it invalid
		 (*dest_x)    =  current_x;
		 //(*dest_y)    =  current_y;

		}

     }

	 else printf ("traffic %s is an unsupported traffic pattern\n",TRAFFIC);

}





void pck_dst_gen (
    unsigned int current_x,
	unsigned int current_y,
	unsigned int core_num,
	unsigned int *dest_x,
	unsigned int *dest_y
){
	if((strcmp (TOPOLOGY,"MESH")==0)||(strcmp (TOPOLOGY,"TORUS")==0)){
		pck_dst_gen_2D (
		    current_x,
			current_y,
			core_num,
			dest_x,
			dest_y
		);
	}
	else {
		dest_y=0;
		pck_dst_gen_1D (
				current_x,
				core_num,
				dest_x
		);

	}
}








