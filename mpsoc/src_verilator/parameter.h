 #ifndef     INCLUDE_PARAM
  #define   INCLUDE_PARAM

	 #define	V	4
	 #define	B	5
	 #define	NX	8
	 #define	NY	8
	 #define	C	4
	 #define	Fpay    32
	 #define	MUX_TYPE    "ONE_HOT"
	 #define	VC_REALLOCATION_TYPE    "NONATOMIC"
	 #define	COMBINATION_TYPE    "COMB_NONSPEC"
	 #define	FIRST_ARBITER_EXT_P_EN    0
	 #define	TOPOLOGY    "MESH"
	 #define	ROUTE_NAME    "XY"
	 #define  C0_p	25
	 #define  C1_p	25
	 #define  C2_p	25
	 #define  C3_p	25
	 #define	TRAFFIC    "RANDOM"
	 #define	HOTSPOT_PERCENTAGE    3
	 #define	HOTSOPT_NUM    4
	 #define	HOTSPOT_CORE_1    18
	 #define	HOTSPOT_CORE_2    50
	 #define	HOTSPOT_CORE_3    22
	 #define	HOTSPOT_CORE_4    54
	 #define	HOTSPOT_CORE_5    18
	 #define	MAX_PCK_NUM			256000
	 #define	MAX_SIM_CLKs		100000
	 #define	MAX_PCK_SIZ			10
	 #define	TIMSTMP_FIFO_NUM	8
	 #define	PACKET_SIZE	4
	 #define	DEBUG_EN	1
	 #define	ROUTE_SUBFUNC "NORTH_LAST"
	 #define	AVC_ATOMIC_EN 0
	 #define	CONGESTION_INDEX 3
	 #define	STND_DEV_EN	0
	 #define  AVG_LATENCY_METRIC	"HEAD_2_TAIL"
	 #define  ADD_PIPREG_AFTER_CROSSBAR  0
	 #define  CVw	(C==0)? V : C * V
	 #define  CLASS_SETTING   "16'b111111111111111"
	 #define  ESCAP_VC_MASK	4'b0001
	 #define	SSA_EN "NO"
 

 #endif 