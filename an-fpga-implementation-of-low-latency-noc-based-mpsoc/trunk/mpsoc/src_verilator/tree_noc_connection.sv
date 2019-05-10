// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

module tree_noc_connection (   
   
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

 ni_flit_in,    
 ni_flit_in_wr, 
 ni_credit_out,                 
 ni_flit_out, 
 ni_flit_out_wr,  
 ni_credit_in,
 er_addr,
 current_r_addr,
 neighbors_r_all
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
        
  function integer addrencode;
        input integer pos,k,n,kw;
        integer pow,i,tmp;begin
        addrencode=0;
        pow=1;
        for (i = 0; i <n; i=i+1 ) begin 
            tmp=(pos/pow);
            tmp=tmp%k;
            tmp=tmp<<i*kw;
            addrencode=addrencode | tmp;
            pow=pow * k;
        end
        end   
    endfunction // log2 
        
    
    
    localparam
        PV = V * MAX_P,
        Fw = 2+V+Fpay, //flit width;    
        PFw = MAX_P * Fw,
        NEFw = NE * Fw,
        NEV = NE * V,
        CONG_ALw = CONGw * MAX_P,
        PLKw = MAX_P * LKw,
        PLw = MAX_P * Lw,       
        PRAw = MAX_P * RAw; // {layer , Pos} width
                
                    
   
    input reset,clk;      
    
    
                    
     
    output [PFw-1 : 0] router_flit_out_all [NR-1 :0];
    output [MAX_P-1 : 0] router_flit_out_we_all [NR-1 :0];    
    input  [PV-1 : 0] router_credit_in_all [NR-1 :0];    
    input  [PFw-1 : 0] router_flit_in_all [NR-1 :0];
    input  [MAX_P-1 : 0] router_flit_in_we_all [NR-1 :0];
    output [PV-1 : 0] router_credit_out_all[NR-1 :0]; 
    input  [CONG_ALw-1: 0] router_congestion_in_all[NR-1 :0];  
    output [CONG_ALw-1: 0] router_congestion_out_all [NR-1 :0];   
  
    input  [Fw-1 : 0] ni_flit_in [NE-1 :0];   
    input  [NE-1 : 0] ni_flit_in_wr; 
    output [V-1 : 0] ni_credit_out [NE-1 :0];
    output [Fw-1 : 0] ni_flit_out [NE-1 :0];   
    output [NE-1 : 0] ni_flit_out_wr;  
    input  [V-1 : 0] ni_credit_in [NE-1 :0];

    wire [PLKw-1 : 0]  neighbors_pos_all [NR-1 :0];//get a fixed value for each individual router
    wire [PLw-1  : 0]  neighbors_layer_all [NR-1 :0];   
    output [PRAw-1 : 0]  neighbors_r_all [NR-1 :0];
    
    output [RAw-1 : 0] er_addr [NE-1 : 0]; // provide router address for each connected endpoint
    
    wire [LKw-1 : 0]  current_pos_addr [NR-1 :0];
    wire [Lw-1  : 0]  current_layer_addr [NR-1 :0];   
    output [RAw-1 : 0] current_r_addr [NR-1 : 0];
    
     
    input  start_i;
    output [NE-1 : 0] start_o;
 
    
    localparam ROOT_L = L-1; 
    localparam ROOT_ID = 0;
 
    assign current_layer_addr [ROOT_ID] = ROOT_L[Lw-1 : 0];
    assign current_pos_addr [ROOT_ID] = {LKw{1'b0}};       
    assign current_r_addr[ROOT_ID] = {current_layer_addr [ROOT_ID],current_pos_addr[ROOT_ID]}; 
 
  genvar pos,level,port;  
 generate   
//connect all up connections
for (level = 1; level<L; level=level+1) begin : level_c
    localparam NPOS = powi(K,level); // number of routers in this level
    localparam L1 = L-1-level;
    localparam level2= level - 1;
    localparam L2 = L-1-level2;
    for ( pos = 0; pos < NPOS; pos=pos+1 ) begin : pos_c
        localparam ID1 = sum_powi ( K,level) + pos;        
        localparam FATTREE_EQ_POS1 = pos*(K**L1);
        localparam ADR_CODE1=addrencode(FATTREE_EQ_POS1,K,L,Kw);       
        localparam POS2 = pos /K ;
        localparam ID2 = sum_powi ( K,level-1) + (pos/K);
        localparam PORT2= pos % K;  
        localparam FATTREE_EQ_POS2 = POS2*(K**L2);
        localparam ADR_CODE2=addrencode(FATTREE_EQ_POS2,K,L,Kw);
        
        // node_connection('Router[id1][k] to router[id2][pos%k];  
                  
            assign  router_flit_out_all   [ID1][(K+1)*Fw-1 : K*Fw] = router_flit_in_all [ID2][(PORT2+1)*Fw-1 : PORT2*Fw];
            assign  router_flit_out_all   [ID2][(PORT2+1)*Fw-1 : PORT2*Fw] = router_flit_in_all [ID1][(K+1)*Fw-1 : K*Fw];  

            assign  router_credit_out_all [ID1][(K+1)*V-1 : K*V]= router_credit_in_all  [ID2][(PORT2+1)*V-1 : PORT2*V];
            assign  router_credit_out_all [ID2][(PORT2+1)*V-1 : PORT2*V]= router_credit_in_all [ID1][(K+1)*V-1 : K*V];


            assign  router_flit_out_we_all[ID1][K] = router_flit_in_we_all [ID2][PORT2];
            assign  router_flit_out_we_all[ID2][PORT2] = router_flit_in_we_all [ID1][K];

            assign  router_congestion_out_all  [ID1][(K+1)*CONGw-1 : K*CONGw]  = router_congestion_in_all  [ID2][(PORT2+1)*CONGw-1 : PORT2*CONGw];
            assign  router_congestion_out_all [ID2][(PORT2+1)*CONGw-1 : PORT2*CONGw] = router_congestion_in_all [ID1][(K+1)*CONGw-1 : K*CONGw];
            
            assign  neighbors_pos_all[ID1][(K+1)*LKw-1 : K*LKw] = ADR_CODE2 [LKw-1 :0];
            assign  neighbors_pos_all[ID2][(PORT2+1)*LKw-1 : PORT2*LKw] = ADR_CODE1[LKw-1 :0];
            
            assign  neighbors_layer_all[ID1][(K+1)*Lw-1 : K*Lw] =  L2 [Lw-1 : 0];
            assign  neighbors_layer_all[ID2][(PORT2+1)*Lw-1 : PORT2*Lw] =L1 [Lw-1 : 0];   
            
            assign  neighbors_r_all[ID1][(K+1)*RAw-1 : K*RAw]   = {neighbors_layer_all[ID1][(K+1)*Lw-1 : K*Lw],neighbors_pos_all[ID1][(K+1)*LKw-1 : K*LKw]};
            assign  neighbors_r_all[ID2][(PORT2+1)*RAw-1 : PORT2*RAw] = {neighbors_layer_all[ID2][(PORT2+1)*Lw-1 : PORT2*Lw],neighbors_pos_all[ID2][(PORT2+1)*LKw-1 : PORT2*LKw]};
        
            assign current_layer_addr [ID1] = L1[Lw-1 : 0];
            assign current_pos_addr [ID1] = ADR_CODE1 [LKw-1 : 0];         
            assign current_r_addr [ID1] = {current_layer_addr [ID1],current_pos_addr[ID1]};
        
        
        end// pos
    
end //level
          
    
for ( pos = 0; pos <  NE; pos=pos+1 ) begin : endpoints
    localparam RID= sum_powi(K,L-1)+(pos/K);
    localparam RPORT = pos%K;
    //connected router encoded address
    localparam  CURRENTPOS=   addrencode(pos/K,K,L,Kw);
  
    
     //$dotfile=$dotfile.node_connection('T',$i,undef,undef,'R',$r,undef,$i%($k));    
 
            assign router_flit_out_all [RID][(RPORT+1)*Fw-1 : RPORT*Fw] =    ni_flit_in [pos];
            assign router_credit_out_all [RID][(RPORT+1)*V-1 : RPORT*V] =    ni_credit_in [pos];
            assign router_flit_out_we_all [RID][RPORT] =    ni_flit_in_wr [pos];
            assign router_congestion_out_all[RID][(RPORT+1)*CONGw-1 : RPORT*CONGw] =   {CONGw{1'b0}}; 
           // assign  neighbors_layer_all[RID][(RPORT+1)*Lw-1 : RPORT*Lw] = {Lw{1'b0}};                 
            assign  neighbors_r_all[RID][(RPORT+1)*RAw-1 : RPORT*RAw]   = {RAw{1'b0}};            
            
            assign ni_flit_out [pos] = router_flit_in_all [RID][(RPORT+1)*Fw-1 : RPORT*Fw]; 
            assign ni_flit_out_wr [pos] = router_flit_in_we_all[RID][RPORT];
            assign ni_credit_out [pos] = router_credit_in_all [RID][(RPORT+1)*V-1 : RPORT*V];             
            assign er_addr [pos] = CURRENTPOS [RAw-1 : 0];
         
 
end//pos
 
 endgenerate    
    
    start_delay_gen #(
        .NC(NE)
    )
    delay_gen
    (
        .clk(clk),
        .reset(reset),
        .start_i(start_i),
        .start_o(start_o)
    );


endmodule

