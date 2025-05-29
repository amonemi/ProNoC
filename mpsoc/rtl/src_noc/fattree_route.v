`include "pronoc_def.v"
/**************************************
*
*   fattree rout function
*
***************************************/

// ============================================================
//  FATTREE: Nearest Common Ancestor w/ Random  Routing Up
// ============================================================

module fattree_nca_random_up_routing  #(
   parameter K   = 2, // number of last level individual router`s endpoints.
   parameter L   = 2 // Fattree layer number (The height of FT)
)(
    reset,
    clk,
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
        Lw = log2(L);
    
    input reset,clk;
    input  [LKw-1 :0]    current_addr_encoded;
    input  [Lw-1  :0]    current_level;    
    input  [LKw-1 :0]    dest_addr_encoded;
    output [K :0]    destport_encoded;
    /******************
    *    destport_encoded format in fat tree. K+1 bit
    *    destport[K] 
    *        1'b0  : go down 
    *        1'b1  : go up
    *    destport[K-1: 0]: 
    *        onehot coded. asserted bit show the output port locatation     
    *******************/
    wire  [Kw-1 :0]  current_addr [L-1 : 0];
    wire  [Kw-1 :0]  parrent_dest_addr [L-1 : 0];
    wire  [Kw-1 :0]  dest_addr [L-1 : 0];
    wire  [Kw-1 :0]  current_node_dest_port;
    
    wire [L-1 : 0] parrents_node_missmatch; 
    wire [K-1 : 0] counter; // a one hot counter. The value of the counter is used as a random destination port number when going to the up ports
        
    pronoc_register #(
        .W(K),
        .RESET_TO(1)
    ) reg1 ( 
        .in({counter[0],counter[K-1:1]}),
        .reset(reset),    
        .clk(clk),      
        .out(counter)
    );
    
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
    endgenerate
    assign current_node_dest_port = dest_addr[current_level];
    wire [K-1:0] current_node_dest_port_one_hot;
    
    bin_to_one_hot #(
        .BIN_WIDTH(Kw),
        .ONE_HOT_WIDTH(K)
    ) conv (
    .bin_code(current_node_dest_port),
    .one_hot_code(current_node_dest_port_one_hot)
    ); 
    
    assign destport_encoded = (parrents_node_missmatch != {L{1'b0}}) ? /*go up*/{1'b1,counter} :  /*go down*/{1'b0,current_node_dest_port_one_hot};
endmodule

// ============================================================
//  FATTREE: Nearest Common Ancestor w/ destination port Up. 
//  The up port is selected based on destination connected port num
// ============================================================

module fattree_nca_destp_up_routing  #(
   parameter K   = 2, // number of last level individual router`s endpoints.
   parameter L   = 2 // Fattree layer number (The height of FT)
)(
    reset,
    clk,
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
        Lw = log2(L);
    
    input reset,clk;
    input  [LKw-1 :0]    current_addr_encoded;
    input  [Lw-1  :0]    current_level;    
    input  [LKw-1 :0]    dest_addr_encoded;
    output [K :0]    destport_encoded;
    /******************
    *    destport_encoded format in fat tree. K+1 bit
    *    destport[K] 
    *        1'b0  : go down 
    *        1'b1  : go up
    *    destport[K-1: 0]: 
    *        onehot coded. asserted bit show the output port locatation     
    *******************/
    
    wire  [Kw-1 :0]  current_addr [L-1 : 0];
    wire  [Kw-1 :0]  parrent_dest_addr [L-1 : 0];
    wire  [Kw-1 :0]  dest_addr [L-1 : 0];
    wire  [Kw-1 :0]  current_node_dest_port;    
    wire [L-1 : 0] parrents_node_missmatch; 
    wire [K-1 : 0] counter; // a one hot counter. The value of the counter is used as a random destination port number when going to the up ports
    
    pronoc_register #(
        .W(K),
        .RESET_TO(1)
    ) reg1 ( 
        .in({counter[0],counter[K-1:1]}),
        .reset(reset),    
        .clk(clk),      
        .out(counter)
    );
    
    assign current_addr [0]={Kw{1'b0}}; 
    assign parrent_dest_addr [0]={Kw{1'b0}}; 
    
    genvar i;
    generate 
    for(i=1; i<L; i=i+1) begin : caddr
        assign current_addr [i] = (current_level <i)? current_addr_encoded[i*Kw-1 : (i-1)*Kw] : {Kw{1'b0}};
        assign parrent_dest_addr [i] = (current_level<i)? dest_addr_encoded[(i+1)*Kw-1 : i*Kw] : {Kw{1'b0}};
    end
    for(i=0; i<L; i=i+1) begin : daddr
       // assign current_addr [i] = (current_level >=i)? current_addr_encoded[(i+1)*Kw-1 : i*Kw] : {Kw{1'b0}};
        assign dest_addr [i] =  dest_addr_encoded[(i+1)*Kw-1 : i*Kw];
        assign parrents_node_missmatch[i]=  current_addr [i] !=  parrent_dest_addr [i]; 
    end//for
    endgenerate
    assign current_node_dest_port = dest_addr[current_level];
    wire [K-1:0] current_node_dest_port_one_hot;
    bin_to_one_hot #(
        .BIN_WIDTH(Kw),
        .ONE_HOT_WIDTH(K)
    ) conv (
        .bin_code(current_node_dest_port),
        .one_hot_code(current_node_dest_port_one_hot)
    ); 
    
    assign destport_encoded = (parrents_node_missmatch != {L{1'b0}}) ? /*go up*/{1'b1,current_node_dest_port_one_hot} :  /*go down*/{1'b0,current_node_dest_port_one_hot};
endmodule


// ============================================================
//  FATTREE: Nearest Common Ancestor w/ straight port Up. 
//  The up port is in the same column as reciver port
// ============================================================

module fattree_nca_straight_up_routing  #(
   parameter K   = 2, // number of last level individual router`s endpoints.
   parameter L   = 2 // Fattree layer number (The height of FT)
) (
    reset,
    clk,
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
        Lw = log2(L);
    
    input reset,clk;
    input  [LKw-1 :0]    current_addr_encoded;
    input  [Lw-1  :0]    current_level;    
    input  [LKw-1 :0]    dest_addr_encoded;
    output [K :0]    destport_encoded;
    /******************
    *    destport_encoded format in fat tree. K+1 bit
    *    destport[K] 
    *        1'b0  : go down 
    *        1'b1  : go up
    *    destport[K-1: 0]: 
    *        onehot coded. asserted bit show the output port locatation     
    ********************/
    
    wire  [Kw-1 :0]  current_addr [L-1 : 0];
    wire  [Kw-1 :0]  parrent_dest_addr [L-1 : 0];
    wire  [Kw-1 :0]  dest_addr [L-1 : 0];
    wire  [Kw-1 :0]  current_node_dest_port;
    wire [L-1 : 0] parrents_node_missmatch; 
    wire  [K-1 : 0] counter; // a one hot counter. The value of the counter is used as a random destination port number when going to the up ports
    pronoc_register #(
        .W(K),
        .RESET_TO(1)
    ) reg1 ( 
        .in({counter[0],counter[K-1:1]}),
        .reset(reset),    
        .clk(clk),      
        .out(counter)
    );
    
    assign current_addr [0]={Kw{1'b0}}; 
    assign parrent_dest_addr [0]={Kw{1'b0}}; 
    
    genvar i;
    generate 
    for(i=1; i<L; i=i+1)begin : caddr
        assign current_addr [i] = (current_level <i)? current_addr_encoded[i*Kw-1 : (i-1)*Kw] : {Kw{1'b0}};
        assign parrent_dest_addr [i] = (current_level<i)? dest_addr_encoded[(i+1)*Kw-1 : i*Kw] : {Kw{1'b0}};
    end
    for(i=0; i<L; i=i+1)begin : daddr
        // assign current_addr [i] = (current_level >=i)? current_addr_encoded[(i+1)*Kw-1 : i*Kw] : {Kw{1'b0}};
        assign dest_addr [i] =  dest_addr_encoded[(i+1)*Kw-1 : i*Kw];
        assign parrents_node_missmatch[i]=  current_addr [i] !=  parrent_dest_addr [i]; 
    end//for
    endgenerate
    assign current_node_dest_port = dest_addr[current_level];
    wire [K-1:0] current_node_dest_port_one_hot;
    
    bin_to_one_hot #(
        .BIN_WIDTH(Kw),
        .ONE_HOT_WIDTH(K)
    ) conv (
        .bin_code(current_node_dest_port),
        .one_hot_code(current_node_dest_port_one_hot)
    ); 
    
    // if going up the destination port num is statis straigh. It will be filled at reciver port of the next router so leave it empty
    assign destport_encoded = (parrents_node_missmatch != {L{1'b0}}) ? /*go up*/{1'b1,{K{1'b0}}} :  /*go down*/{1'b0,current_node_dest_port_one_hot};
endmodule


module    fattree_destport_up_select #(
    parameter   K=3,
    parameter   SW_LOC=0
)(
    destport_in,
    destport_o
);
    
    input  [K :0]    destport_in;
    output [K :0]    destport_o;
    
    localparam [K-1 : 0] SW_LOC_ONHOT = 1<< SW_LOC; 
    
    wire going_up = destport_in[K];
    assign destport_o = (going_up)?  {1'b1,SW_LOC_ONHOT[K-1 : 0]} : destport_in;
endmodule

/*************************
 *  fattree_conventional_routing 
 * **********************/
module fattree_conventional_routing #(
    parameter ROUTE_NAME = "NCA_RND_UP",
    parameter K   = 2, // number of last level individual router`s endpoints.
    parameter L   = 2 // Fattree layer number (The height of FT)
)(
    reset,
    clk,
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
        Lw = log2(L);
    input reset,clk;
    input  [LKw-1 :0]    current_addr_encoded;
    input  [Lw-1  :0]    current_level;    
    input  [LKw-1 :0]    dest_addr_encoded;
    output [K :0]    destport_encoded;
    generate 
    /* verilator lint_off WIDTH */ 
    if( ROUTE_NAME == "NCA_RND_UP")begin :nca_rnd
    /* verilator lint_on WIDTH */ 
        fattree_nca_random_up_routing #(
            .K(K),
            .L(L)
        ) nca_random_up (
            .reset(reset),
            .clk(clk),
            .current_addr_encoded(current_addr_encoded),
            .current_level(current_level),
            .dest_addr_encoded(dest_addr_encoded),
            .destport_encoded(destport_encoded)
        );
     /* verilator lint_off WIDTH */ 
    end else if ( ROUTE_NAME == "NCA_DST_UP")begin :nca_dst
    /* verilator lint_on WIDTH */ 
        fattree_nca_destp_up_routing #(
            .K(K),
            .L(L)
        )nca_random_up (
            .reset(reset),
            .clk(clk),
            .current_addr_encoded(current_addr_encoded),
            .current_level(current_level),
            .dest_addr_encoded(dest_addr_encoded),
            .destport_encoded(destport_encoded)
        );
    /* verilator lint_off WIDTH */ 
    end else if ( ROUTE_NAME == "NCA_STRAIGHT_UP")begin :nca_straight
    /* verilator lint_on WIDTH */ 
        fattree_nca_straight_up_routing #(
            .K(K),
            .L(L)
        )  nca_straight_up (
            .reset(reset),
            .clk(clk),
            .current_addr_encoded(current_addr_encoded),
            .current_level(current_level),
            .dest_addr_encoded(dest_addr_encoded),
            .destport_encoded(destport_encoded)
        );
    end else begin 
        `ifdef SIMULATION
        initial begin 
            $display( "\t ERROR: %s is an undefined routing algorithm for FATTREE topology",ROUTE_NAME);
            $finish;
        end
        `endif
    end
    endgenerate
endmodule

/************************************
*    fattree_look_ahead_routing
**************************************/
module fattree_look_ahead_routing #(
    parameter ROUTE_NAME = "NCA_RND_UP",
    parameter P = 4,
    parameter L = 2,
    parameter K = 2
)(
    reset,
    clk,
    destport_encoded,// current router destination port 
    dest_addr_encoded,
    neighbors_rx,
    neighbors_ry,
    lkdestport_encoded // look ahead destination port     
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
        PLw = P * Lw,
        PLKw = P * LKw;
    
    input  [K :0]    destport_encoded;
    input  [LKw-1 :0]    dest_addr_encoded;
    input  [PLKw-1 : 0]  neighbors_rx;
    input  [PLw-1 : 0]  neighbors_ry;
    output [K: 0]    lkdestport_encoded;
    input                   reset,clk;
    
    wire  [K :0]    destport_encoded_delayed;
    wire  [LKw-1 :0]    dest_addr_encoded_delayed;
    
    fattree_deterministic_look_ahead_routing #(
        .P(P),
        .ROUTE_NAME(ROUTE_NAME),
        .K(K),
        .L(L)
    ) look_ahead_routing (
        .reset(reset),
        .clk(clk),
        .destport_encoded(destport_encoded_delayed),
        .dest_addr_encoded(dest_addr_encoded_delayed),
        .neighbors_rx(neighbors_rx),
        .neighbors_ry(neighbors_ry),
        .lkdestport_encoded(lkdestport_encoded)
    );
    
    pronoc_register #(
        .W(K+1)
    ) reg1 ( 
        .in(destport_encoded),
        .reset(reset),    
        .clk(clk),      
        .out(destport_encoded_delayed)
    );
    
    pronoc_register #(
        .W(LKw)
    ) reg2 ( 
        .in(dest_addr_encoded),
        .reset(reset),    
        .clk(clk),      
        .out(dest_addr_encoded_delayed)
    );
endmodule


/************************************************
*        deterministic_look_ahead_routing
**********************************************/
module  fattree_deterministic_look_ahead_routing #(
    parameter P=4,
    parameter ROUTE_NAME = "NCA_RND_UP",
    parameter K   = 2, // number of last level individual router`s endpoints.
    parameter L   = 2 // Fattree layer number (The height of FT)
)(
    reset,
    clk,
    destport_encoded,// current router destination port 
    dest_addr_encoded,
    neighbors_rx,
    neighbors_ry,
    lkdestport_encoded // look ahead destination port     
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
        PLw = P * Lw,
        PLKw = P * LKw;
        
    input reset,clk;
    input  [K :0]    destport_encoded;
    input  [LKw-1 :0]    dest_addr_encoded;
    input  [PLKw-1 : 0]  neighbors_rx;
    input  [PLw-1 : 0]  neighbors_ry;
    output [K: 0]    lkdestport_encoded;
    
    wire  [LKw-1 :0]    next_addr_encoded;
    wire  [Lw-1  :0]    next_level;  
    wire  [K : 0] lkdestport_encoded;  
    wire  [2*K-1 : 0] destport_decoded;
    
    fattree_destport_decoder #(
        .K(K)
    ) fattree_destport_decoder(
        .destport_encoded_i(destport_encoded),
        .destport_decoded_o(destport_decoded)
    ); 
    
    next_router_addr_selector_onehot #(
        .P(P),
        .RXw(LKw), 
        .RYw(Lw)
    ) addr_predictor (
        .destport_onehot(destport_decoded[P-1 : 0]),
        .neighbors_rx(neighbors_rx),
        .neighbors_ry(neighbors_ry),
        .next_rx(next_addr_encoded),
        .next_ry(next_level)
    );
    
    fattree_conventional_routing #(        
        .ROUTE_NAME(ROUTE_NAME),
        .K(K),
        .L(L)        
    ) conv_routing (
        .reset(reset),
        .clk(clk),
        .current_addr_encoded(next_addr_encoded),
        .current_level(next_level),
        .dest_addr_encoded(dest_addr_encoded),
        .destport_encoded(lkdestport_encoded)
    );
    
endmodule


module fattree_destport_decoder #(
    parameter K=2
)(
    destport_decoded_o,
    destport_encoded_i  
);
    input [K:0] destport_encoded_i;
    output [2*K-1 : 0] destport_decoded_o;     
    assign destport_decoded_o =   
        (destport_encoded_i[K])? /*go up*/    {destport_encoded_i[K-1:0],{K{1'b0}}}:
                                /*go down*/   {{K{1'b0}},destport_encoded_i[K-1:0]};    
endmodule

/**********
 *  fattree_mask_non_assignable_destport
 * ********/

module fattree_mask_non_assignable_destport #(
    parameter K=4,
    parameter P=2*K,
    parameter SW_LOC = 0        
)(
    destport_in,
    destport_out        
);
    input [2*K-1 : 0] destport_in;
    output [2*K-1 : 0] destport_out;
    generate 
    if(P<=K)begin :root //This is a root node there is conectivety between all ports
        assign destport_out = destport_in;    
    end else begin: leaf
        if(SW_LOC < K) begin: down // This port located in lower side of the router. It can send packet to any destport 
            assign destport_out = destport_in;   
        end else begin : up // // This port located in upper side of the router. It cannot send packet to upper port anymore
            assign destport_out[2*K-1 : K] = {K{1'b0}};   
            assign destport_out[K-1 : 0] = destport_in [K-1 : 0];           
        end
    end
    endgenerate
endmodule

/********************
*    distance_gen 
********************/
module fattree_distance_gen #(
    parameter K= 4,    
    parameter L= 4
)(
    src_addr_encoded,    
    dest_addr_encoded,       
    distance
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
        DISTw= log2(2*L+1);
    input  [LKw-1 :0]    src_addr_encoded;
    input  [LKw-1 :0]    dest_addr_encoded;
    output reg [DISTw-1 : 0] distance;
    wire  [Kw-1 :0]  dest_addr [L-1 : 0];
    wire  [Kw-1 :0]  src_addr [L-1 : 0];
    wire  [L-1 : 0] diffrent;
    genvar i;
    generate 
    for(i=0; i<L; i=i+1)begin : daddr      
        assign dest_addr [i] =  dest_addr_encoded[(i+1)*Kw-1 : i*Kw];
        assign src_addr [i] =  src_addr_encoded[(i+1)*Kw-1 : i*Kw];
        assign diffrent[i] = dest_addr [i] != src_addr [i];
    end//for
    endgenerate
    
    wire [11:0] tmp;
    assign tmp= {{(12-L){1'b0}},diffrent};
    /* verilator lint_off WIDTH */
    always @(*)begin
        if (tmp[10]) distance =21;
        else if (tmp[9]) distance =19;
        else if (tmp[8]) distance =17;
        else if (tmp[7]) distance =15;
        else if (tmp[6]) distance =13;
        else if (tmp[5]) distance =11;
        else if (tmp[4]) distance =9;
        else if (tmp[3]) distance =7;
        else if (tmp[2]) distance =5;
        else if (tmp[1]) distance =3;
        else distance =1;    
    end
    /* verilator lint_on WIDTH */
endmodule

/**************
    fattree_addr_encoder
    most probably it is only needed for simulation purposes
***************/  

module  fattree_addr_encoder #(
    parameter   K=2,
    parameter   L=2
)(
    id,
    code
);
    
    function integer log2;
    input integer number; begin   
        log2=(number <=1) ? 1: 0;    
        while(2**log2<number) begin    
            log2=log2+1;    
        end        
    end   
    endfunction // log2 
    
    function integer powi;
        input integer x,y;
        integer i;begin //compute x to the y
        powi=1;
        for (i = 0; i <y; i=i+1 ) begin 
            powi=powi * x;
        end
        end   
    endfunction // log2 
    
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
        NE = powi( K,L ),  //total number of endpoints
        NEw = log2(NE),
        Kw=log2(K),
        LKw=L*Kw;
    input [NEw-1 :0] id;
    output [LKw-1 : 0] code;
    
    wire [LKw-1 : 0 ] codes [NE-1 : 0];
    genvar i;
    generate 
    for(i=0; i< NE; i=i+1) begin : endpoints
        //Endpoint decoded address
        localparam [LKw-1 : 0] ENDPX= addrencode(i,K,L,Kw);
        assign codes[i] = ENDPX;            
    end
    endgenerate
    
    assign code = codes[id];
endmodule


/**************
*    fattree_addr_decoder
*    most probably it is only needed for simulation 
***************/  
module  fattree_addr_decoder #(
    parameter   K=2,
    parameter   L=2
)(
    id,
    code
);
    
    function integer log2;
    input integer number; begin   
        log2=(number <=1) ? 1: 0;    
        while(2**log2<number) begin    
            log2=log2+1;    
        end        
    end   
    endfunction // log2 
    
    function integer powi;
        input integer x,y;
        integer i;begin //compute x to the y
        powi=1;
        for (i = 0; i <y; i=i+1 ) begin 
            powi=powi * x;
        end
        end   
    endfunction // log2 
    
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
        NE = powi( K,L ),  //total number of endpoints
        NEw = log2(NE),
        Kw=log2(K),
        LKw=L*Kw;
    output [NEw-1 :0] id;
    input  [LKw-1 : 0] code;
    
    wire  [NEw-1 : 0] codes  [2**LKw-1 : 0 ];
    genvar i;
    generate 
    for(i=0; i< NE; i=i+1) begin : endpoints
        //Endpoint decoded address
        /* verilator lint_off WIDTH */
        localparam [LKw-1 : 0] ENDPX= addrencode(i,K,L,Kw);
        /* verilator lint_on WIDTH */
        assign codes[ENDPX] = i;            
    end
    endgenerate
    
    assign id = codes[code];
endmodule

/**************
 * mesh_torus_ssa_check_destport_conflict
 * check if the incomming flit goes to SS port
 * ************/
module fattree_ssa_check_destport #(
    parameter DSTPw = 5,
    parameter SS_PORT=0
)(
    destport_encoded, //exsited packet dest port
    destport_in_encoded, // incomming packet dest port
    ss_port_hdr_flit, // asserted if the header incomming flit goes to ss port
    ss_port_nonhdr_flit // asserted if the body or tail incomming flit goes to ss port
);
    localparam K= DSTPw-1;
    localparam SS_LOC = (SS_PORT < K)? SS_PORT : SS_PORT-K;
    
    input [DSTPw-1 : 0] destport_encoded, destport_in_encoded; 
    output ss_port_hdr_flit, ss_port_nonhdr_flit;
    /******************
    *        destport_encoded format in fat tree. K+1 bit
    *        destport[K] 
    *            1'b0  : go down 
    *            1'b1  : go up
    *        destport[K-1: 0]: 
    *            onehot coded. asserted bit show the output port locatation     
    *******************/
    wire up_flg = destport_encoded[DSTPw-1];
    wire up_flg_in = destport_in_encoded[DSTPw-1];
    wire down_flg = ~destport_encoded[DSTPw-1];
    wire down_flg_in = ~destport_in_encoded[DSTPw-1];   
    generate 
    if(SS_PORT < K) begin :SS_DOWN // the ssa port is located in down router side
        assign ss_port_hdr_flit = destport_in_encoded [SS_LOC] & down_flg_in;   
        assign ss_port_nonhdr_flit =  destport_encoded[SS_LOC] & down_flg;   
    end else begin : SS_UP
        assign ss_port_hdr_flit = destport_in_encoded [SS_LOC] & up_flg_in;   
        assign ss_port_nonhdr_flit =  destport_encoded[SS_LOC] & up_flg;       
    end
    endgenerate    
endmodule

/*
module fattree_add_ss_port #(   
    parameter SW_LOC=1,
    parameter P=5
)(
    destport_in,
    destport_out 
);
    localparam
        P_1     =   P-1,
        DISABLED   =    P;
    
    localparam  SS_PORT_FATTREE_EVEN =  (SW_LOC < (P/2) )? (P/2)+ SW_LOC-1 : SW_LOC - (P/2);
    localparam  SS_PORT_FATTREE_ODD  =  (SW_LOC == (P-1)/2)?   DISABLED:
                                        (SW_LOC < ((P+1)/2) )? ((P+1)/2)+ SW_LOC-1 : SW_LOC - ((P+1)/2);
        
    localparam  SS_PORT_FATTREE = (P[0]==1'b0) ? SS_PORT_FATTREE_EVEN : SS_PORT_FATTREE_ODD;
    localparam  SS_PORT      =   SS_PORT_FATTREE;
    input       [P_1-1  :   0] destport_in;
    output reg  [P_1-1  :   0] destport_out; 
    always @(*)begin 
        destport_out=destport_in;
        if( SS_PORT != DISABLED ) begin 
            if(destport_in=={P_1{1'b0}}) destport_out[SS_PORT]= 1'b1;
        end    
    end 
endmodule
 */


module fattree_router_addr_decode #(
    parameter K=4,
    parameter L=4
)(
    r_addr,
    rx,
    rl
    //valid
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
        RAw= LKw + Lw;
    
    input   [RAw-1 : 0]   r_addr;
    output  [LKw-1 :0]    rx;
    output  [Lw-1  :0]    rl;
    assign {rl,rx} = r_addr;
endmodule


//decode and mask destport  
module  fattree_destp_generator #(
    parameter K=2,
    parameter P=2*K,
    parameter SW_LOC=0,
    parameter DSTPw=4,
    parameter SELF_LOOP_EN = 0
)(
    dest_port_in_encoded,
    dest_port_out
);

    localparam P_1 = (SELF_LOOP_EN )?  P : P-1;
    input  [DSTPw-1:0] dest_port_in_encoded;
    output [P_1-1 : 0] dest_port_out;
    
    wire [2*K-1 : 0] destport_decoded;
    wire [2*K-1 : 0] destport_masked;

    fattree_destport_decoder #(
        .K(K)
    )destport_decoder (
        .destport_encoded_i(dest_port_in_encoded),
        .destport_decoded_o(destport_decoded)
    );
    
    fattree_mask_non_assignable_destport #(
        .K(K),
        .P(P),
        .SW_LOC(SW_LOC)
    ) mask  (
        .destport_in(destport_decoded),
        .destport_out(destport_masked)
    );
    
    generate 
    if(SELF_LOOP_EN == 0) begin : nslp
        remove_sw_loc_one_hot #(
            .P(P),
            .SW_LOC(SW_LOC)
        ) conv (
            .destport_in(destport_masked[P-1 : 0]),
            .destport_out(dest_port_out[P_1-1  :   0 ])
        );  
    end else begin : slp 
        assign dest_port_out= destport_masked [P_1-1  :   0 ];
    end
    endgenerate
endmodule