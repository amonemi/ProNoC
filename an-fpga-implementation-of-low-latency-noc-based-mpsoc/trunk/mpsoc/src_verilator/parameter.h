
#ifndef     INCLUDE_PARAM
	#define   INCLUDE_PARAM 
 
 

	

//NoC parameters
 	#define TOPOLOGY	"MESH"
 	#define NX	 2
 	#define NY	 2
 	#define V	2
 	#define B	4
 	#define Fpay	32
 	#define ROUTE_NAME	"XY"
 	#define SSA_EN	"NO"
 	#define CONGESTION_INDEX	3
 	#define ESCAP_VC_MASK	 01
 	#define VC_REALLOCATION_TYPE	"NONATOMIC"
 	#define COMBINATION_TYPE	"COMB_NONSPEC"
 	#define MUX_TYPE	"BINARY"
 	#define C	0
 	#define DEBUG_EN	0
 	#define ADD_PIPREG_AFTER_CROSSBAR	 0
 	#define SWA_ARBITER_TYPE	"RRA"
 	#define FIRST_ARBITER_EXT_P_EN	1
 	#define AVC_ATOMIC_EN	0
 	#define ROUTE_SUBFUNC	"XY"
 
	
	int   P=(strcmp (TOPOLOGY,"RING")==0 || strcmp (TOPOLOGY,"LINE")==0 )    ?   3 : 5;
 	
	
	//simulation parameter	
	#define AVG_LATENCY_METRIC "HEAD_2_TAIL"
	#define TIMSTMP_FIFO_NUM   16 

 
 #endif
