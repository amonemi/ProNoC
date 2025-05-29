
#ifndef SIMULATOR_H
    #define  SIMULATOR_H

#if (__cplusplus > 201103L) //"C++11\n";

    void* operator new(std::size_t size, std::align_val_t align) {
    #if defined(_WIN32) || defined(__CYGWIN__)
        auto ptr = _aligned_malloc(size, static_cast<std::size_t>(align));
    #else
        auto ptr = aligned_alloc(static_cast<std::size_t>(align), size);
    #endif

        if (!ptr)
            throw std::bad_alloc{};
    /*
        std::cout << "new: " << size << ", align: "
                  << static_cast<std::size_t>(align)
                  << ", ptr: " << ptr << '\n';
    */
        return ptr;

    }

    void operator delete(void* ptr, std::size_t size, std::align_val_t align) noexcept {
    /*
        std::cout << "delete: " << size << ", align: "
                  << static_cast<std::size_t>(align)
                  << ", ptr : " << ptr << '\n';
    */
    #if defined(_WIN32) || defined(__CYGWIN__)
        _aligned_free(ptr);
    #else
        free(ptr);
    #endif
    }

    void operator delete(void* ptr, std::align_val_t align) noexcept {
      /*  std::cout << "delete: align: "
                  << static_cast<std::size_t>(align)
                  << ", ptr : " << ptr << '\n';
      */
    #if defined(_WIN32) || defined(__CYGWIN__)
        _aligned_free(ptr);
    #else
        free(ptr);
    #endif
    }

#endif


#define xstr(s) str(s)
#define str(s) #s


//traffic type
#define SYNTHETIC 0
#define TASK      1
#define NETRACE   2
#define SYNFUL    3

//injector type
#define PCK_INJECTOR    0
#define TRFC_INJECTOR     1

#define STND_DEV_EN 1


int TRAFFIC_TYPE=SYNTHETIC;
int ENDP_TYPE   =TRFC_INJECTOR;


   
int get_router_num (int , int );
    


    #define ideal_port router_top_v__DOT__router__DOT__router_is_ideal
    #define active_port router_top_v__DOT__router__DOT__nb_router_active
    #define pck_active_port  packet_injector_verilator__DOT__endp_is_active
    #define traffic_active_port traffic_gen_top__DOT__endp_is_active

    #define CHAN_SIZE   sizeof(router1[0]->chan_in[0])

    #define conect_r2r(T1,r1,p1,T2,r2,p2)  \
        memcpy(&router##T1 [r1]->chan_in[p1] , &router##T2 [r2]->chan_out[p2], CHAN_SIZE )

//        router_is_active[get_router_num(T1,r1)] |=(( router##T1 [r1]-> ideal_port!=0) |  (router##T2 [r2]-> active_port[p2]==1))

    #define connect_r2gnd(T,r,p)\
        memset(&router##T [r]->chan_in [p],0x00,CHAN_SIZE);


    #define connect_r2e(T,r,p,e) \
        void * addr1, * addr2;\
        addr1=(ENDP_TYPE == PCK_INJECTOR)? &pck_inj[e]->chan_out  : &traffic[e]->chan_out;\
        addr2=(ENDP_TYPE == PCK_INJECTOR)? &pck_inj[e]->chan_in  : &traffic[e]->chan_in;\
        memcpy(&router##T [r]->chan_in[p], addr1, CHAN_SIZE );\
        memcpy(addr2, &router##T [r]->chan_out[p], CHAN_SIZE )





//        router_is_active[get_router_num(T,r)] |= (ENDP_TYPE == PCK_INJECTOR)? \
            (( router##T [r]-> ideal_port!=0) |  (pck_inj[e]->pck_active_port==1)):\
            (( router##T [r]-> ideal_port!=0) |  (traffic[e]->traffic_active_port==1))

#define IS_SELF_LOOP_EN   SELF_LOOP_EN
#define IS_UNICAST        (strcmp(CAST_TYPE,"UNICAST")==0)
#define IS_MCAST_FULL     (strcmp(CAST_TYPE,"MULTICAST_FULL")==0)
#define IS_MCAST_PARTIAL  (strcmp(CAST_TYPE,"MULTICAST_PARTIAL")==0)
#define IS_BCAST_FULL     (strcmp(CAST_TYPE,"BROADCAST_FULL")==0)
#define IS_BCAST_PARTIAL  (strcmp(CAST_TYPE,"BROADCAST_PARTIAL")==0)

#include "parameter.h"
//alignas(64) int router_is_active [NR]={1};


int reset,clk;

Vtraffic        *traffic[NE]; // for synthetic and trace traffic pattern
Vpck_inj        *pck_inj[NE]; // for netrace



unsigned char reset_active_high=1;

unsigned int total_rsv_pck_num=0;
unsigned int total_sent_pck_num=0;
unsigned int end_sim_pck_num=0;
unsigned int sim_end_clk_num;
unsigned long int nt_tr_list_pck=0;
int netrace_speed_up =1;

unsigned int * rsv_size_array;
int AVG_PACKET_SIZE=5;
int MIN_PACKET_SIZE=5;
int MAX_PACKET_SIZE=5;


unsigned int random_var[NE] = {100};


typedef struct  statistic_struct {
    unsigned int pck_num;
    unsigned int flit_num;
    unsigned int worst_latency;
    unsigned int min_latency;
    double sum_clk_h2h;
    double sum_clk_h2t;
    double sum_clk_per_hop;
#if (STND_DEV_EN)
    double sum_clk_pow2;
#endif

} statistic_t;


typedef struct  avg_st_struct {
    double avg_latency_per_hop;
    double avg_latency_flit;
    double avg_latency_pck;
    double avg_throughput;
    double avg_pck_siz;
#if (STND_DEV_EN)
    double std_dev;
#endif

} avg_st_t;

#define BYPASS_LSB          7
#define FLIT_IN_WR_FLG        (1<<6)
#define PCK_IN_WR_FLG         (1<<5)
#define FLIT_OUT_WR_FLG     (1<<4)
#define PCK_OUT_WR_FLG        (1<<3)
#define FLIT_IN_BYPASSED     (1<<2)
#define ACTIVE_HIGH_RST     (1<<1)
#define EMPTY_FLG           (1<<0)




typedef  struct  router_st_struct {
    unsigned int pck_num_in;
    unsigned int flit_num_in;
    unsigned int pck_num_out;
    unsigned int flit_num_out;
    unsigned int flit_num_in_bypassed;
    unsigned int flit_num_in_buffered;
    unsigned int bypass_counter [SMART_NUM+1 ] ;
} router_st_t;

alignas(64) router_st_t router_stat [NR][MAX_P];
router_st_t router_stat_accum [NR];


#if (C>1)
    statistic_t sent_stat [NE][C];
    statistic_t rsvd_stat [NE][C];
#else
    statistic_t sent_stat [NE];
    statistic_t rsvd_stat [NE];
#endif

    statistic_t endp_to_endp [NE][NE];

typedef struct mcast_struct {
    int ratio;
    int min;
    int max;
}mcast_t;


void update_statistic_at_ejection (    int    ,     unsigned int, unsigned int, unsigned int,  unsigned int, unsigned int ,unsigned int);
void update_noc_statistic (    int);
unsigned char pck_class_in_gen(unsigned int);
unsigned int pck_dst_gen_task_graph ( unsigned int, unsigned char *);
void print_statistic (void);
void print_parameter();
void reset_all_register();
void sim_eval_all (void);
void sim_final_all (void);
void traffic_clk_negedge_event(void);
void traffic_clk_posedge_event(void);
void connect_clk_reset_start_all(void);
unsigned int rnd_between (unsigned int, unsigned int );
void traffic_gen_init( void );
void  pck_inj_init(int);
void traffic_gen_final_report(void);
void processArgs (int, char ** );
void task_traffic_init (char * );
int parse_string ( char *, int *);
void update_pck_size(char *);
void update_custom_traffic (char *);
void update_hotspot(char * );
void update_mcast_traffic(char * str);
void initial_threads (void);
void print_statistic_new (unsigned long int);
void allocate_rsv_pck_counters (void);
void update_all_router_stat(void);
void print_router_st(void);
void print_endp_to_endp_st(const char *);
void update_traffic_injector_st (unsigned int );

#include "topology_top.h"
#include "traffic_task_graph.h"
#include "traffic_synthetic.h"
#include "netrace_lib.h"
#include "synful_wrapper.h"

#define RATIO_INIT        2
#define DISABLE -1
#define MY_VL_SETBIT_W(data,bit) (data[VL_BITWORD_I(bit)] |= (VL_UL(1) << VL_BITBIT_I(bit)))

#define RANDOM_RANGE 1
#define RANDOM_discrete 2







int HOTSPOT_NUM;
int  * class_percentage;
char * TRAFFIC;
char * netrace_file;
char * synful_file;
unsigned char FIXED_SRC_DST_PAIR;
unsigned char  NEw=0;
unsigned long int main_time = 0;     // Current simulation time
unsigned int saved_time = 0;

unsigned int sum_clk_h2h=0;
unsigned int sum_clk_h2t=0;
double          sum_clk_per_hop=0;
const int  CC=(C==0)? 1 : C;
unsigned int total_rsv_pck_num_per_class[CC]={0};
unsigned int sum_clk_h2h_per_class[CC]={0};
unsigned int sum_clk_h2t_per_class[CC]={0};
double          sum_clk_per_hop_per_class[CC]={0};

unsigned int clk_counter,ideal_rsv_cnt;
unsigned int count_en;
unsigned int total_active_endp;
char all_done=0;
unsigned int total_sent_flit_number =0;
unsigned int total_rsv_flit_number =0;
unsigned int total_expect_rsv_flit_num =0;
unsigned int total_rsv_flit_number_old=0;
int ratio=RATIO_INIT;
double first_avg_latency_flit,current_avg_latency_flit;
double sc_time_stamp ();
int pow2( int );
char inject_done=0;
char simulation_done=0;
char pck_size_sel=RANDOM_RANGE;
int  * discrete_size;
int  * discrete_prob;
int verbosity=1;
int thread_num =1;


mcast_t mcast;



#if (STND_DEV_EN)
    //#include <math.h>
    double sqroot (double s){
        int i;    
        double root = s/3;
        if (s<=0) return 0;
        for(i=0;i<32;i++) root = (root +s/root)/2;
        return root;
    }
    
    double          sum_clk_pow2=0;
    double          sum_clk_pow2_per_class[C];
    double standard_dev( double , unsigned int, double);
#endif


    // set data[bit] to 1
        #define VL_BIT_SET_I(data, bit) data |= (VL_UL(1) << VL_BITBIT_I(bit))
        #define VL_BIT_SET_Q(data, bit) data |= (1ULL << VL_BITBIT_Q(bit))
        #define VL_BIT_SET_E(data, bit) data |= (VL_EUL(1) << VL_BITBIT_E(bit))
        #define VL_BIT_SET_W(data, bit) (data)[VL_BITWORD_E(bit)] |= (VL_EUL(1) << VL_BITBIT_E(bit))

        // set data[bit] to 0
        #define VL_BIT_CLR_I(data, bit) data &= ~(VL_UL(1) << VL_BITBIT_I(bit))
        #define VL_BIT_CLR_Q(data, bit) data &= ~(1ULL << VL_BITBIT_Q(bit))
        #define VL_BIT_CLR_E(data, bit) data &= ~ (VL_EUL(1) << VL_BITBIT_E(bit))
        #define VL_BIT_CLR_W(data, bit) (data)[VL_BITWORD_E(bit)] &= ~ (VL_EUL(1) << VL_BITBIT_E(bit))


        #if   (DAw<=VL_IDATASIZE)
            #define DEST_ADDR_BIT_SET(data, bit)  VL_BIT_SET_I(data, bit)
            #define DEST_ADDR_BIT_CLR(data, bit)  VL_BIT_CLR_I(data, bit)
            #define DEST_ADDR_ASSIGN_RAND(data)   data = rand() & ((1<<DAw) -1)
            #define DEST_ADDR_ASSIGN_ZERO(data)   data = 0
            #define DEST_ADDR_ASSIGN_INT(data,val) data = val & ((1<<DAw) -1)
            #define DEST_ADDR_IS_ZERO(a,data) a= (data ==0)
        #elif (DAw<=VL_QUADSIZE)
            #define DEST_ADDR_BIT_SET(data, bit)  VL_BIT_SET_Q(data, bit)
            #define DEST_ADDR_BIT_CLR(data, bit)  VL_BIT_CLR_Q(data, bit)
            #define DEST_ADDR_ASSIGN_RAND(data)   data = (rand()&0xFFFFFFFF) | \
            (QData)    (rand() & ((1ULL<<(DAw-32)) -1))    <<32
            #define DEST_ADDR_ASSIGN_ZERO(data)   data = 0ULL
            #define DEST_ADDR_ASSIGN_INT(data,val) data = val & ((1ULL<<32) -1)
            #define DEST_ADDR_IS_ZERO(a,data) a= (data == 0ULL)
        #else
            #define DEST_ADDR_BIT_SET(data, bit)  VL_BIT_SET_W(data, bit)
            #define DEST_ADDR_BIT_CLR(data, bit)  VL_BIT_CLR_W(data, bit)
            #define DEST_ADDR_ASSIGN_RAND(data) \
            for(int n=0;n<=VL_BITWORD_E(DAw-1)-1;n++)  (data)[n]=rand();\
            (data)[VL_BITWORD_E(DAw-1)]=rand() & ((1ULL<<(VL_BITBIT_E(DAw-1)+1)) -1)
            #define DEST_ADDR_ASSIGN_ZERO(data) \
            for(int n=0;n<=VL_BITWORD_E(DAw-1);n++)  (data)[n]= 0
            #define DEST_ADDR_ASSIGN_INT(data,val) (data)[0] = val

            #define DEST_ADDR_IS_ZERO(a,data) \
            a=1; for(int n=0;n<=VL_BITWORD_E(DAw-1)-1;n++)     \
            if (a==1) a= ((data)[n]==0);\
            if (a==1) a= ((data)[VL_BITWORD_E(DAw-1)] & ((1ULL<<(VL_BITBIT_E(DAw-1)+1)) -1))==0
        #endif


#endif
