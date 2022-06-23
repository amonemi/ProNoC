#ifndef _SYNFUL_H
	#define  _SYNFUL_H
	
	#define SYNFUL_ENDP_NUM 32


typedef struct pronoc_pck pronoc_pck_t;

struct pronoc_pck {
	int source;
	int dest;
	int id;
	int packetSize;
	int msgType;
	unsigned long long cycle;
};


	

extern queue_t** synful_inject;

extern unsigned long long synful_cycle;
extern int synful_injection_done;


	
void synful_eval ();
void synful_model_init(char *, bool , int,unsigned int,unsigned int, int *);
void synful_run_one_cycle ();

void synful_print_packet( pronoc_pck_t*) ;
void synful_Eject (pronoc_pck_t*);
	
	
#endif
