`include "pronoc_def.v"
/**************************************
*
*   tree route function
*
***************************************/

// ============================================================
//  TREE: Nearest Common Ancestor w
// ============================================================

module tree_nca_routing  #(
   parameter K   = 2, // number of last level individual router`s endpoints.
   parameter L   = 2 // Fattree layer number (The height of FT)
)(
    current_addr_encoded,    // connected to current router x address
    current_level,    //connected to current router y address
    dest_addr_encoded,        // destination address
    destport_encoded    // router output port
);
    function integer log2;
    input integer number; begin   
        log2=(number <=1) ? 1: 0;    
        while(2**log2<number) begin    
            log2=log2+1;    
        end        
    end   
    endfunction // log2 
    
    localparam
        Kw = log2(K),
        LKw= L*Kw,
        Lw = log2(L),
        DSPw= log2(K+1);       
    
    input  [LKw-1 : 0]    current_addr_encoded;
    input  [Lw-1 : 0]    current_level;    
    input  [LKw-1 : 0]    dest_addr_encoded;
    output [DSPw-1: 0]    destport_encoded;
    
    /******************
    * There is always one destination path that can be
    * selected for each destination endpoint. Hence we 
    * can use the binary address of destination port      
    *******************/   
    
    wire  [Kw-1 : 0]  current_addr [L-1 : 0];
    wire  [Kw-1 : 0]  parrent_dest_addr [L-1 : 0];
    wire  [Kw-1 : 0]  dest_addr [L-1 : 0];
    wire  [DSPw-1 : 0]  current_node_dest_port;
    wire [L-1 : 0] parrents_node_missmatch;   
    
    assign current_addr [0]={Kw{1'b0}}; 
    assign parrent_dest_addr [0]={Kw{1'b0}}; 
    
    genvar i;
    generate 
    for(i=1; i<L; i=i+1)begin : caddr
        /* verilator lint_off WIDTH */ 
        assign current_addr [i] = (current_level <i)? current_addr_encoded[i*Kw-1 : (i-1)*Kw] : {Kw{1'b0}};
        assign parrent_dest_addr [i] = (current_level<i)? dest_addr_encoded[(i+1)*Kw-1 : i*Kw] : {Kw{1'b0}};
        /* verilator lint_on WIDTH */ 
    end
    
    for(i=0; i<L; i=i+1) begin : daddr
    // assign current_addr [i] = (current_level >=i)? current_addr_encoded[(i+1)*Kw-1 : i*Kw] : {Kw{1'b0}};
        assign dest_addr [i] =  dest_addr_encoded[(i+1)*Kw-1 : i*Kw];
        assign parrents_node_missmatch[i]=  current_addr [i] !=  parrent_dest_addr [i]; 
    end//for
    
    if(DSPw==Kw) begin :eq
        assign current_node_dest_port = dest_addr[current_level];
    end else begin :neq
        assign current_node_dest_port = {1'b0,dest_addr[current_level]};
    end    
    endgenerate
    assign destport_encoded = (parrents_node_missmatch != {L{1'b0}}) ? /*go up*/ K[DSPw-1: 0] : /*go down*/current_node_dest_port;
endmodule


/*************************
*  tree_conventional_routing 
***********************/
module tree_conventional_routing #(
    parameter ROUTE_NAME = "NCA",
    parameter K   = 2, // number of last level individual router`s endpoints.
    parameter L   = 2 // Fattree layer number (The height of FT)
)(
    current_addr_encoded,    // connected to current router x address
    current_level,    //connected to current router y address
    dest_addr_encoded,        // destination address
    destport_encoded    // router output port
);
    function integer log2;
    input integer number; begin   
        log2=(number <=1) ? 1: 0;    
        while(2**log2<number) begin    
            log2=log2+1;    
        end        
    end   
    endfunction // log2 
    
    localparam
        Kw = log2(K),
        LKw= L*Kw,
        Lw = log2(L),
        DSPw= log2(K+1);
    input  [LKw-1 : 0]    current_addr_encoded;
    input  [Lw-1 : 0]    current_level;    
    input  [LKw-1 : 0]    dest_addr_encoded;
    output [DSPw-1 : 0]    destport_encoded;
    
    tree_nca_routing #(
        .K(K),
        .L(L)
    ) nca_random_up (
        .current_addr_encoded(current_addr_encoded),
        .current_level(current_level),
        .dest_addr_encoded(dest_addr_encoded),
        .destport_encoded(destport_encoded)
    );
endmodule



/************************************************
*        deterministic_look_ahead_routing
**********************************************/

module  tree_deterministic_look_ahead_routing # (
    parameter P=4
) (
    destport_encoded,// current router destination port 
    dest_addr_encoded,
    neighbors_rx,
    neighbors_ry,
    lkdestport_encoded // look ahead destination port     
);
    import pronoc_pkg::*;
    
    localparam
        Pw=log2(P),
        PLw = P * Lw,
        PLKw = P * LKw,
        DSPw= log2(K+1);
        
    input  [DSPw-1 : 0]    destport_encoded;
    input  [LKw-1 : 0]    dest_addr_encoded;
    input  [PLKw-1 : 0]  neighbors_rx;
    input  [PLw-1 : 0]  neighbors_ry;
    output [DSPw-1: 0]    lkdestport_encoded;
    
    wire  [LKw-1 : 0]    next_addr_encoded;
    wire  [Lw-1 : 0]    next_level;  
    wire  [DSPw-1: 0] lkdestport_encoded;  
    
    next_router_addr_selector_bin #(
        .P(P),
        .RXw(LKw), 
        .RYw(Lw)
    ) addr_predictor (
        .destport_bin(destport_encoded[Pw-1 : 0]),
        .neighbors_rx(neighbors_rx),
        .neighbors_ry(neighbors_ry),
        .next_rx(next_addr_encoded),
        .next_ry(next_level)
    );
    
    tree_conventional_routing #(
        .ROUTE_NAME(ROUTE_NAME),
        .K(K),
        .L(L)
    ) conv_routing (
        .current_addr_encoded(next_addr_encoded),
        .current_level(next_level),
        .dest_addr_encoded(dest_addr_encoded),
        .destport_encoded(lkdestport_encoded)
    );
endmodule


/************************************
*     tree_look_ahead_routing
*************************************/
module tree_look_ahead_routing #(
    parameter P = 4 // port number
)(
    reset,
    clk,
    destport_encoded,// current router destination port 
    dest_addr_encoded,
    neighbors_rx,
    neighbors_ry,
    lkdestport_encoded // look ahead destination port
);
    import pronoc_pkg::*;
    
    localparam
        PLw = P * Lw,
        PLKw = P * LKw,
        DSPw= log2(K+1);
    
    input  [DSPw-1 : 0] destport_encoded;
    input  [LKw-1 : 0] dest_addr_encoded;
    input  [PLKw-1 : 0] neighbors_rx;
    input  [PLw-1 : 0] neighbors_ry;
    output [DSPw-1: 0] lkdestport_encoded;
    input reset,clk;
    
    wire [DSPw-1 : 0] destport_encoded_delayed;
    wire [LKw-1 : 0]  dest_addr_encoded_delayed;
    
    tree_deterministic_look_ahead_routing #(
        .P(P)
    ) look_ahead_routing (
        .destport_encoded(destport_encoded_delayed),
        .dest_addr_encoded(dest_addr_encoded_delayed),
        .neighbors_rx(neighbors_rx),
        .neighbors_ry(neighbors_ry),
        .lkdestport_encoded(lkdestport_encoded)
    );
    
    pronoc_register #(.W(DSPw)) reg1 (.D_in(destport_encoded  ), .Q_out(destport_encoded_delayed), .reset(reset), .clk(clk));
    pronoc_register #(.W(LKw )) reg2 (.D_in(dest_addr_encoded ), .Q_out(dest_addr_encoded_delayed),.reset(reset), .clk(clk));
endmodule




/*************
 * tree_destport_encoder
 * ***********/
module tree_destport_decoder #(
    parameter K=2 
)(
    destport_decoded_o,
    destport_encoded_i  
);
    function integer log2;
    input integer number; begin   
        log2=(number <=1) ? 1: 0;    
        while(2**log2<number) begin    
            log2=log2+1;    
        end        
    end   
    endfunction // log2 
    
    localparam
        MAX_P = K+1,
        DSPw= log2(MAX_P);     
    
    input  [DSPw-1 : 0] destport_encoded_i;
    output [MAX_P-1 : 0] destport_decoded_o; 
    
    bin_to_one_hot #(
        .BIN_WIDTH(DSPw),
        .ONE_HOT_WIDTH(MAX_P)
    ) cnvt  (
        .bin_code(destport_encoded_i),
        .one_hot_code(destport_decoded_o)
    );
endmodule



//decode and mask destport  
module  tree_destp_generator #(
    parameter K=2,
    parameter P=K+1,
    parameter SW_LOC=0,
    parameter DSTPw=4,
    parameter SELF_LOOP_EN = 0
)(
    dest_port_in_encoded,
    dest_port_out
);
    localparam
        MAX_P = K+1,
        P_1 = (SELF_LOOP_EN )? P : P-1;

    input  [DSTPw-1: 0] dest_port_in_encoded;
    output [P_1-1 : 0] dest_port_out;
    
    wire [MAX_P-1 : 0] destport_decoded;
    
    tree_destport_decoder #(
        .K(K)
    ) destport_decoder(
        .destport_encoded_i(dest_port_in_encoded),
        .destport_decoded_o(destport_decoded)
    );
    
    generate 
    if(SELF_LOOP_EN == 0) begin : nslp
        remove_sw_loc_one_hot #(
            .P(P),
            .SW_LOC(SW_LOC)
        ) conv (
            .destport_in(destport_decoded[P-1 : 0]),
            .destport_out(dest_port_out[P_1-1 : 0 ])
        );  
    end else begin : slp
        assign dest_port_out = destport_decoded;
    end
    endgenerate
endmodule