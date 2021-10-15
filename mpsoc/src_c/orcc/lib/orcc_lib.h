#ifndef ORCC_LIB_H
#define ORCC_LIB_H

#define MAX_ACTORS 1024


typedef signed char i8;
typedef short i16;
typedef int i32;
typedef long long int i64;

typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;
typedef unsigned long long int u64;

///////////////////////////////////////////////////

#ifndef CACHELINE_SIZE
#define CACHELINE_SIZE 4 // 
#endif

// Declare the FIFO structure with a size equal to (size)
#define DECLARE_FIFO(type, size, count, readersnb) static type array_##count[(size)]; \
static unsigned int read_inds_##count[readersnb] = {0}; \
static FIFO_T(type) fifo_##count = {{0}, read_inds_##count, {0}, 0, {0}, array_##count};

#define FIFO_T(T) FIFO_T_EXPAND(T)
#define FIFO_T_EXPAND(T) fifo_##T##_t

#define FIFO_GET_ROOM(T) FIFO_GET_ROOM_EXPAND(T)
#define FIFO_GET_ROOM_EXPAND(T) fifo_ ## T ## _get_room

#define FIFO_GET_NUM_TOKENS(T) FIFO_GET_NUM_TOKENS_EXPAND(T)
#define FIFO_GET_NUM_TOKENS_EXPAND(T) fifo_ ## T ## _get_num_tokens

/* Define structure and methods for all types thanks to macro expansion */

#define T i8
#include "generic_fifo.h"
#undef T

#define T i16
#include "generic_fifo.h"
#undef T

#define T i32
#include "generic_fifo.h"
#undef T

#define T i64
#include "generic_fifo.h"
#undef T

#define T u8
#include "generic_fifo.h"
#undef T

#define T u16
#include "generic_fifo.h"
#undef T

#define T u32
#include "generic_fifo.h"
#undef T

#define T u64
#include "generic_fifo.h"
#undef T

#define T float
#include "generic_fifo.h"
#undef T

//#endif  /* _ORCC_FIFO_H_ */

///////////////////////////////////////////////////


typedef int boolean;
#define TRUE  1
#define FALSE 0

/* Scheduling strategy codes */
typedef enum {
    ORCC_SS_ROUND_ROBIN,
    ORCC_SS_DD_DRIVEN, /* data-driven & demand-driven */
    ORCC_SS_SIZE /* only used for string tab declaration */
} schedstrategy_et;

/* Mapping strategy codes */
typedef enum {
#ifdef METIS_ENABLE
    ORCC_MS_METIS_REC,
    ORCC_MS_METIS_KWAY_CV,
    ORCC_MS_METIS_KWAY_EC,
#endif /* METIS_ENABLE */
    ORCC_MS_ROUND_ROBIN,
    ORCC_MS_QM,
    ORCC_MS_WLB,
    ORCC_MS_COWLB,
    ORCC_MS_KRWLB,
    ORCC_MS_SIZE /* only used for string tab declaration */
} mappingstrategy_et;

typedef enum reasons {
    starved,
    full
} reasons_t;

typedef struct actor_s actor_t;
typedef struct waiting_s waiting_t;
typedef struct agent_s agent_t;
typedef struct action_s action_t;
typedef struct local_scheduler_s local_scheduler_t;
typedef struct schedinfo_s schedinfo_t;
typedef struct options_s options_t;
typedef struct global_scheduler_s global_scheduler_t;
typedef struct mapping_s mapping_t;
typedef struct network_s network_t;
typedef struct connection_s connection_t;

/*
 * Actors are the vertices of orcc Networks
 */
struct actor_s {
    char *name;
    void (*init_func)(schedinfo_t *);
    void (*sched_func)(schedinfo_t *);
    int num_inputs; /** number of input ports */
    int num_outputs; /** number of output ports */
    int in_list; /** set to 1 when the actor is in the schedulable list. Used by add_schedulable to do the membership test in O(1). */
    int in_waiting; /** idem with the waiting list. */
    local_scheduler_t *sched; /** scheduler which execute this actor. */
    int processor_id; /** id of the processor core mapped to this actor. */
    int id;
    int commCost;  /** Used by Quick Mapping algo */
    int triedProcId;  /** Used by Quick Mapping algo */
    int evaluated;  /** Used by KL algo */
    int workload; /** actor's workload */
    double ticks; /** elapsed ticks obtained by profiling */
    action_t **actions;
    int nb_actions;
    double scheduler_workload;
    char *class_name;
    int firings; /** nb of firings for profiling */
    int switches; /** nb of switches for profiling */
    int misses; /** nb of misses for profiling */
};


struct waiting_s {
    actor_t *waiting_actors[MAX_ACTORS];
    volatile unsigned int next_entry;
    unsigned int next_waiting;
};



struct agent_s {
    options_t *options; /** Mapping options */
    global_scheduler_t *scheduler;
    network_t *network;
    mapping_t *mapping;
    int nb_threads;
#ifdef THREADS_ENABLE
    orcc_semaphore_t sem_agent;
#endif
};


/*
 * Actions
 */
struct action_s {
    char *name;
    double workload; /** action's workload */
    double ticks; /** elapsed ticks obtained by profiling */
    double min_ticks; /** elapsed min clockcycles obtained by profiling */
    double avg_ticks; /** elapsed average clockcycles obtained by profiling */
    double max_ticks; /** elapsed max clockcycles obtained by profiling */
    double variance_ticks; /** elapsed clockcycles variance obtained by profiling */
    int firings; /** nb of firings for profiling */
};



struct schedinfo_s {
    int num_firings;
    reasons_t reason;
    int ports; /** contains a mask that indicate the ports affected */
};

struct options_s
{
    /* Video specific options */
    char *input_file;
    char *input_directory;               // Directory for input files.

    /* Video specific options */
    char display_flags;                  // Display flags
    int nbLoops;                         // (Deprecated) Number of times the input file is read
    int nbFrames;                        // Number of frames to display before closing application
    char *yuv_file;                      // Reference YUV file

    /* Runtime options */
    schedstrategy_et sched_strategy;     // Strategy for the actor scheduling
    char *mapping_input_file;            // Predefined mapping configuration
    char *mapping_output_file;           //
    int nb_processors;
    boolean enable_dynamic_mapping;
    mappingstrategy_et mapping_strategy; // Strategy for the actor mapping
    int nbProfiledFrames;                // Number of frames to display before remapping application
    int mapping_repetition;              // Repetition of the actor remapping

    char *profiling_file; // profiling file
    char *write_file; // write file

    /* Debugging options */
    boolean print_firings;
};



struct global_scheduler_s {
    local_scheduler_t **schedulers;
    int nb_schedulers;
    agent_t *agent;
};

/*
 * Mapping structure store the mapping result
 */
struct mapping_s {
    int number_of_threads;
    int *threads_affinities;
    actor_t ***partitions_of_actors;
    int *partitions_size;
};

/*
 * Orcc Networks are directed graphs
 */
struct network_s {
    char *name;
    actor_t **actors;
    connection_t **connections;
    int nb_actors;
    int nb_connections;
};

/*
 * Connections are the edges of orcc Networks
 */
struct connection_s {
    actor_t *src;
    actor_t *dst;
    int workload; /** connections's workload */
    long rate; /** communication rate obtained by profiling */
};





struct local_scheduler_s {
    int id; /** Unique ID of this scheduler */
    int nb_schedulers;
    schedstrategy_et strategy; /** Scheduling strategy */

    /* Round robin */
    int num_actors; /** number of actors managed by this scheduler */
    actor_t **actors; /** static list of actors managed by this scheduler */
    int rr_next_schedulable; /** index of the next actor to schedule in last list */

    /* Data demand/driven scheduler */
    actor_t *schedulable[MAX_ACTORS]; /** dynamic list of the next actors to schedule */
    unsigned int ddd_next_entry; /** index of the next actor to schedule in last list */
    unsigned int ddd_next_schedulable; /** index of next actor added in the list */

    /* Multicore with data demand/driven scheduler */
    int round_robin; /** set to 1 when last scheduled actor is a result of round robin scheduling */
    waiting_t **waiting_schedulable; /** receiving lists from other schedulers of some actors to schedule */

    /* Mapping synchronization */
    agent_t *agent;
#ifdef THREADS_ENABLE
    orcc_semaphore_t sem_thread;
#endif
};






/*


// a simple delay function

void delay ( unsigned int num ){
	
	while (num>0){ 
		num--;
		nop(); // asm volatile ("nop");
	}
	return;

}

#ifndef RANDOM_H
	#define RANDOM_H

// KISS is one random number generator according to three numbers.
static unsigned int x=123456789,y=234567891,z=345678912,w=456789123,c=0; 

unsigned int JKISS32() { 
    unsigned int t; 

    y ^= (y<<5); y ^= (y>>7); y ^= (y<<22); 

    t = z+w+c; z = w; c = t < 0; w = t&2147483647; 

    x += 1411392427; 

    return x + y + w; 
}

unsigned int rand(void){
	return JKISS32();
}

void srand(unsigned int seed){
	x^=seed; y+=seed; z^=seed; w-=seed;
}

#endif
*/

#endif
