#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

#include <verilated.h>          // Defines common routines
#include "Vrouter.h"               // From Verilating "router.v"
#include "Vnoc.h"
#include "Vtraffic.h"
#include "parameter.h"



#define  NC		(NX*NY)
#define  RATIO_INIT		5




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
unsigned int  total_router;


char all_done=0;

unsigned int flit_counter =0;

char ratio=RATIO_INIT;
double first_avg_latency_flit,current_avg_latency_flit;

double sc_time_stamp () ;
int pow2( int );
int reset,clk;

#if (STND_DEV_EN)
	#include <math.h>
	double 	     sum_clk_pow2=0;
	double 	     sum_clk_pow2_per_class[C]={0};
	double standard_dev( double , unsigned int, double);
#endif

void update_noc_statistic (
		char 			,
		char 			,
        unsigned int   	,
		unsigned int	,
        unsigned int    ,
        unsigned int
);


void print_statistic (char *);
void print_parameter();
void update_throughput (
		char,
		char ,
       unsigned int,
       unsigned int
      );

void reset_all_register();
int update_ratio();



int main(int argc, char** argv) {
	char change_injection_ratio=0,inject_done;
	int i,j,x,y;//,report_delay_counter=0;
	char file_name[100];
	char deafult_out[] = {"result"};
	char * out_file_name;

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

	
	//initialize input
	for(x=0;x<NX;x++)for(y=0;y<NY;y++){
					i=(y*NX)+x;
					router[i]->current_x		= x;
					router[i]->current_y		= y;
					traffic[i]->current_x		= x;
					traffic[i]->current_y		= y;

	}
	
	reset=1;
	reset_all_register();

	for(i=0;i<NC;i++){
		traffic[i]->start=0;
		traffic[i]->pck_size=PACKET_SIZE;
		traffic[i]->ratio=ratio;

	}


	main_time=0;
	print_parameter();
	printf("\n\n\n Flit injection ratio per router is =%d \n",ratio);
	//printf("\n\n\n delay= %u clk",router->delay);
	while (!Verilated::gotFinish()) {
	   
		if (main_time-saved_time >= 10 ) {
			reset = 0;   // Deassert reset
		}

		if(main_time == saved_time+21){ count_en=1; for(i=0;i<NC;i++) traffic[i]->start=1;}
		if(main_time == saved_time+26) for(i=0;i<NC;i++) traffic[i]->start=0;
		if(change_injection_ratio==1 && clk == 0 ){
			change_injection_ratio=0;
			//report_delay_counter=0;
			saved_time=main_time;
			reset=1;
			reset_all_register();
			char buff[20];
			sprintf(buff,"ratio_%d.v",ratio);
			rename( "Result.txt", buff);
			if(update_ratio()){ printf("\n\nEnd of simulation!\n");return 0;}
			for(i=0;i<NC;i++) traffic[i]->ratio=ratio;
			printf("\n\n\n Flit injection ratio per router is =%d \n",ratio);



		}
		
		if ((main_time % 4) == 0) {
			//getchar();
			clk = 1;       // Toggle clock
			//printf("\nclock cycle:%d",cycle++);
			//all_done=1;
			if(count_en) clk_counter++;
			inject_done= ((total_pck_num >= MAX_PCK_NUM) || (clk_counter>= MAX_SIM_CLKs));
			//if(inject_done) printf("clk_counter=========%d\n",clk_counter);
			for(x=0;x<NX;x++)for(y=0;y<NY;y++)
			{
				i=(y*NX)+x;


				update_noc_statistic (
						reset,
						traffic[i]->update,
						traffic[i]->time_stamp_h2h,
						traffic[i]->time_stamp_h2t,
						traffic[i]->distance,
						traffic[i]->msg_class
				) ;


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
		else {//((main_time % 2) == 1) {
			//router->request=0xFF;	//change input
			clk = 0;
			//printf("\n router->request= %u",router->request);
			noc->ni_flit_in_wr =0;
			for(x=0;x<NX;x++)for(y=0;y<NY;y++){
				i=(y*NX)+x;


				router[i]->flit_in_we_all	= noc->router_flit_out_we_all[i];
				router[i]->credit_in_all	= noc->router_credit_out_all[i];
				router[i]->congestion_in_all	= noc->router_congestion_out_all[i];
				for(j=0;j<6;j++)router[i]->flit_in_all[j] 	= noc->router_flit_out_all[i][j];


				noc->router_flit_in_we_all[i]	=	router[i]->flit_out_we_all ;
				noc->router_credit_in_all[i]	=	router[i]->credit_out_all;
				noc->router_congestion_in_all[i]=	router[i]->congestion_out_all;
				for(j=0;j<6;j++) noc->router_flit_in_all[i][j]	= router[i]->flit_out_all[j] ;

				traffic[i]->flit_in  = noc->ni_flit_out [i];
				traffic[i]->credit_in= noc->ni_credit_out[i];
			

				noc->ni_credit_in[i] = traffic[i]->credit_out;
				noc->ni_flit_in [i]  = traffic[i]->flit_out;

				if(traffic[i]->flit_out_wr) noc->ni_flit_in_wr = noc->ni_flit_in_wr | ((vluint64_t)1<<i);

				traffic[i]->flit_in_wr= ((noc->ni_flit_out_wr >> i) & 0x01);

			
			}//for
		

		}
		//if(main_time > 20 && main_time < 30 ) traffic->start=1; else traffic->start=0;
		//if(main_time == saved_time+25) router[0]->flit_in_we_all=0;
		//if((main_time % 250)==0) printf("router->all_done =%u\n",router->all_done);
		
		
		noc-> clk = clk; 
		

		 
		for(i=0;i<NC;i++)	{
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
		char 			reset,
		char 			update,
        unsigned int   	clk_num_h2h,
		unsigned int    clk_num_h2t,
        unsigned int    distance,
        unsigned int  	class_num
)
	{
	if(update & ~reset)
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


	}

/*************************
 *
 *		update_throughput
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
	                printf(" Total number of packet = %d \n average latency per hop = %f \n average latency = %f\n",total_pck_num,avg_latency_per_hop,avg_latency_flit);
	                update_file(file_name ,avg_throughput,avg_latency_flit);
}else{
	                printf(" Total number of packet = %d \n average latency per hop = %f \n average latency = %f\n",total_pck_num,avg_latency_per_hop,avg_latency_pck);
	                update_file(file_name ,avg_throughput,avg_latency_pck);
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
	                    printf	(" Total number of packet  = %d \n avg_throughput = %f \n average latency per hop = %f \n average latency = %f\n",total_pck_num_per_class[i],avg_throughput,avg_latency_per_hop,avg_latency_flit);
	                    sprintf(file_name,"%s_c%u.txt",out_file_name,i);
	                    update_file( file_name,avg_throughput,avg_latency_flit );
}else{
	                    printf	 ("\nclass : %d  \n",i);
	                    printf	(" Total number of packet  = %d \n avg_throughput = %f \n average latency per hop = %f \n average latency = %f\n",total_pck_num_per_class[i],avg_throughput,avg_latency_per_hop,avg_latency_pck);
   	                    sprintf(file_name,"%s_c%u.txt",out_file_name,i);
   	                    update_file( file_name,avg_throughput,avg_latency_pck );

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
#if(DEBUG_EN)
	    printf ("\tDebuging is enabled\n");
#else
	    printf ("\tDebuging is disabled\n");
#endif

	printf ("Simulation parameters\n");
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
		printf ("\t Simulation timeout =%d\n", MAX_SIM_CLKs);
		printf ("\t Simulation ends on total packet num of =%d\n", MAX_PCK_NUM);
	    printf ("\tPacket size: %u flits\n",PACKET_SIZE);
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
	else if(current_avg_latency_flit <= (6*first_avg_latency_flit)) ratio+=1;
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

