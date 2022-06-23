#ifndef _SYNFUL_WRAPPER_H
	#define  _SYNFUL_WRAPPER_H


#include <iostream>

#include "synful/synful.h"

bool synful_SSExit;
int  synful_random_seed=53432145;
int  synful_packets_left = 0;
int  synful_flitw =4;

extern queue_t** synful_inject;
       queue_t** synful_traverse;





void synful_init(char * fname, bool ss_exit, int seed,unsigned int max_clk, unsigned int max_pck){
	//std::cout << "Initiating synful with: " << fname << "random seed:" << seed << std::endl;
    synful_model_init(fname, ss_exit,seed,max_clk, max_pck, traffic_model_mapping );

 	synful_inject   = (queue_t**) malloc( NE * sizeof(queue_t*) );
 	synful_traverse = (queue_t**) malloc( NE * sizeof(queue_t*) );

 	if(synful_inject == NULL || synful_traverse == NULL ) {
		printf( "ERROR: malloc fail queues\n" );
		exit(0);
	}
	for(int i = 0; i <  NE; ++i ) {
		synful_inject[i]     = queue_new();
		synful_traverse[i]   = queue_new();
	}
}


void synful_final_report(){
	int i;

	if(verbosity==1) 	printf("\e[?25h");//To re-enable the cursor:
	printf("\nSynful simulation results-------------------\n"
			"\tSimulation clock cycles: %llu\n"
	,synful_cycle);
	print_statistic_new (synful_cycle);
}



void synful_eval( ){
	int i;
	unsigned int pronoc_src_id,pronoc_dst_id;

	if((reset==1) || (count_en==0))	return;

	if((( synful_cycle > sim_end_clk_num) || (total_sent_pck_num>= end_sim_pck_num )) && synful_packets_left==0 )  simulation_done=1;

	// Reset packets remaining check
	synful_packets_left = 0;

	synful_run_one_cycle ();


	// Inject where possible (max one per node)
	for( i = 0; i < NE; ++i ) {
		synful_packets_left |= !queue_empty( synful_inject[i] );

		//TODO define sent vc policy
		int sent_vc = 0;

		if(pck_inj[i]->pck_injct_in_pck_wr){
			//the wr_pck should be asserted only for single cycle
			pck_inj[i]->pck_injct_in_pck_wr  	   = 0;
			continue;
		}

		pck_inj[i]->pck_injct_in_pck_wr  	   = 0;
		if((pck_inj[i]->pck_injct_out_ready & (0x1<<sent_vc)) == 0){
			//This pck injector is not ready yet
			continue;
		}

		pronoc_pck_t* temp_node = (pronoc_pck_t*) queue_peek_front( synful_inject[i] );
		if( temp_node != NULL ) {
			if(verbosity>1) {
				printf( "Inject: %llu ", synful_cycle );
				synful_print_packet( temp_node );
			}
			temp_node = (pronoc_pck_t*) queue_pop_front( synful_inject[i] );

			pronoc_dst_id =  traffic_model_mapping[temp_node->dest];
			queue_push( synful_traverse[pronoc_dst_id], temp_node, synful_cycle );
			int flit_num =  temp_node->packetSize / synful_flitw ;
			if (flit_num*synful_flitw !=temp_node->packetSize) flit_num++;
			if (flit_num < pck_inj[i]->min_pck_size) flit_num = pck_inj[i]->min_pck_size;

			if(IS_SELF_LOOP_EN ==0){
				if(pronoc_dst_id == i ){
					 fprintf(stderr,"ERROR: ProNoC is not configured with self-loop enable and Netrace aims to inject\n a "
							 "packet with identical source and destination address. Enable the SELF_LOOP parameter\n"
							 "in ProNoC and rebuild the simulation model\n");
					 exit(1);
				}
			}

			unsigned int sent_class =0;
			long int ptr_addr = reinterpret_cast<long int> (temp_node);
			pck_inj[i]->pck_injct_in_data         = ptr_addr;
			pck_inj[i]->pck_injct_in_size         = flit_num;
			pck_inj[i]->pck_injct_in_endp_addr    = endp_addr_encoder(pronoc_dst_id);
			pck_inj[i]->pck_injct_in_class_num    = sent_class;
			pck_inj[i]->pck_injct_in_init_weight  = 1;
			pck_inj[i]->pck_injct_in_vc           = 0x1<<sent_vc;
			pck_inj[i]->pck_injct_in_pck_wr  	   = 1;
			total_sent_pck_num++;

			#if (C>1)
				sent_stat[i][sent_class].pck_num ++;
				sent_stat[i][sent_class].flit_num +=flit_num;
			#else
				sent_stat[i].pck_num ++;
				sent_stat[i].flit_num +=flit_num;
			#endif
		}//temp!=NULL
	}//inject



	// Step all network components, Eject where possible
	for( i = 0; i < NE; ++i ) {
		synful_packets_left |= !queue_empty( synful_traverse[i] );
		//check which pck injector got a packet
		if(pck_inj[i]->pck_injct_out_pck_wr==0) continue;
		//we have got a packet
		//printf( "data=%lx\n",pck_inj[i]->pck_injct_out_data);

		pronoc_pck_t* temp_node = (pronoc_pck_t*)  pck_inj[i]->pck_injct_out_data;
		if( temp_node != NULL ) {
			if(verbosity>1) {
				printf( "Eject: %llu ", synful_cycle );
				synful_print_packet(temp_node);
			}
			//send it to synful
			synful_Eject (temp_node);

			// remove from traverse

			queue_remove( synful_traverse[i], temp_node );
			unsigned long long int    clk_num_h2t= (synful_cycle - temp_node->cycle);
			unsigned int    clk_num_h2h= clk_num_h2t - pck_inj[i]->pck_injct_out_h2t_delay;
			/*
				printf("clk_num_h2t (%llu) h2t_delay(%u)\n", clk_num_h2t , pck_inj[i]->pck_injct_out_h2t_delay);
				if(clk_num_h2t < pck_inj[i]->pck_injct_out_h2t_delay){
					fprintf(stderr, "ERROR:clk_num_h2t (%llu) is smaller than  injector h2t_delay(%u)\n", clk_num_h2t , pck_inj[i]->pck_injct_out_h2t_delay);
					exit(1);
				}
			*/
			pronoc_src_id=traffic_model_mapping[temp_node->source];
			update_statistic_at_ejection (
					i,//	core_num
					clk_num_h2h, // clk_num_h2h,
					(unsigned int) clk_num_h2t, // clk_num_h2t,
					pck_inj[i]->pck_injct_out_distance, //    distance,
					pck_inj[i]->pck_injct_out_class_num,//  	class_num,
					pronoc_src_id, //temp_node->source
					pck_inj[i]->pck_injct_out_size
			);

				free( temp_node );

		}//emp_node != NULL
	}//for

	synful_cycle++;

	//std::cout << synful_cycle << std::endl;

}





void synful_negedge_event( ){
	int i;
	clk = 0;
	topology_connect_all_nodes ();
	//connect_clk_reset_start_all();
	sim_eval_all();
}

void synful_posedge_event(){
	unsigned int i;
	clk = 1;       // Toggle clock
	update_all_router_stat();
	synful_eval();
	//connect_clk_reset_start_all();
	sim_eval_all();
	//print total sent packet each 1024 clock cycles
	if(verbosity==1) if(synful_cycle&0x3FF) printf("\rTotal sent packet: %9d", total_sent_pck_num);
}





#endif
