#ifndef NETRACE_LIB_H
#define NETRACE_LIB_H


#include "netrace-1.0/queue.h"
#include "netrace-1.0/netrace.h"
#include "netrace-1.0/queue.c"
#include "netrace-1.0/netrace.c"


extern int reset,clk;
extern char simulation_done;
extern void connect_clk_reset_start_all(void);
extern void sim_eval_all (void);
extern void topology_connect_all_nodes (void);
extern Vpck_inj        *pck_inj[NE];
extern unsigned int  count_en;
extern unsigned long int main_time;     // Current simulation time
extern int verbosity;




#define L2_LATENCY 8


int ignore_dependencies = 0;
int start_region = 0;
int reader_throttling = 0;
unsigned long long int nt_cycle=0;
unsigned long long int nt_start_cycle=0;

nt_header_t* header;
queue_t** waiting;
queue_t** inject;
queue_t** traverse;
nt_packet_t* trace_packet = NULL;
nt_packet_t* packet = NULL;
int nt_packets_left = 0;


int * traffic_model_mapping;
int pronoc_to_netrace_map [NE];
int pck_injct_in_pck_wr[NE];

unsigned int nt_total_rd_pck=0; // from trace file
unsigned int read_done=0;

typedef struct queue_node queue_node_t;
struct queue_node {
    nt_packet_t* packet;
    unsigned long long int cycle;
};


unsigned long long int calc_packet_timing( nt_packet_t* packet ) {
    
    int n_hops = abs( packet->src -  packet->dst );
    if( n_hops <= 0 ) n_hops = 1;
    return 3*n_hops;
}



void netrace_init( char * tracefile){
    int i=0;
    nt_open_trfile( tracefile );
    if( ignore_dependencies ) {
        nt_disable_dependencies();
        printf("\tDependencies is turned off in tracking cleared packets list\n");
    }
    if( reader_throttling ) {
        printf("\treader throttling is enabled\n");
    }
    nt_print_trheader();
    header = nt_get_trheader();
    nt_seek_region( &header->regions[start_region] );
    for(i = 0; i < start_region; i++ ) {
        nt_cycle += header->regions[i].num_cycles;
    }
    if(nt_cycle){
        printf("\tThe simulation start at region %u and %llu cycle\n",start_region,nt_cycle);
        nt_start_cycle=nt_cycle;
    }

    waiting  = (queue_t**) malloc( NE * sizeof(queue_t*) );
    inject   = (queue_t**) malloc( NE * sizeof(queue_t*) );
    traverse = (queue_t**) malloc( NE * sizeof(queue_t*) );
    if( (waiting == NULL) || (inject == NULL) || (traverse == NULL) ) {
        printf( "ERROR: malloc fail queues\n" );
        exit(0);
    }

    for( i = 0; i < NE; ++i ) {
        waiting[i]  = queue_new();
        inject[i]   = queue_new();
        traverse[i] = queue_new();
    }


    if( !reader_throttling ) {
        trace_packet = nt_read_packet();
    } else if( !ignore_dependencies ) {
        nt_init_self_throttling();
    }

    MIN_PACKET_SIZE = (8*8)/Fpay;
    MAX_PACKET_SIZE = (64*8)/Fpay;
    AVG_PACKET_SIZE=(MIN_PACKET_SIZE+MAX_PACKET_SIZE)/2;// average packet size
    int p=(MAX_PACKET_SIZE-MIN_PACKET_SIZE)+1;
    if(verbosity==1)     printf("\e[?25l"); //To hide the cursor:

}




void netrace_eval(unsigned int eval_num){
    int i;
    unsigned int pronoc_src_id,pronoc_dst_id;

    if((reset==reset_active_high) || (count_en==0))    return;

    if((( nt_cycle > header->num_cycles) || (read_done==1 )) && nt_packets_left==0 )  simulation_done=1;

    // Reset packets remaining check
    nt_packets_left = 0;

    // Get packets for this cycle
    if((end_sim_pck_num == 0 ) || (end_sim_pck_num > nt_total_rd_pck )){
        if( reader_throttling ) {
            nt_packet_list_t* list;
            for( list = nt_get_cleared_packets_list(); list != NULL; list = list->next ) {
                if( list->node_packet != NULL ) {
                    trace_packet = list->node_packet;
                    queue_node_t* new_node = (queue_node_t*) nt_checked_malloc( sizeof(queue_node_t) );
                    new_node->packet = trace_packet;
                    new_node->cycle = (trace_packet->cycle > nt_cycle) ? trace_packet->cycle : nt_cycle;
                    pronoc_src_id=traffic_model_mapping[trace_packet->src];
                    queue_push( inject[pronoc_src_id], new_node, new_node->cycle );
                    nt_total_rd_pck++;
                } else {
                    printf( "ERROR: Malformed packet list" );
                    exit(-1);
                }
            }
            nt_empty_cleared_packets_list();
        } else {
            while( (trace_packet != NULL) && (trace_packet->cycle == nt_cycle) ) {
                // Place in appropriate queue
                queue_node_t* new_node = (queue_node_t*) nt_checked_malloc( sizeof(queue_node_t) );
                new_node->packet = trace_packet;
                new_node->cycle = (trace_packet->cycle > nt_cycle) ? trace_packet->cycle : nt_cycle;
                pronoc_src_id=traffic_model_mapping[trace_packet->src];
                if( ignore_dependencies || nt_dependencies_cleared( trace_packet ) ) {
                    // Add to inject queue
                    queue_push( inject[pronoc_src_id], new_node, new_node->cycle );
                    nt_total_rd_pck++;
                } else {
                    // Add to waiting queue
                    queue_push( waiting[pronoc_src_id], new_node, new_node->cycle );
                    nt_total_rd_pck++;
                }
                // Get another packet from trace
                trace_packet = nt_read_packet();
            }
            if( (trace_packet != NULL) && (trace_packet->cycle < nt_cycle) ) {
                // Error check: Crash and burn
                printf( "ERROR: Invalid trace_packet cycle time: %llu, current cycle: %llu\n", trace_packet->cycle, nt_cycle );
                exit(-1);
            }
        }
    }else {//if ~end_sim_pck_num
        read_done=1;
    }

    if(eval_num<netrace_speed_up-1) {
        nt_cycle++;
        nt_packets_left=1;
        return;
    }


    // Inject where possible (max one per node)
    //header->num_nodes;
    for( i = 0; i < NE; ++i ) {
        nt_packets_left |= !queue_empty( inject[i] );
        //TODO define sent vc policy
        int sent_vc = 0;

        if(pck_inj[i]->pck_injct_in_pck_wr){
            //the wr_pck should be asserted only for single cycle
            pck_inj[i]->pck_injct_in_pck_wr         = 0;
            continue;
        }

        pck_inj[i]->pck_injct_in_pck_wr         = 0;
        if((pck_inj[i]->pck_injct_out_ready & (0x1<<sent_vc)) == 0){
            //This pck injector is not ready yet
            continue;
        }

        queue_node_t* temp_node = (queue_node_t*) queue_peek_front( inject[i] );
        if( temp_node != NULL ) {
            packet = temp_node->packet;
            if( (packet != NULL) && (temp_node->cycle <= nt_cycle) ) {

                if(verbosity>1) {
                    printf( "Inject: %llu ", nt_cycle );
                    nt_print_packet( packet );
                }
                temp_node = (queue_node_t*) queue_pop_front( inject[i] );
                temp_node->cycle = nt_cycle;//injection time
                pronoc_dst_id =  traffic_model_mapping[packet->dst];
                queue_push( traverse[pronoc_dst_id ], temp_node, temp_node->cycle );
                long int ptr_addr = reinterpret_cast<long int> (temp_node);
                int flit_num = (nt_get_packet_size(packet)* 8) / Fpay;
                if(flit_num< pck_inj[i]->min_pck_size) flit_num = pck_inj[i]->min_pck_size;

                if(SELF_LOOP_EN == 0){
                    if(pronoc_dst_id == i ){
                         fprintf(stderr,"ERROR: ProNoC is not configured with self-loop enable and Netrace aims to inject\n a "
                                 "packet with identical source and destination address. Enable the SELF_LOOP parameter\n"
                                 "in ProNoC and rebuild the simulation model\n");
                         exit(1);
                    }
                }
                unsigned int sent_class =0;
                pck_inj[i]->pck_injct_in_data         = ptr_addr;
                pck_inj[i]->pck_injct_in_size         = flit_num;
                pck_inj[i]->pck_injct_in_endp_addr    = endp_addr_encoder(pronoc_dst_id);
                pck_inj[i]->pck_injct_in_class_num    = sent_class;
                pck_inj[i]->pck_injct_in_init_weight  = 1;
                pck_inj[i]->pck_injct_in_vc           = 0x1<<sent_vc;
                pck_inj[i]->pck_injct_in_pck_wr         = 1;
                total_sent_pck_num++;

                #if (C>1)
                    sent_stat[i][sent_class].pck_num ++;
                    sent_stat[i][sent_class].flit_num +=flit_num;
                #else
                    sent_stat[i].pck_num ++;
                    sent_stat[i].flit_num +=flit_num;
                #endif
            }
        }
    }

/*
    // Step all network components, Eject where possible
        for( i = 0; i < header->num_nodes; ++i ) {
            nt_packets_left |= !queue_empty( traverse[i] );
            queue_node_t* temp_node = (queue_node_t*) queue_peek_front( traverse[i] );
            if( temp_node != NULL ) {
                packet = temp_node->packet;
                if( (packet != NULL) && (temp_node->cycle <= nt_cycle) ) {
                    printf( "Eject: %llu ", nt_cycle );
                    nt_print_packet( packet );
                    nt_clear_dependencies_free_packet( packet );
                    temp_node = (queue_node_t*) queue_pop_front( traverse[i] );
                    free( temp_node );
                }
            }
        }
*/

    // Step all network components, Eject where possible
    for( i = 0; i < NE; ++i ) {
        nt_packets_left |= !queue_empty( traverse[i] );
        //check which pck injector got a packet
        if(pck_inj[i]->pck_injct_out_pck_wr==0) continue;
        //we have got a packet
        //printf( "data=%lx\n",pck_inj[i]->pck_injct_out_data);

        queue_node_t* temp_node = (queue_node_t*)  pck_inj[i]->pck_injct_out_data;
        if( temp_node != NULL ) {
            packet = temp_node->packet;
            if( packet != NULL){
                if(verbosity>1) {
                    printf( "Eject: %llu ", nt_cycle );
                    nt_print_packet( packet );
                }
                // remove from traverse
                nt_clear_dependencies_free_packet( packet );
                queue_remove( traverse[i], temp_node );
                unsigned long long int    clk_num_h2t= (nt_cycle - temp_node->cycle)/netrace_speed_up;
                unsigned int    clk_num_h2h= clk_num_h2t - pck_inj[i]->pck_injct_out_h2t_delay;
                /*
                printf("clk_num_h2t (%llu) h2t_delay(%u)\n", clk_num_h2t , pck_inj[i]->pck_injct_out_h2t_delay);
                if(clk_num_h2t < pck_inj[i]->pck_injct_out_h2t_delay){
                    fprintf(stderr, "ERROR:clk_num_h2t (%llu) is smaller than  injector h2t_delay(%u)\n", clk_num_h2t , pck_inj[i]->pck_injct_out_h2t_delay);
                    exit(1);
                }
                */

                pronoc_src_id=traffic_model_mapping[packet->src];
                total_rsv_pck_num++;
                update_statistic_at_ejection (
                    i,//    core_num
                    clk_num_h2h, // clk_num_h2h,
                    (unsigned int) clk_num_h2t, // clk_num_h2t,
                    pck_inj[i]->pck_injct_out_distance, //    distance,
                    pck_inj[i]->pck_injct_out_class_num,//      class_num,
                    pronoc_src_id,//        unsigned int     src
                    pck_inj[i]->pck_injct_out_size
                );

                free( temp_node );

            }
        }
    }
        // Check for cleared dependences... or not
        if( !reader_throttling ) {
        for( i = 0; i < NE; ++i ) {
            nt_packets_left |= !queue_empty( waiting[i] );
            node_t* temp = waiting[i]->head;
            while( temp != NULL ) {
                queue_node_t* temp_node = (queue_node_t*) temp->elem;
                packet = temp_node->packet;
                temp = temp->next;
                if( nt_dependencies_cleared( packet ) ) {
                    // remove from waiting
                    queue_remove( waiting[i], temp_node );
                    // add to inject
                    queue_node_t* new_node = (queue_node_t*) nt_checked_malloc( sizeof(queue_node_t) );
                    new_node->packet = packet;
                    new_node->cycle = nt_cycle + L2_LATENCY;
                    queue_push( inject[i], new_node, new_node->cycle );
                    free( temp_node );
                }
            }
        }
    }
    nt_cycle++;
}


void netrace_posedge_event(){
    unsigned int i;
    clk = 1;       // Toggle clock
    update_all_router_stat();
    for(i=0;i<netrace_speed_up; i++)  netrace_eval(i);
    //connect_clk_reset_start_all();
    sim_eval_all();
    //print total sent packet each 1024 clock cycles
    if(verbosity==1) if(nt_cycle&0x3FF) printf("\rTotal sent packet: %9d", total_sent_pck_num);
}


void netrace_negedge_event( ){
    int i;
    clk = 0;
    topology_connect_all_nodes ();
    //connect_clk_reset_start_all();
    sim_eval_all();
}




void netrace_final_report(){
    int i;
    unsigned int worst_sent=0, worst_rsv=0;
    unsigned long long int total_clock = (nt_cycle-nt_start_cycle);
    unsigned long long int pronoc_total_clock = total_clock/netrace_speed_up;

    if(verbosity==1)     printf("\e[?25h");//To re-enable the cursor:
    printf("\nNetrace simulation results-------------------\n"
            "\tNetrace end clock cycles: %llu\n"
            "\tNetrace duration clock cycles: %llu\n"
            "\tProNoC  duration clock cycles: %llu\n"
            "\tSimulation clock cycles: %llu\n"
    ,nt_cycle,total_clock,pronoc_total_clock,pronoc_total_clock);

    print_statistic_new (pronoc_total_clock);
    printf("Netrace simulation results-------------------\n");
}



#endif
