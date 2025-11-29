
// simulation parameter setting

`ifdef INCLUDE_SIM_PARAM
    localparam
        TRAFFIC="RANDOM", // "NEIGHBOR", "BIT_COMPLEMENT", "TRANSPOSE2", "RANDOM", "CUSTOM", "HOTSPOT"
        PCK_SIZ_SEL="random-range",
        AVG_LATENCY_METRIC= "HEAD_2_TAIL",
        // Simulation min/max packet size
        // NOTE: The injected packet take a size randomly selected between min and max values
        MIN_PACKET_SIZE=5,
        MAX_PACKET_SIZE=5,
        STOP_PCK_NUM=2000, // simulation stops when #STOP_PCK_NUM packets are injected in the NoC
        STOP_SIM_CLK=1000; // simulation stops when #STOP_SIM_CLK cycles are passed

    // parameters for setting hotspot traffic pattern
    localparam HOTSPOT_NODE_NUM = 0;
    hotspot_t hotspot_info [0:0];

    // parameters for setting point-to-point custom traffic pattern
    localparam CUSTOM_NODE_NUM = 0;
    wire [NEw-1:0] custom_traffic_t[NE-1:0];
    wire [NE-1:0]  custom_traffic_en;

    localparam MCAST_TRAFFIC_RATIO = 0;
    localparam MCAST_PCK_SIZ_MAX   = 0;
    localparam MCAST_PCK_SIZ_MIN   = 0;

    localparam DISCRETE_PCK_SIZ_NUM = 1;
    rnd_discrete_t rnd_discrete [DISCRETE_PCK_SIZ_NUM-1:0];

    // flit injection ratio in %
    parameter INJRATIO=50;
`endif
