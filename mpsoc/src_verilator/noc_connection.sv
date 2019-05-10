`timescale     1ns/1ps


module noc_connection (
    
    /*
    reset,
    clk,    
    flit_out_all,
    flit_out_wr_all, 
    credit_in_all,
    flit_in_all,  
    flit_in_wr_all,  
    credit_out_all
    */
 clk,
 reset,
 start_i,
 start_o,
 router_flit_out_all, 
 router_flit_out_we_all,    
 router_credit_in_all,
 router_credit_out_all,
 router_flit_in_all,     
 router_flit_in_we_all,
 router_congestion_in_all,
 router_congestion_out_all,
// router_iport_weight_in_all,
// router_iport_weight_out_all, 
 ni_flit_in,    
 ni_flit_in_wr, 
 ni_credit_out,                 
 ni_flit_out, 
 ni_flit_out_wr,  
 ni_credit_in,
 er_addr,// endpoints connected to each router   
 current_r_addr,
 neighbors_r_addr
);
    


  
    `define  INCLUDE_PARAM
    `include"parameter.v"
    
     `define INCLUDE_TOPOLOGY_LOCALPARAM
    `include "topology_localparam.v"
   
    
    localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;


   
    localparam
        PV = V * MAX_P,
        Fw = 2+V+Fpay, //flit width;    
        PFw = MAX_P * Fw,
        CONG_ALw = CONGw * MAX_P, // congestion width per router            
        W= WEIGHTw,
        WP = W * MAX_P,
        PRAw= RAw * MAX_P;                   
                    
                    
    output [PFw-1 : 0] router_flit_out_all [NR-1 : 0];
    output [MAX_P-1 : 0] router_flit_out_we_all [NR-1 : 0];    
    input  [PV-1 : 0] router_credit_in_all [NR-1 : 0];
    
    
    input  [PFw-1 : 0] router_flit_in_all [NR-1 : 0];
    input  [MAX_P-1 : 0] router_flit_in_we_all [NR-1 : 0];
    output [PV-1 : 0] router_credit_out_all[NR-1: 0];                    
    
    input  [CONG_ALw-1  :   0] router_congestion_in_all [NR-1         :0];    
    output [CONG_ALw-1  :   0] router_congestion_out_all  [NR-1         :0]; 
 
    
    input  [Fw-1 : 0] ni_flit_in [NE-1 : 0];   
    input  [NE-1 : 0] ni_flit_in_wr; 
    output [V-1 : 0] ni_credit_out [NE-1 : 0];
    output [Fw-1 : 0] ni_flit_out [NE-1 : 0];   
    output [NE-1 : 0] ni_flit_out_wr;  
    input  [V-1 : 0]  ni_credit_in [NE-1 : 0]; 

    output [RAw-1 :	0] current_r_addr [NR-1 : 0];
    output [RAw-1 : 0] er_addr [NE-1 : 0];
    output [PRAw-1 :0] neighbors_r_addr [NR-1 :0];//get a fixed value for each individual router
 
   
    
    input clk,reset, start_i;
    
    
    output [NE-1 : 0] start_o;


generate 
    /* verilator lint_off WIDTH */ 
    if( TOPOLOGY == "FATTREE") begin : fat
    /* verilator lint_on WIDTH */  
       
        fattree_noc_connection connections
        (    
         .clk(clk),
         .reset(reset),
         .start_i(start_i),
         .start_o(start_o),
         .router_flit_out_all(router_flit_out_all), 
         .router_flit_out_we_all(router_flit_out_we_all),    
         .router_credit_in_all(router_credit_in_all),
         .router_credit_out_all(router_credit_out_all),
         .router_flit_in_all(router_flit_in_all),     
         .router_flit_in_we_all(router_flit_in_we_all),
         .router_congestion_in_all(router_congestion_in_all),
         .router_congestion_out_all(router_congestion_out_all),
         .ni_flit_in(ni_flit_in),    
         .ni_flit_in_wr(ni_flit_in_wr), 
         .ni_credit_out(ni_credit_out),                 
         .ni_flit_out(ni_flit_out), 
         .ni_flit_out_wr(ni_flit_out_wr),  
         .ni_credit_in(ni_credit_in),
         .er_addr(er_addr),
         .current_r_addr(current_r_addr),
         .neighbors_r_all(neighbors_r_addr)    
        );
     /* verilator lint_off WIDTH */    
    end else if( TOPOLOGY == "TREE") begin : fat
    /* verilator lint_on WIDTH */  
       
        tree_noc_connection  connections
        (    
         .clk(clk),
         .reset(reset),
         .start_i(start_i),
         .start_o(start_o),
         .router_flit_out_all(router_flit_out_all), 
         .router_flit_out_we_all(router_flit_out_we_all),    
         .router_credit_in_all(router_credit_in_all),
         .router_credit_out_all(router_credit_out_all),
         .router_flit_in_all(router_flit_in_all),     
         .router_flit_in_we_all(router_flit_in_we_all),
         .router_congestion_in_all(router_congestion_in_all),
         .router_congestion_out_all(router_congestion_out_all),
         .ni_flit_in(ni_flit_in),    
         .ni_flit_in_wr(ni_flit_in_wr), 
         .ni_credit_out(ni_credit_out),                 
         .ni_flit_out(ni_flit_out), 
         .ni_flit_out_wr(ni_flit_out_wr),  
         .ni_credit_in(ni_credit_in),
         .er_addr(er_addr),
         .current_r_addr(current_r_addr),
         .neighbors_r_all(neighbors_r_addr)    
        );       
       
    end else begin :mesh_torus
        mesh_torus_noc_connection connections
       (    
         .clk(clk),
         .reset(reset),
         .start_i(start_i),
         .start_o(start_o),
         .router_flit_out_all(router_flit_out_all), 
         .router_flit_out_we_all(router_flit_out_we_all),    
         .router_credit_in_all(router_credit_in_all),
         .router_credit_out_all(router_credit_out_all),
         .router_flit_in_all(router_flit_in_all),     
         .router_flit_in_we_all(router_flit_in_we_all),
         .router_congestion_in_all(router_congestion_in_all),
         .router_congestion_out_all(router_congestion_out_all),
         .ni_flit_in(ni_flit_in),    
         .ni_flit_in_wr(ni_flit_in_wr), 
         .ni_credit_out(ni_credit_out),                 
         .ni_flit_out(ni_flit_out), 
         .ni_flit_out_wr(ni_flit_out_wr),  
         .ni_credit_in(ni_credit_in),
	     .er_addr(er_addr),
    	 .current_r_addr(current_r_addr)  	
    
);

    end
  endgenerate
endmodule

