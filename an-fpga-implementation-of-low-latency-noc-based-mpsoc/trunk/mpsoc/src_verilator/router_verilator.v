/**************
Port num = 2
****************/ 

module router_verilator_p2
(
    current_r_addr,
    neighbors_r_addr,    
    flit_in_all,
    flit_in_we_all,
    credit_out_all,
    congestion_in_all,
    flit_out_all,
    flit_out_we_all,
    credit_in_all,
    congestion_out_all,
    clk,reset
);

    localparam P=2;   

    `define   INCLUDE_PARAM
    `include "parameter.v"

    `define INCLUDE_TOPOLOGY_LOCALPARAM
    `include "topology_localparam.v"
 

    localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;


   
    localparam         
        PV = V * P,
        P_1 = P-1,
        Fw = 2+V+Fpay,  //flit width;
        PFw = P * Fw,
        CONG_ALw = CONGw * P,    //  congestion width per router      
        W = WEIGHTw,
        WP = W * P,
        PRAw = P * RAw;    

    input clk,reset;
    input  [RAw-1 : 0] current_r_addr;    
    input  [PRAw-1 :  0] neighbors_r_addr;    
    input  [PFw-1 : 0]  flit_in_all;
    input  [P-1 : 0]  flit_in_we_all;
    output [PV-1 : 0]  credit_out_all;
    input  [CONG_ALw-1 : 0]  congestion_in_all;  
     
    output [PFw-1 : 0]  flit_out_all;
    output [P-1 : 0]  flit_out_we_all;
    input  [PV-1 : 0]  credit_in_all;
    output [CONG_ALw-1 : 0]  congestion_out_all;  

    router # (
        .V(V),
        .P(P),
        .B(B), 
        .T1(T1),
        .T2(T2),
	.T3(T3),
        .C(C),  
        .Fpay(Fpay),    
        .MUX_TYPE(MUX_TYPE),
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .COMBINATION_TYPE(COMBINATION_TYPE),
        .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),  
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .CONGw(CONGw),
        .DEBUG_EN(DEBUG_EN),
        .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING),   
        .ESCAP_VC_MASK(ESCAP_VC_MASK),
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw),
        .MIN_PCK_SIZE(MIN_PCK_SIZE)           
    )
    the_router
    (
        .current_r_addr(current_r_addr),
        .neighbors_r_addr(neighbors_r_addr),
        .flit_in_all(flit_in_all),
        .flit_in_we_all(flit_in_we_all),
        .credit_out_all(credit_out_all),
        .congestion_in_all(congestion_in_all),
        .flit_out_all(flit_out_all),
        .flit_out_we_all(flit_out_we_all),
        .credit_in_all(credit_in_all),
        .congestion_out_all(congestion_out_all),
        .clk(clk),
        .reset(reset)

    );
endmodule

/**************
Port num = 3
****************/ 

module router_verilator_p3
(
    current_r_addr,
    neighbors_r_addr,    
    flit_in_all,
    flit_in_we_all,
    credit_out_all,
    congestion_in_all,
    flit_out_all,
    flit_out_we_all,
    credit_in_all,
    congestion_out_all,
    clk,reset
);

    localparam P=3;   

    `define   INCLUDE_PARAM
    `include "parameter.v"

    `define INCLUDE_TOPOLOGY_LOCALPARAM
    `include "topology_localparam.v"
 

    localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;


   
    localparam         
        PV = V * P,
        P_1 = P-1,
        Fw = 2+V+Fpay,  //flit width;
        PFw = P * Fw,
        CONG_ALw = CONGw * P,    //  congestion width per router      
        W = WEIGHTw,
        WP = W * P,
        PRAw = P * RAw;    

    input clk,reset;
    input  [RAw-1 : 0] current_r_addr;    
    input  [PRAw-1 :  0] neighbors_r_addr;    
    input  [PFw-1 : 0]  flit_in_all;
    input  [P-1 : 0]  flit_in_we_all;
    output [PV-1 : 0]  credit_out_all;
    input  [CONG_ALw-1 : 0]  congestion_in_all;  
     
    output [PFw-1 : 0]  flit_out_all;
    output [P-1 : 0]  flit_out_we_all;
    input  [PV-1 : 0]  credit_in_all;
    output [CONG_ALw-1 : 0]  congestion_out_all;  

    router # (
        .V(V),
        .P(P),
        .B(B), 
        .T1(T1),
        .T2(T2),
	.T3(T3),
        .C(C),  
        .Fpay(Fpay),    
        .MUX_TYPE(MUX_TYPE),
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .COMBINATION_TYPE(COMBINATION_TYPE),
        .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),  
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .CONGw(CONGw),
        .DEBUG_EN(DEBUG_EN),
        .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING),   
        .ESCAP_VC_MASK(ESCAP_VC_MASK),
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw),
        .MIN_PCK_SIZE(MIN_PCK_SIZE)           
    )
    the_router
    (
        .current_r_addr(current_r_addr),
        .neighbors_r_addr(neighbors_r_addr),
        .flit_in_all(flit_in_all),
        .flit_in_we_all(flit_in_we_all),
        .credit_out_all(credit_out_all),
        .congestion_in_all(congestion_in_all),
        .flit_out_all(flit_out_all),
        .flit_out_we_all(flit_out_we_all),
        .credit_in_all(credit_in_all),
        .congestion_out_all(congestion_out_all),
        .clk(clk),
        .reset(reset)

    );
endmodule

/**************
Port num = 4
****************/ 

module router_verilator_p4
(
    current_r_addr,
    neighbors_r_addr,    
    flit_in_all,
    flit_in_we_all,
    credit_out_all,
    congestion_in_all,
    flit_out_all,
    flit_out_we_all,
    credit_in_all,
    congestion_out_all,
    clk,reset
);

    localparam P=4;   

    `define   INCLUDE_PARAM
    `include "parameter.v"

    `define INCLUDE_TOPOLOGY_LOCALPARAM
    `include "topology_localparam.v"
 

    localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;


   
    localparam         
        PV = V * P,
        P_1 = P-1,
        Fw = 2+V+Fpay,  //flit width;
        PFw = P * Fw,
        CONG_ALw = CONGw * P,    //  congestion width per router      
        W = WEIGHTw,
        WP = W * P,
        PRAw = P * RAw;    

    input clk,reset;
    input  [RAw-1 : 0] current_r_addr;    
    input  [PRAw-1 :  0] neighbors_r_addr;    
    input  [PFw-1 : 0]  flit_in_all;
    input  [P-1 : 0]  flit_in_we_all;
    output [PV-1 : 0]  credit_out_all;
    input  [CONG_ALw-1 : 0]  congestion_in_all;  
     
    output [PFw-1 : 0]  flit_out_all;
    output [P-1 : 0]  flit_out_we_all;
    input  [PV-1 : 0]  credit_in_all;
    output [CONG_ALw-1 : 0]  congestion_out_all;  

    router # (
        .V(V),
        .P(P),
        .B(B), 
        .T1(T1),
        .T2(T2),
	.T3(T3),
        .C(C),  
        .Fpay(Fpay),    
        .MUX_TYPE(MUX_TYPE),
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .COMBINATION_TYPE(COMBINATION_TYPE),
        .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),  
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .CONGw(CONGw),
        .DEBUG_EN(DEBUG_EN),
        .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING),   
        .ESCAP_VC_MASK(ESCAP_VC_MASK),
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw),
        .MIN_PCK_SIZE(MIN_PCK_SIZE)           
    )
    the_router
    (
        .current_r_addr(current_r_addr),
        .neighbors_r_addr(neighbors_r_addr),
        .flit_in_all(flit_in_all),
        .flit_in_we_all(flit_in_we_all),
        .credit_out_all(credit_out_all),
        .congestion_in_all(congestion_in_all),
        .flit_out_all(flit_out_all),
        .flit_out_we_all(flit_out_we_all),
        .credit_in_all(credit_in_all),
        .congestion_out_all(congestion_out_all),
        .clk(clk),
        .reset(reset)

    );
endmodule

/**************
Port num = 5
****************/ 

module router_verilator_p5
(
    current_r_addr,
    neighbors_r_addr,    
    flit_in_all,
    flit_in_we_all,
    credit_out_all,
    congestion_in_all,
    flit_out_all,
    flit_out_we_all,
    credit_in_all,
    congestion_out_all,
    clk,reset
);

    localparam P=5;   

    `define   INCLUDE_PARAM
    `include "parameter.v"

    `define INCLUDE_TOPOLOGY_LOCALPARAM
    `include "topology_localparam.v"
 

    localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;


   
    localparam         
        PV = V * P,
        P_1 = P-1,
        Fw = 2+V+Fpay,  //flit width;
        PFw = P * Fw,
        CONG_ALw = CONGw * P,    //  congestion width per router      
        W = WEIGHTw,
        WP = W * P,
        PRAw = P * RAw;    

    input clk,reset;
    input  [RAw-1 : 0] current_r_addr;    
    input  [PRAw-1 :  0] neighbors_r_addr;    
    input  [PFw-1 : 0]  flit_in_all;
    input  [P-1 : 0]  flit_in_we_all;
    output [PV-1 : 0]  credit_out_all;
    input  [CONG_ALw-1 : 0]  congestion_in_all;  
     
    output [PFw-1 : 0]  flit_out_all;
    output [P-1 : 0]  flit_out_we_all;
    input  [PV-1 : 0]  credit_in_all;
    output [CONG_ALw-1 : 0]  congestion_out_all;  

    router # (
        .V(V),
        .P(P),
        .B(B), 
        .T1(T1),
        .T2(T2),
	.T3(T3),
        .C(C),  
        .Fpay(Fpay),    
        .MUX_TYPE(MUX_TYPE),
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .COMBINATION_TYPE(COMBINATION_TYPE),
        .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),  
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .CONGw(CONGw),
        .DEBUG_EN(DEBUG_EN),
        .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING),   
        .ESCAP_VC_MASK(ESCAP_VC_MASK),
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw),
        .MIN_PCK_SIZE(MIN_PCK_SIZE)           
    )
    the_router
    (
        .current_r_addr(current_r_addr),
        .neighbors_r_addr(neighbors_r_addr),
        .flit_in_all(flit_in_all),
        .flit_in_we_all(flit_in_we_all),
        .credit_out_all(credit_out_all),
        .congestion_in_all(congestion_in_all),
        .flit_out_all(flit_out_all),
        .flit_out_we_all(flit_out_we_all),
        .credit_in_all(credit_in_all),
        .congestion_out_all(congestion_out_all),
        .clk(clk),
        .reset(reset)

    );
endmodule

/**************
Port num = 6
****************/ 

module router_verilator_p6
(
    current_r_addr,
    neighbors_r_addr,    
    flit_in_all,
    flit_in_we_all,
    credit_out_all,
    congestion_in_all,
    flit_out_all,
    flit_out_we_all,
    credit_in_all,
    congestion_out_all,
    clk,reset
);

    localparam P=6;   

    `define   INCLUDE_PARAM
    `include "parameter.v"

    `define INCLUDE_TOPOLOGY_LOCALPARAM
    `include "topology_localparam.v"
 

    localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;


   
    localparam         
        PV = V * P,
        P_1 = P-1,
        Fw = 2+V+Fpay,  //flit width;
        PFw = P * Fw,
        CONG_ALw = CONGw * P,    //  congestion width per router      
        W = WEIGHTw,
        WP = W * P,
        PRAw = P * RAw;    

    input clk,reset;
    input  [RAw-1 : 0] current_r_addr;    
    input  [PRAw-1 :  0] neighbors_r_addr;    
    input  [PFw-1 : 0]  flit_in_all;
    input  [P-1 : 0]  flit_in_we_all;
    output [PV-1 : 0]  credit_out_all;
    input  [CONG_ALw-1 : 0]  congestion_in_all;  
     
    output [PFw-1 : 0]  flit_out_all;
    output [P-1 : 0]  flit_out_we_all;
    input  [PV-1 : 0]  credit_in_all;
    output [CONG_ALw-1 : 0]  congestion_out_all;  

    router # (
        .V(V),
        .P(P),
        .B(B), 
        .T1(T1),
        .T2(T2),
	.T3(T3),
        .C(C),  
        .Fpay(Fpay),    
        .MUX_TYPE(MUX_TYPE),
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .COMBINATION_TYPE(COMBINATION_TYPE),
        .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),  
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .CONGw(CONGw),
        .DEBUG_EN(DEBUG_EN),
        .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING),   
        .ESCAP_VC_MASK(ESCAP_VC_MASK),
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw),
        .MIN_PCK_SIZE(MIN_PCK_SIZE)           
    )
    the_router
    (
        .current_r_addr(current_r_addr),
        .neighbors_r_addr(neighbors_r_addr),
        .flit_in_all(flit_in_all),
        .flit_in_we_all(flit_in_we_all),
        .credit_out_all(credit_out_all),
        .congestion_in_all(congestion_in_all),
        .flit_out_all(flit_out_all),
        .flit_out_we_all(flit_out_we_all),
        .credit_in_all(credit_in_all),
        .congestion_out_all(congestion_out_all),
        .clk(clk),
        .reset(reset)

    );
endmodule

/**************
Port num = 7
****************/ 

module router_verilator_p7
(
    current_r_addr,
    neighbors_r_addr,    
    flit_in_all,
    flit_in_we_all,
    credit_out_all,
    congestion_in_all,
    flit_out_all,
    flit_out_we_all,
    credit_in_all,
    congestion_out_all,
    clk,reset
);

    localparam P=7;   

    `define   INCLUDE_PARAM
    `include "parameter.v"

    `define INCLUDE_TOPOLOGY_LOCALPARAM
    `include "topology_localparam.v"
 

    localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;


   
    localparam         
        PV = V * P,
        P_1 = P-1,
        Fw = 2+V+Fpay,  //flit width;
        PFw = P * Fw,
        CONG_ALw = CONGw * P,    //  congestion width per router      
        W = WEIGHTw,
        WP = W * P,
        PRAw = P * RAw;    

    input clk,reset;
    input  [RAw-1 : 0] current_r_addr;    
    input  [PRAw-1 :  0] neighbors_r_addr;    
    input  [PFw-1 : 0]  flit_in_all;
    input  [P-1 : 0]  flit_in_we_all;
    output [PV-1 : 0]  credit_out_all;
    input  [CONG_ALw-1 : 0]  congestion_in_all;  
     
    output [PFw-1 : 0]  flit_out_all;
    output [P-1 : 0]  flit_out_we_all;
    input  [PV-1 : 0]  credit_in_all;
    output [CONG_ALw-1 : 0]  congestion_out_all;  

    router # (
        .V(V),
        .P(P),
        .B(B), 
        .T1(T1),
        .T2(T2),
	.T3(T3),
        .C(C),  
        .Fpay(Fpay),    
        .MUX_TYPE(MUX_TYPE),
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .COMBINATION_TYPE(COMBINATION_TYPE),
        .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),  
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .CONGw(CONGw),
        .DEBUG_EN(DEBUG_EN),
        .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING),   
        .ESCAP_VC_MASK(ESCAP_VC_MASK),
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw),
        .MIN_PCK_SIZE(MIN_PCK_SIZE)           
    )
    the_router
    (
        .current_r_addr(current_r_addr),
        .neighbors_r_addr(neighbors_r_addr),
        .flit_in_all(flit_in_all),
        .flit_in_we_all(flit_in_we_all),
        .credit_out_all(credit_out_all),
        .congestion_in_all(congestion_in_all),
        .flit_out_all(flit_out_all),
        .flit_out_we_all(flit_out_we_all),
        .credit_in_all(credit_in_all),
        .congestion_out_all(congestion_out_all),
        .clk(clk),
        .reset(reset)

    );
endmodule

/**************
Port num = 8
****************/ 

module router_verilator_p8
(
    current_r_addr,
    neighbors_r_addr,    
    flit_in_all,
    flit_in_we_all,
    credit_out_all,
    congestion_in_all,
    flit_out_all,
    flit_out_we_all,
    credit_in_all,
    congestion_out_all,
    clk,reset
);

    localparam P=8;   

    `define   INCLUDE_PARAM
    `include "parameter.v"

    `define INCLUDE_TOPOLOGY_LOCALPARAM
    `include "topology_localparam.v"
 

    localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;


   
    localparam         
        PV = V * P,
        P_1 = P-1,
        Fw = 2+V+Fpay,  //flit width;
        PFw = P * Fw,
        CONG_ALw = CONGw * P,    //  congestion width per router      
        W = WEIGHTw,
        WP = W * P,
        PRAw = P * RAw;    

    input clk,reset;
    input  [RAw-1 : 0] current_r_addr;    
    input  [PRAw-1 :  0] neighbors_r_addr;    
    input  [PFw-1 : 0]  flit_in_all;
    input  [P-1 : 0]  flit_in_we_all;
    output [PV-1 : 0]  credit_out_all;
    input  [CONG_ALw-1 : 0]  congestion_in_all;  
     
    output [PFw-1 : 0]  flit_out_all;
    output [P-1 : 0]  flit_out_we_all;
    input  [PV-1 : 0]  credit_in_all;
    output [CONG_ALw-1 : 0]  congestion_out_all;  

    router # (
        .V(V),
        .P(P),
        .B(B), 
        .T1(T1),
        .T2(T2),
	.T3(T3),
        .C(C),  
        .Fpay(Fpay),    
        .MUX_TYPE(MUX_TYPE),
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .COMBINATION_TYPE(COMBINATION_TYPE),
        .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),  
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .CONGw(CONGw),
        .DEBUG_EN(DEBUG_EN),
        .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING),   
        .ESCAP_VC_MASK(ESCAP_VC_MASK),
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw),
        .MIN_PCK_SIZE(MIN_PCK_SIZE)           
    )
    the_router
    (
        .current_r_addr(current_r_addr),
        .neighbors_r_addr(neighbors_r_addr),
        .flit_in_all(flit_in_all),
        .flit_in_we_all(flit_in_we_all),
        .credit_out_all(credit_out_all),
        .congestion_in_all(congestion_in_all),
        .flit_out_all(flit_out_all),
        .flit_out_we_all(flit_out_we_all),
        .credit_in_all(credit_in_all),
        .congestion_out_all(congestion_out_all),
        .clk(clk),
        .reset(reset)

    );
endmodule

/**************
Port num = 9
****************/ 

module router_verilator_p9
(
    current_r_addr,
    neighbors_r_addr,    
    flit_in_all,
    flit_in_we_all,
    credit_out_all,
    congestion_in_all,
    flit_out_all,
    flit_out_we_all,
    credit_in_all,
    congestion_out_all,
    clk,reset
);

    localparam P=9;   

    `define   INCLUDE_PARAM
    `include "parameter.v"

    `define INCLUDE_TOPOLOGY_LOCALPARAM
    `include "topology_localparam.v"
 

    localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;


   
    localparam         
        PV = V * P,
        P_1 = P-1,
        Fw = 2+V+Fpay,  //flit width;
        PFw = P * Fw,
        CONG_ALw = CONGw * P,    //  congestion width per router      
        W = WEIGHTw,
        WP = W * P,
        PRAw = P * RAw;    

    input clk,reset;
    input  [RAw-1 : 0] current_r_addr;    
    input  [PRAw-1 :  0] neighbors_r_addr;    
    input  [PFw-1 : 0]  flit_in_all;
    input  [P-1 : 0]  flit_in_we_all;
    output [PV-1 : 0]  credit_out_all;
    input  [CONG_ALw-1 : 0]  congestion_in_all;  
     
    output [PFw-1 : 0]  flit_out_all;
    output [P-1 : 0]  flit_out_we_all;
    input  [PV-1 : 0]  credit_in_all;
    output [CONG_ALw-1 : 0]  congestion_out_all;  

    router # (
        .V(V),
        .P(P),
        .B(B), 
        .T1(T1),
        .T2(T2),
	.T3(T3),
        .C(C),  
        .Fpay(Fpay),    
        .MUX_TYPE(MUX_TYPE),
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .COMBINATION_TYPE(COMBINATION_TYPE),
        .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),  
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .CONGw(CONGw),
        .DEBUG_EN(DEBUG_EN),
        .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING),   
        .ESCAP_VC_MASK(ESCAP_VC_MASK),
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw),
        .MIN_PCK_SIZE(MIN_PCK_SIZE)           
    )
    the_router
    (
        .current_r_addr(current_r_addr),
        .neighbors_r_addr(neighbors_r_addr),
        .flit_in_all(flit_in_all),
        .flit_in_we_all(flit_in_we_all),
        .credit_out_all(credit_out_all),
        .congestion_in_all(congestion_in_all),
        .flit_out_all(flit_out_all),
        .flit_out_we_all(flit_out_we_all),
        .credit_in_all(credit_in_all),
        .congestion_out_all(congestion_out_all),
        .clk(clk),
        .reset(reset)

    );
endmodule

/**************
Port num = 10
****************/ 

module router_verilator_p10
(
    current_r_addr,
    neighbors_r_addr,    
    flit_in_all,
    flit_in_we_all,
    credit_out_all,
    congestion_in_all,
    flit_out_all,
    flit_out_we_all,
    credit_in_all,
    congestion_out_all,
    clk,reset
);

    localparam P=10;   

    `define   INCLUDE_PARAM
    `include "parameter.v"

    `define INCLUDE_TOPOLOGY_LOCALPARAM
    `include "topology_localparam.v"
 

    localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;


   
    localparam         
        PV = V * P,
        P_1 = P-1,
        Fw = 2+V+Fpay,  //flit width;
        PFw = P * Fw,
        CONG_ALw = CONGw * P,    //  congestion width per router      
        W = WEIGHTw,
        WP = W * P,
        PRAw = P * RAw;    

    input clk,reset;
    input  [RAw-1 : 0] current_r_addr;    
    input  [PRAw-1 :  0] neighbors_r_addr;    
    input  [PFw-1 : 0]  flit_in_all;
    input  [P-1 : 0]  flit_in_we_all;
    output [PV-1 : 0]  credit_out_all;
    input  [CONG_ALw-1 : 0]  congestion_in_all;  
     
    output [PFw-1 : 0]  flit_out_all;
    output [P-1 : 0]  flit_out_we_all;
    input  [PV-1 : 0]  credit_in_all;
    output [CONG_ALw-1 : 0]  congestion_out_all;  

    router # (
        .V(V),
        .P(P),
        .B(B), 
        .T1(T1),
        .T2(T2),
	.T3(T3),
        .C(C),  
        .Fpay(Fpay),    
        .MUX_TYPE(MUX_TYPE),
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .COMBINATION_TYPE(COMBINATION_TYPE),
        .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),  
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .CONGw(CONGw),
        .DEBUG_EN(DEBUG_EN),
        .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING),   
        .ESCAP_VC_MASK(ESCAP_VC_MASK),
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw),
        .MIN_PCK_SIZE(MIN_PCK_SIZE)           
    )
    the_router
    (
        .current_r_addr(current_r_addr),
        .neighbors_r_addr(neighbors_r_addr),
        .flit_in_all(flit_in_all),
        .flit_in_we_all(flit_in_we_all),
        .credit_out_all(credit_out_all),
        .congestion_in_all(congestion_in_all),
        .flit_out_all(flit_out_all),
        .flit_out_we_all(flit_out_we_all),
        .credit_in_all(credit_in_all),
        .congestion_out_all(congestion_out_all),
        .clk(clk),
        .reset(reset)

    );
endmodule

/**************
Port num = 11
****************/ 

module router_verilator_p11
(
    current_r_addr,
    neighbors_r_addr,    
    flit_in_all,
    flit_in_we_all,
    credit_out_all,
    congestion_in_all,
    flit_out_all,
    flit_out_we_all,
    credit_in_all,
    congestion_out_all,
    clk,reset
);

    localparam P=11;   

    `define   INCLUDE_PARAM
    `include "parameter.v"

    `define INCLUDE_TOPOLOGY_LOCALPARAM
    `include "topology_localparam.v"
 

    localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;


   
    localparam         
        PV = V * P,
        P_1 = P-1,
        Fw = 2+V+Fpay,  //flit width;
        PFw = P * Fw,
        CONG_ALw = CONGw * P,    //  congestion width per router      
        W = WEIGHTw,
        WP = W * P,
        PRAw = P * RAw;    

    input clk,reset;
    input  [RAw-1 : 0] current_r_addr;    
    input  [PRAw-1 :  0] neighbors_r_addr;    
    input  [PFw-1 : 0]  flit_in_all;
    input  [P-1 : 0]  flit_in_we_all;
    output [PV-1 : 0]  credit_out_all;
    input  [CONG_ALw-1 : 0]  congestion_in_all;  
     
    output [PFw-1 : 0]  flit_out_all;
    output [P-1 : 0]  flit_out_we_all;
    input  [PV-1 : 0]  credit_in_all;
    output [CONG_ALw-1 : 0]  congestion_out_all;  

    router # (
        .V(V),
        .P(P),
        .B(B), 
        .T1(T1),
        .T2(T2),
	.T3(T3),
        .C(C),  
        .Fpay(Fpay),    
        .MUX_TYPE(MUX_TYPE),
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .COMBINATION_TYPE(COMBINATION_TYPE),
        .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),  
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .CONGw(CONGw),
        .DEBUG_EN(DEBUG_EN),
        .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING),   
        .ESCAP_VC_MASK(ESCAP_VC_MASK),
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw),
        .MIN_PCK_SIZE(MIN_PCK_SIZE)           
    )
    the_router
    (
        .current_r_addr(current_r_addr),
        .neighbors_r_addr(neighbors_r_addr),
        .flit_in_all(flit_in_all),
        .flit_in_we_all(flit_in_we_all),
        .credit_out_all(credit_out_all),
        .congestion_in_all(congestion_in_all),
        .flit_out_all(flit_out_all),
        .flit_out_we_all(flit_out_we_all),
        .credit_in_all(credit_in_all),
        .congestion_out_all(congestion_out_all),
        .clk(clk),
        .reset(reset)

    );
endmodule

/**************
Port num = 12
****************/ 

module router_verilator_p12
(
    current_r_addr,
    neighbors_r_addr,    
    flit_in_all,
    flit_in_we_all,
    credit_out_all,
    congestion_in_all,
    flit_out_all,
    flit_out_we_all,
    credit_in_all,
    congestion_out_all,
    clk,reset
);

    localparam P=12;   

    `define   INCLUDE_PARAM
    `include "parameter.v"

    `define INCLUDE_TOPOLOGY_LOCALPARAM
    `include "topology_localparam.v"
 

    localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;


   
    localparam         
        PV = V * P,
        P_1 = P-1,
        Fw = 2+V+Fpay,  //flit width;
        PFw = P * Fw,
        CONG_ALw = CONGw * P,    //  congestion width per router      
        W = WEIGHTw,
        WP = W * P,
        PRAw = P * RAw;    

    input clk,reset;
    input  [RAw-1 : 0] current_r_addr;    
    input  [PRAw-1 :  0] neighbors_r_addr;    
    input  [PFw-1 : 0]  flit_in_all;
    input  [P-1 : 0]  flit_in_we_all;
    output [PV-1 : 0]  credit_out_all;
    input  [CONG_ALw-1 : 0]  congestion_in_all;  
     
    output [PFw-1 : 0]  flit_out_all;
    output [P-1 : 0]  flit_out_we_all;
    input  [PV-1 : 0]  credit_in_all;
    output [CONG_ALw-1 : 0]  congestion_out_all;  

    router # (
        .V(V),
        .P(P),
        .B(B), 
        .T1(T1),
        .T2(T2),
	.T3(T3),
        .C(C),  
        .Fpay(Fpay),    
        .MUX_TYPE(MUX_TYPE),
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .COMBINATION_TYPE(COMBINATION_TYPE),
        .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),  
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .CONGw(CONGw),
        .DEBUG_EN(DEBUG_EN),
        .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING),   
        .ESCAP_VC_MASK(ESCAP_VC_MASK),
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw),
        .MIN_PCK_SIZE(MIN_PCK_SIZE)           
    )
    the_router
    (
        .current_r_addr(current_r_addr),
        .neighbors_r_addr(neighbors_r_addr),
        .flit_in_all(flit_in_all),
        .flit_in_we_all(flit_in_we_all),
        .credit_out_all(credit_out_all),
        .congestion_in_all(congestion_in_all),
        .flit_out_all(flit_out_all),
        .flit_out_we_all(flit_out_we_all),
        .credit_in_all(credit_in_all),
        .congestion_out_all(congestion_out_all),
        .clk(clk),
        .reset(reset)

    );
endmodule

/**************
Port num = 13
****************/ 

module router_verilator_p13
(
    current_r_addr,
    neighbors_r_addr,    
    flit_in_all,
    flit_in_we_all,
    credit_out_all,
    congestion_in_all,
    flit_out_all,
    flit_out_we_all,
    credit_in_all,
    congestion_out_all,
    clk,reset
);

    localparam P=13;   

    `define   INCLUDE_PARAM
    `include "parameter.v"

    `define INCLUDE_TOPOLOGY_LOCALPARAM
    `include "topology_localparam.v"
 

    localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;


   
    localparam         
        PV = V * P,
        P_1 = P-1,
        Fw = 2+V+Fpay,  //flit width;
        PFw = P * Fw,
        CONG_ALw = CONGw * P,    //  congestion width per router      
        W = WEIGHTw,
        WP = W * P,
        PRAw = P * RAw;    

    input clk,reset;
    input  [RAw-1 : 0] current_r_addr;    
    input  [PRAw-1 :  0] neighbors_r_addr;    
    input  [PFw-1 : 0]  flit_in_all;
    input  [P-1 : 0]  flit_in_we_all;
    output [PV-1 : 0]  credit_out_all;
    input  [CONG_ALw-1 : 0]  congestion_in_all;  
     
    output [PFw-1 : 0]  flit_out_all;
    output [P-1 : 0]  flit_out_we_all;
    input  [PV-1 : 0]  credit_in_all;
    output [CONG_ALw-1 : 0]  congestion_out_all;  

    router # (
        .V(V),
        .P(P),
        .B(B), 
        .T1(T1),
        .T2(T2),
	.T3(T3),
        .C(C),  
        .Fpay(Fpay),    
        .MUX_TYPE(MUX_TYPE),
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .COMBINATION_TYPE(COMBINATION_TYPE),
        .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),  
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .CONGw(CONGw),
        .DEBUG_EN(DEBUG_EN),
        .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING),   
        .ESCAP_VC_MASK(ESCAP_VC_MASK),
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw),
        .MIN_PCK_SIZE(MIN_PCK_SIZE)           
    )
    the_router
    (
        .current_r_addr(current_r_addr),
        .neighbors_r_addr(neighbors_r_addr),
        .flit_in_all(flit_in_all),
        .flit_in_we_all(flit_in_we_all),
        .credit_out_all(credit_out_all),
        .congestion_in_all(congestion_in_all),
        .flit_out_all(flit_out_all),
        .flit_out_we_all(flit_out_we_all),
        .credit_in_all(credit_in_all),
        .congestion_out_all(congestion_out_all),
        .clk(clk),
        .reset(reset)

    );
endmodule

/**************
Port num = 14
****************/ 

module router_verilator_p14
(
    current_r_addr,
    neighbors_r_addr,    
    flit_in_all,
    flit_in_we_all,
    credit_out_all,
    congestion_in_all,
    flit_out_all,
    flit_out_we_all,
    credit_in_all,
    congestion_out_all,
    clk,reset
);

    localparam P=14;   

    `define   INCLUDE_PARAM
    `include "parameter.v"

    `define INCLUDE_TOPOLOGY_LOCALPARAM
    `include "topology_localparam.v"
 

    localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;


   
    localparam         
        PV = V * P,
        P_1 = P-1,
        Fw = 2+V+Fpay,  //flit width;
        PFw = P * Fw,
        CONG_ALw = CONGw * P,    //  congestion width per router      
        W = WEIGHTw,
        WP = W * P,
        PRAw = P * RAw;    

    input clk,reset;
    input  [RAw-1 : 0] current_r_addr;    
    input  [PRAw-1 :  0] neighbors_r_addr;    
    input  [PFw-1 : 0]  flit_in_all;
    input  [P-1 : 0]  flit_in_we_all;
    output [PV-1 : 0]  credit_out_all;
    input  [CONG_ALw-1 : 0]  congestion_in_all;  
     
    output [PFw-1 : 0]  flit_out_all;
    output [P-1 : 0]  flit_out_we_all;
    input  [PV-1 : 0]  credit_in_all;
    output [CONG_ALw-1 : 0]  congestion_out_all;  

    router # (
        .V(V),
        .P(P),
        .B(B), 
        .T1(T1),
        .T2(T2),
	.T3(T3),
        .C(C),  
        .Fpay(Fpay),    
        .MUX_TYPE(MUX_TYPE),
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .COMBINATION_TYPE(COMBINATION_TYPE),
        .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),  
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .CONGw(CONGw),
        .DEBUG_EN(DEBUG_EN),
        .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING),   
        .ESCAP_VC_MASK(ESCAP_VC_MASK),
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw),
        .MIN_PCK_SIZE(MIN_PCK_SIZE)           
    )
    the_router
    (
        .current_r_addr(current_r_addr),
        .neighbors_r_addr(neighbors_r_addr),
        .flit_in_all(flit_in_all),
        .flit_in_we_all(flit_in_we_all),
        .credit_out_all(credit_out_all),
        .congestion_in_all(congestion_in_all),
        .flit_out_all(flit_out_all),
        .flit_out_we_all(flit_out_we_all),
        .credit_in_all(credit_in_all),
        .congestion_out_all(congestion_out_all),
        .clk(clk),
        .reset(reset)

    );
endmodule

/**************
Port num = 15
****************/ 

module router_verilator_p15
(
    current_r_addr,
    neighbors_r_addr,    
    flit_in_all,
    flit_in_we_all,
    credit_out_all,
    congestion_in_all,
    flit_out_all,
    flit_out_we_all,
    credit_in_all,
    congestion_out_all,
    clk,reset
);

    localparam P=15;   

    `define   INCLUDE_PARAM
    `include "parameter.v"

    `define INCLUDE_TOPOLOGY_LOCALPARAM
    `include "topology_localparam.v"
 

    localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;


   
    localparam         
        PV = V * P,
        P_1 = P-1,
        Fw = 2+V+Fpay,  //flit width;
        PFw = P * Fw,
        CONG_ALw = CONGw * P,    //  congestion width per router      
        W = WEIGHTw,
        WP = W * P,
        PRAw = P * RAw;    

    input clk,reset;
    input  [RAw-1 : 0] current_r_addr;    
    input  [PRAw-1 :  0] neighbors_r_addr;    
    input  [PFw-1 : 0]  flit_in_all;
    input  [P-1 : 0]  flit_in_we_all;
    output [PV-1 : 0]  credit_out_all;
    input  [CONG_ALw-1 : 0]  congestion_in_all;  
     
    output [PFw-1 : 0]  flit_out_all;
    output [P-1 : 0]  flit_out_we_all;
    input  [PV-1 : 0]  credit_in_all;
    output [CONG_ALw-1 : 0]  congestion_out_all;  

    router # (
        .V(V),
        .P(P),
        .B(B), 
        .T1(T1),
        .T2(T2),
	.T3(T3),
        .C(C),  
        .Fpay(Fpay),    
        .MUX_TYPE(MUX_TYPE),
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .COMBINATION_TYPE(COMBINATION_TYPE),
        .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),  
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .CONGw(CONGw),
        .DEBUG_EN(DEBUG_EN),
        .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING),   
        .ESCAP_VC_MASK(ESCAP_VC_MASK),
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw),
        .MIN_PCK_SIZE(MIN_PCK_SIZE)           
    )
    the_router
    (
        .current_r_addr(current_r_addr),
        .neighbors_r_addr(neighbors_r_addr),
        .flit_in_all(flit_in_all),
        .flit_in_we_all(flit_in_we_all),
        .credit_out_all(credit_out_all),
        .congestion_in_all(congestion_in_all),
        .flit_out_all(flit_out_all),
        .flit_out_we_all(flit_out_we_all),
        .credit_in_all(credit_in_all),
        .congestion_out_all(congestion_out_all),
        .clk(clk),
        .reset(reset)

    );
endmodule

/**************
Port num = 16
****************/ 

module router_verilator_p16
(
    current_r_addr,
    neighbors_r_addr,    
    flit_in_all,
    flit_in_we_all,
    credit_out_all,
    congestion_in_all,
    flit_out_all,
    flit_out_we_all,
    credit_in_all,
    congestion_out_all,
    clk,reset
);

    localparam P=16;   

    `define   INCLUDE_PARAM
    `include "parameter.v"

    `define INCLUDE_TOPOLOGY_LOCALPARAM
    `include "topology_localparam.v"
 

    localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;


   
    localparam         
        PV = V * P,
        P_1 = P-1,
        Fw = 2+V+Fpay,  //flit width;
        PFw = P * Fw,
        CONG_ALw = CONGw * P,    //  congestion width per router      
        W = WEIGHTw,
        WP = W * P,
        PRAw = P * RAw;    

    input clk,reset;
    input  [RAw-1 : 0] current_r_addr;    
    input  [PRAw-1 :  0] neighbors_r_addr;    
    input  [PFw-1 : 0]  flit_in_all;
    input  [P-1 : 0]  flit_in_we_all;
    output [PV-1 : 0]  credit_out_all;
    input  [CONG_ALw-1 : 0]  congestion_in_all;  
     
    output [PFw-1 : 0]  flit_out_all;
    output [P-1 : 0]  flit_out_we_all;
    input  [PV-1 : 0]  credit_in_all;
    output [CONG_ALw-1 : 0]  congestion_out_all;  

    router # (
        .V(V),
        .P(P),
        .B(B), 
        .T1(T1),
        .T2(T2),
	.T3(T3),
        .C(C),  
        .Fpay(Fpay),    
        .MUX_TYPE(MUX_TYPE),
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .COMBINATION_TYPE(COMBINATION_TYPE),
        .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),  
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .CONGw(CONGw),
        .DEBUG_EN(DEBUG_EN),
        .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING),   
        .ESCAP_VC_MASK(ESCAP_VC_MASK),
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw),
        .MIN_PCK_SIZE(MIN_PCK_SIZE)           
    )
    the_router
    (
        .current_r_addr(current_r_addr),
        .neighbors_r_addr(neighbors_r_addr),
        .flit_in_all(flit_in_all),
        .flit_in_we_all(flit_in_we_all),
        .credit_out_all(credit_out_all),
        .congestion_in_all(congestion_in_all),
        .flit_out_all(flit_out_all),
        .flit_out_we_all(flit_out_we_all),
        .credit_in_all(credit_in_all),
        .congestion_out_all(congestion_out_all),
        .clk(clk),
        .reset(reset)

    );
endmodule

/**************
Port num = 17
****************/ 

module router_verilator_p17
(
    current_r_addr,
    neighbors_r_addr,    
    flit_in_all,
    flit_in_we_all,
    credit_out_all,
    congestion_in_all,
    flit_out_all,
    flit_out_we_all,
    credit_in_all,
    congestion_out_all,
    clk,reset
);

    localparam P=17;   

    `define   INCLUDE_PARAM
    `include "parameter.v"

    `define INCLUDE_TOPOLOGY_LOCALPARAM
    `include "topology_localparam.v"
 

    localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;


   
    localparam         
        PV = V * P,
        P_1 = P-1,
        Fw = 2+V+Fpay,  //flit width;
        PFw = P * Fw,
        CONG_ALw = CONGw * P,    //  congestion width per router      
        W = WEIGHTw,
        WP = W * P,
        PRAw = P * RAw;    

    input clk,reset;
    input  [RAw-1 : 0] current_r_addr;    
    input  [PRAw-1 :  0] neighbors_r_addr;    
    input  [PFw-1 : 0]  flit_in_all;
    input  [P-1 : 0]  flit_in_we_all;
    output [PV-1 : 0]  credit_out_all;
    input  [CONG_ALw-1 : 0]  congestion_in_all;  
     
    output [PFw-1 : 0]  flit_out_all;
    output [P-1 : 0]  flit_out_we_all;
    input  [PV-1 : 0]  credit_in_all;
    output [CONG_ALw-1 : 0]  congestion_out_all;  

    router # (
        .V(V),
        .P(P),
        .B(B), 
        .T1(T1),
        .T2(T2),
	.T3(T3),
        .C(C),  
        .Fpay(Fpay),    
        .MUX_TYPE(MUX_TYPE),
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .COMBINATION_TYPE(COMBINATION_TYPE),
        .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),  
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .CONGw(CONGw),
        .DEBUG_EN(DEBUG_EN),
        .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING),   
        .ESCAP_VC_MASK(ESCAP_VC_MASK),
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw),
        .MIN_PCK_SIZE(MIN_PCK_SIZE)           
    )
    the_router
    (
        .current_r_addr(current_r_addr),
        .neighbors_r_addr(neighbors_r_addr),
        .flit_in_all(flit_in_all),
        .flit_in_we_all(flit_in_we_all),
        .credit_out_all(credit_out_all),
        .congestion_in_all(congestion_in_all),
        .flit_out_all(flit_out_all),
        .flit_out_we_all(flit_out_we_all),
        .credit_in_all(credit_in_all),
        .congestion_out_all(congestion_out_all),
        .clk(clk),
        .reset(reset)

    );
endmodule

/**************
Port num = 18
****************/ 

module router_verilator_p18
(
    current_r_addr,
    neighbors_r_addr,    
    flit_in_all,
    flit_in_we_all,
    credit_out_all,
    congestion_in_all,
    flit_out_all,
    flit_out_we_all,
    credit_in_all,
    congestion_out_all,
    clk,reset
);

    localparam P=18;   

    `define   INCLUDE_PARAM
    `include "parameter.v"

    `define INCLUDE_TOPOLOGY_LOCALPARAM
    `include "topology_localparam.v"
 

    localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;


   
    localparam         
        PV = V * P,
        P_1 = P-1,
        Fw = 2+V+Fpay,  //flit width;
        PFw = P * Fw,
        CONG_ALw = CONGw * P,    //  congestion width per router      
        W = WEIGHTw,
        WP = W * P,
        PRAw = P * RAw;    

    input clk,reset;
    input  [RAw-1 : 0] current_r_addr;    
    input  [PRAw-1 :  0] neighbors_r_addr;    
    input  [PFw-1 : 0]  flit_in_all;
    input  [P-1 : 0]  flit_in_we_all;
    output [PV-1 : 0]  credit_out_all;
    input  [CONG_ALw-1 : 0]  congestion_in_all;  
     
    output [PFw-1 : 0]  flit_out_all;
    output [P-1 : 0]  flit_out_we_all;
    input  [PV-1 : 0]  credit_in_all;
    output [CONG_ALw-1 : 0]  congestion_out_all;  

    router # (
        .V(V),
        .P(P),
        .B(B), 
        .T1(T1),
        .T2(T2),
	.T3(T3),
        .C(C),  
        .Fpay(Fpay),    
        .MUX_TYPE(MUX_TYPE),
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .COMBINATION_TYPE(COMBINATION_TYPE),
        .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),  
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .CONGw(CONGw),
        .DEBUG_EN(DEBUG_EN),
        .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING),   
        .ESCAP_VC_MASK(ESCAP_VC_MASK),
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw),
        .MIN_PCK_SIZE(MIN_PCK_SIZE)           
    )
    the_router
    (
        .current_r_addr(current_r_addr),
        .neighbors_r_addr(neighbors_r_addr),
        .flit_in_all(flit_in_all),
        .flit_in_we_all(flit_in_we_all),
        .credit_out_all(credit_out_all),
        .congestion_in_all(congestion_in_all),
        .flit_out_all(flit_out_all),
        .flit_out_we_all(flit_out_we_all),
        .credit_in_all(credit_in_all),
        .congestion_out_all(congestion_out_all),
        .clk(clk),
        .reset(reset)

    );
endmodule

/**************
Port num = 19
****************/ 

module router_verilator_p19
(
    current_r_addr,
    neighbors_r_addr,    
    flit_in_all,
    flit_in_we_all,
    credit_out_all,
    congestion_in_all,
    flit_out_all,
    flit_out_we_all,
    credit_in_all,
    congestion_out_all,
    clk,reset
);

    localparam P=19;   

    `define   INCLUDE_PARAM
    `include "parameter.v"

    `define INCLUDE_TOPOLOGY_LOCALPARAM
    `include "topology_localparam.v"
 

    localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;


   
    localparam         
        PV = V * P,
        P_1 = P-1,
        Fw = 2+V+Fpay,  //flit width;
        PFw = P * Fw,
        CONG_ALw = CONGw * P,    //  congestion width per router      
        W = WEIGHTw,
        WP = W * P,
        PRAw = P * RAw;    

    input clk,reset;
    input  [RAw-1 : 0] current_r_addr;    
    input  [PRAw-1 :  0] neighbors_r_addr;    
    input  [PFw-1 : 0]  flit_in_all;
    input  [P-1 : 0]  flit_in_we_all;
    output [PV-1 : 0]  credit_out_all;
    input  [CONG_ALw-1 : 0]  congestion_in_all;  
     
    output [PFw-1 : 0]  flit_out_all;
    output [P-1 : 0]  flit_out_we_all;
    input  [PV-1 : 0]  credit_in_all;
    output [CONG_ALw-1 : 0]  congestion_out_all;  

    router # (
        .V(V),
        .P(P),
        .B(B), 
        .T1(T1),
        .T2(T2),
	.T3(T3),
        .C(C),  
        .Fpay(Fpay),    
        .MUX_TYPE(MUX_TYPE),
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .COMBINATION_TYPE(COMBINATION_TYPE),
        .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),  
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .CONGw(CONGw),
        .DEBUG_EN(DEBUG_EN),
        .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING),   
        .ESCAP_VC_MASK(ESCAP_VC_MASK),
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw),
        .MIN_PCK_SIZE(MIN_PCK_SIZE)           
    )
    the_router
    (
        .current_r_addr(current_r_addr),
        .neighbors_r_addr(neighbors_r_addr),
        .flit_in_all(flit_in_all),
        .flit_in_we_all(flit_in_we_all),
        .credit_out_all(credit_out_all),
        .congestion_in_all(congestion_in_all),
        .flit_out_all(flit_out_all),
        .flit_out_we_all(flit_out_we_all),
        .credit_in_all(credit_in_all),
        .congestion_out_all(congestion_out_all),
        .clk(clk),
        .reset(reset)

    );
endmodule

