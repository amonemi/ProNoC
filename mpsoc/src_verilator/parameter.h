 #ifndef     INCLUDE_PARAM
  #define   INCLUDE_PARAM

	 #define	V	4
	 #define	B	4
	 #define	NX	8
	 #define	NY	8
	 #define	C	1
	 #define	Fpay    32
	 #define	MUX_TYPE    "ONE_HOT"
	 #define	VC_REALLOCATION_TYPE    "NONATOMIC"
	 #define	COMBINATION_TYPE    "COMB_NONSPEC"
	 #define	FIRST_ARBITER_EXT_P_EN    0
	 #define	TOPOLOGY    "MESH"
	 #define	ROUTE_NAME    "XY"
	 #define  C0_p	100
	 #define  C1_p	0
	 #define  C2_p	0
	 #define  C3_p	0
	 #define	TRAFFIC    "RANDOM"
	 #define	HOTSPOT_PERCENTAGE    3
	 #define	HOTSOPT_NUM    4
	 #define	HOTSPOT_CORE_1    9
	 #define	HOTSPOT_CORE_2    25
	 #define	HOTSPOT_CORE_3    11
	 #define	HOTSPOT_CORE_4    27
	 #define	HOTSPOT_CORE_5    18
	 #define	MAX_PCK_NUM			128000
	 #define	MAX_SIM_CLKs		100000
	 #define	MAX_PCK_SIZ			10
	 #define	TIMSTMP_FIFO_NUM	64
	 #define	PACKET_SIZE	2
	 #define	DEBUG_EN	1
	 #define	ROUTE_SUBFUNC "NORTH_LAST"
	 #define	AVC_ATOMIC_EN 0
	 #define	CONGESTION_INDEX 3
	 #define	STND_DEV_EN	0
	 #define  AVG_LATENCY_METRIC	"HEAD_2_TAIL"
	 #define  ADD_PIPREG_AFTER_CROSSBAR  0
	 #define  ADD_PIPREG_BEFORE_CROSSBAR  0
	 #define  CVw	(C==0)? V : C * V
	 #define  CLASS_SETTING   8'b11111111
	 #define  ESCAP_VC_MASK	1
 

 #endif 