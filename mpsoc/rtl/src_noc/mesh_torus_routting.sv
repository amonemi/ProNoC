`include "pronoc_def.v"
/************************************
*
*    regular_topo_look_ahead_routing
*
*************************************/

module regular_topo_look_ahead_routing (
    dest_router_addr_i,
    destport_encoded,   // current router destination port number
    lkdestport_encoded, // look ahead destination port number
    neighbors_r_addr,
    reset,
    clk
);
    import pronoc_pkg::*;
    localparam  P = (IS_MESH_3D)? 7 : ( IS_MESH || IS_FMESH || IS_TORUS ) ? 5 : 3;
    
    localparam  P_1 = P-1;
    input regular_topo_router_addr_t dest_router_addr_i;
    input  [DSTPw-1  :   0] destport_encoded;
    output [DSTPw-1  :   0] lkdestport_encoded;
    input  [RAw-1:  0]  neighbors_r_addr [P-1 : 0];
    input  reset,clk;
    
    regular_topo_router_addr_t dest_router_addr_f;
    logic [DSTPw-1  :   0]  destport_delayed;
    // routing algorithm
    generate 
    if( IS_DETERMINISTIC ) begin :dtrmst
        regular_topo_deterministic_look_ahead_routing #(
            .P(P)
        ) deterministic_look_ahead(
            .dest_router_addr_i(dest_router_addr_f),
            .destport(destport_delayed),
            .lkdestport(lkdestport_encoded),
            .neighbors_r_addr(neighbors_r_addr)
        );
    end else begin :adapt
        if(IS_3D_TOPO) begin 
            regular_topo_adaptive_look_ahead_routing_3D #(
                .P(P)
            ) adaptive_look_ahead (
                .dest_router_addr_i(dest_router_addr_f),
                .destport_encoded(destport_delayed),
                .lkdestport_encoded(lkdestport_encoded),
                .neighbors_r_addr(neighbors_r_addr)
            );
        end else begin 
            regular_topo_adaptive_look_ahead_routing #(
                .P(P)
            ) adaptive_look_ahead (
                .dest_router_addr_i(dest_router_addr_f),
                .destport_encoded(destport_delayed),
                .lkdestport_encoded(lkdestport_encoded),
                .neighbors_r_addr(neighbors_r_addr)
            );
        end
    end
    endgenerate
    always_ff @ (`pronoc_clk_reset_edge) begin
        if (`pronoc_reset) begin
            dest_router_addr_f <= '0;
            destport_delayed <= '0;
        end else begin
            dest_router_addr_f <= dest_router_addr_i;
            destport_delayed <= destport_encoded;
        end
    end
endmodule


/************************************************
*    deterministic_look_ahead_routing
**********************************************/
module  regular_topo_deterministic_look_ahead_routing #(
    parameter P =5
) (
    dest_router_addr_i,
    destport,   // current router destination port number
    neighbors_r_addr,
    lkdestport // look ahead destination port number
);
    import pronoc_pkg::*;
    localparam  
        P_1 = P-1,
        Pw= log2(P);
    
    input regular_topo_router_addr_t dest_router_addr_i;
    input [DSTPw-1  :   0]  destport;
    input [RAw-1 : 0]  neighbors_r_addr [P-1 : 0];
    output [DSTPw-1  :   0] lkdestport;
    wire [Pw-1 : 0]  dstport_decimal;
    genvar i;
    generate 
    if(IS_MESH_3D) begin: threeD
        assign dstport_decimal = destport;
    end else if (IS_MESH || IS_TORUS || IS_FMESH ) begin: twoD
        regular_topo_destport_decode_decimal decoder(
            .destport_encoded(destport),
            .destport_decimal(dstport_decimal)
        );
    end else begin :oneD
        line_ring_destport_decode_decimal  decoder(
            .destport_encoded(destport),
            .destport_decimal(dstport_decimal)
        );
    end
    endgenerate 
    wire [RAw-1 : 0] next_router_addr = neighbors_r_addr[dstport_decimal];
    
    wire [DSTPw-1  :   0] lkdestport_encoded;
    regular_topo_router_addr_t next_router_addr_struct;
    assign next_router_addr_struct = regular_topo_router_addr_t'(next_router_addr);
    regular_topo_conventional_routing #(
        .LOCATED_IN_NI(0)
    ) conv_routing (
        .current_router_addr_i(next_router_addr_struct),
        .dest_router_addr_i(dest_router_addr_i),
        .destport(lkdestport_encoded)
    );
    
    //take the value of a&b only.  x&y can be obtained from destport in the router
    assign lkdestport = lkdestport_encoded;//[1: 0];
endmodule




/************************************************
*        adaptive_look_ahead_routing
**********************************************/
module  regular_topo_adaptive_look_ahead_routing_3D #(
    parameter P =5
)(
    dest_router_addr_i, 
    neighbors_r_addr,
    destport_encoded,   // current router destination port
    lkdestport_encoded // look ahead destination port 
);
    import pronoc_pkg::*;
    localparam 
        DIM = (IS_1D_TOPO)? 1 : (IS_2D_TOPO)? 2 : 3,
        P_1 = P-1,
        Pw = log2(P);
    input regular_topo_router_addr_t   dest_router_addr_i;
    input [RAw-1 : 0]  neighbors_r_addr [P-1 : 0];
    input [DSTPw-1  :   0]  destport_encoded;
    output logic [DSTPw-1  :   0]  lkdestport_encoded;
    regular_topo_router_addr_t next_router_addr [DIM-1 : 0];
    reg [Pw-1 : 0]  destport [DIM-1 : 0];
    logic [6 : 0] destport_onehot;
    //destport_encoded: width is equal to the number of router_to_router port. each asserted bit shows possible route path to that direction. if all bit are zro its destinated to local
    //lkdestport_encoded:  the first DIM-bits  are valid. each bit shows if nex router in its corespondin dimention is in the same dimention with destination router
    always_comb begin 
        destport_onehot='0;
        destport_onehot [DSTPw:1] = destport_encoded;
        destport[0] =  destport_onehot[EAST]  ? EAST  : destport_onehot[WEST]  ? WEST  : LOCAL;
        destport[1] =  destport_onehot[NORTH] ? NORTH : destport_onehot[SOUTH] ? SOUTH : LOCAL;
        destport[2] =  destport_onehot[UP]    ? UP    : destport_onehot[DOWN]  ? DOWN  : LOCAL;
        lkdestport_encoded ='0;
        for (int d=0;d<DIM;d++) begin 
            next_router_addr[d] = regular_topo_router_addr_t'(neighbors_r_addr[destport[d]]);
        end
        lkdestport_encoded[0] = 
                (destport[0] == LOCAL ) ? 1'b0: 
                (next_router_addr[0].x !=dest_router_addr_i.x);
        lkdestport_encoded[1] = 
                (destport[1] == LOCAL || DIM < 2) ? 1'b0: 
                next_router_addr[1].y !=dest_router_addr_i.y;
        lkdestport_encoded[2] = 
                (destport[2] == LOCAL || DIM < 3 ) ? 1'b0: 
                next_router_addr[2].z !=dest_router_addr_i.z;
    end
endmodule

/************************************************
*        adaptive_look_ahead_routing
**********************************************/
module  regular_topo_adaptive_look_ahead_routing #(
    parameter P =5
)(
    dest_router_addr_i, 
    neighbors_r_addr,
    destport_encoded,   // current router destination port
    lkdestport_encoded // look ahead destination port 
);
    import pronoc_pkg::*;
    localparam 
        P_1 = P-1,
        Pw = log2(P);
    input regular_topo_router_addr_t   dest_router_addr_i;
    input [RAw-1 : 0]  neighbors_r_addr [P-1 : 0];
    input [P_1-1 : 0]  destport_encoded;
    output  [P_1-1 : 0]  lkdestport_encoded;
    /**************************
    *    destination-port coded
    *            x: 1 EAST, 0 WEST  
    *            y: 1 NORTH, 0 SOUTH
    *            ab: 00 : LOCAL, 10: xdir, 01: ydir, 11 x&y dir 
    **************************/       
    wire x,y,a,b;
    wire [P_1-1 : 0]  lkdestport_x,lkdestport_y;
    reg [Pw-1 : 0]  destport_x, destport_y;
    
    assign {x,y,a,b} = destport_encoded;
    
    always_comb begin
    destport_x = 0;
    destport_y = 0;
    case ({a, b})   
        2'b10: destport_x = (x) ? Pw'(EAST) : Pw'(WEST);// 1=East, 2=West
        2'b01: destport_y = (y) ? Pw'(NORTH) : Pw'(SOUTH);// 3=North, 4=South
        2'b11: begin
            // Both directions
            destport_x = (x) ? Pw'(EAST) : Pw'(WEST);
            destport_y = (y) ? Pw'(NORTH) : Pw'(SOUTH);
        end
        2'b00: begin
            // Local node
            destport_x = Pw'(LOCAL);
            destport_y = Pw'(LOCAL);
        end
    endcase
    end
    
    regular_topo_router_addr_t next_router_addr_x, next_router_addr_y;
    assign next_router_addr_x = regular_topo_router_addr_t'(neighbors_r_addr[destport_x]);
    assign next_router_addr_y = regular_topo_router_addr_t'(neighbors_r_addr[destport_y]);
    
    regular_topo_conventional_routing #(
        .LOCATED_IN_NI(0)
    ) conv_route_x (
        .current_router_addr_i(next_router_addr_x),
        .dest_router_addr_i(dest_router_addr_i),
        .destport(lkdestport_x)
    );
    
    regular_topo_conventional_routing #(
        .LOCATED_IN_NI(0)
    ) conv_route_y (
        .current_router_addr_i(next_router_addr_y),
        .dest_router_addr_i(dest_router_addr_i),
        .destport(lkdestport_y)
    );
    //take the value of a&b only.  x&y can be obtained from destport in the router
    assign lkdestport_encoded = {lkdestport_x[1: 0],lkdestport_y[1: 0]};
endmodule

/***********************************
*            remove_sw_loc_one_hot
*remove port number that is holding the packet
************************************/
module remove_sw_loc_one_hot #(
    parameter P = 5,
    parameter SW_LOC = 0
)(
    destport_in,
    destport_out
);
    localparam P_1 = P-1;
    
    input [P-1 : 0] destport_in;
    output  [P_1-1 : 0] destport_out;
    
    generate 
    if(SW_LOC==0)begin :local_p
        assign destport_out= destport_in[P-1 : 1];
    end else if (SW_LOC==P_1)begin :last_p
        assign destport_out= destport_in[P_1-1 : 0];
    end else begin :midle_p
        assign destport_out= {destport_in[P-1 : SW_LOC+1],destport_in[SW_LOC-1 :  0]};
    end
    endgenerate
endmodule

module destport_non_selfloop_fix #(
    parameter SELF_LOOP_EN = 0,
    parameter P = 5,
    parameter SW_LOC = 0
)(
    destport_in,
    destport_out
);
    localparam P_1 = (SELF_LOOP_EN)?  P : P-1;
    
    input [P-1 : 0] destport_in;
    output [P_1-1 : 0] destport_out;
    
    generate 
    if (SELF_LOOP_EN) begin
        assign destport_out = destport_in;
    end else begin
        if(SW_LOC==0)begin :local_p
            assign destport_out= destport_in[P-1 : 1];
        end else if (SW_LOC==P_1)begin :last_p
            assign destport_out= destport_in[P_1-1 : 0];
        end else begin :midle_p
            assign destport_out= {destport_in[P-1 : SW_LOC+1],destport_in[SW_LOC-1 :  0]};
        end
    end 
    endgenerate
endmodule



/***********************************
*     remove_receive_port_one_hot
*                
************************************/
module remove_receive_port_one_hot #(
    parameter P = 5    
)(
    receiver_port,
    destport_in,
    destport_out
);
    import pronoc_pkg::*;
    
    localparam 
        P_1 = P-1,
        Pw = log2(P),
        P_1w = log2(P_1);
    input [P-1 : 0] destport_in;
    input [P-1 : 0] receiver_port;
    output logic [P_1-1 : 0] destport_out;
    logic [Pw-1 : 0] receiver_port_bin,destport_in_bin;
    wire [P_1w-1 : 0]  destport_out_bin;
    
    always_comb begin
        receiver_port_bin = '0;
        destport_in_bin = '0;
        destport_out ='0;
        //bin to one_hot
        destport_out[destport_out_bin] = 1'b1;
        //one_hot_to_bin
        for (int k = 0;k < P;k++) begin
            if (receiver_port[k]) receiver_port_bin = Pw'(k);
            if (destport_in[k]) destport_in_bin = Pw'(k);
        end
    end
    
    wire [Pw-1 : 0] temp;
    assign temp = (receiver_port_bin > destport_in_bin ) ? destport_in_bin : destport_in_bin  -1'b1;
    assign destport_out_bin=temp[P_1w-1 : 0];
endmodule

/**************************************
*        add_sw_loc_one_hot
****************************************/
module add_sw_loc_one_hot #(
    parameter P = 5,
    parameter SW_LOC = 1
)(
    destport_in,
    destport_out
);
    localparam P_1 = P-1;
    input [P_1-1 : 0] destport_in;
    output reg [P-1 : 0] destport_out;
    
    always_comb begin 
        for(int i=0;i<P;i++)begin 
            if (i>SW_LOC) destport_out[i] = destport_in[i-1];
            else if (i==SW_LOC) destport_out[i] = 1'b0;
            else destport_out[i] = destport_in[i];
        end//for 
    end
endmodule  


module add_sw_loc_one_hot_val #(
    parameter P = 5,
    parameter SW_LOC = 1
    
)(
    sw_loc_val,
    destport_in,
    destport_out
);
    localparam P_1 = P-1;
    input sw_loc_val;
    input [P_1-1 : 0] destport_in;
    output reg [P-1 : 0] destport_out;
    
    integer i;
    always @(*)begin 
        for(i=0;i<P;i=i+1)begin :port_loop
            if (i>SW_LOC)      destport_out[i] = destport_in[i-1];
            else if (i==SW_LOC)     destport_out[i] = sw_loc_val;
            else                    destport_out[i] = destport_in[i];
        end//for 
    end
endmodule  


/***************************************************
*            conventional routing 
***************************************************/
module regular_topo_conventional_routing #(
    parameter LOCATED_IN_NI = 0 //used only for odd-even routing
    ) (   
    current_router_addr_i,
    dest_router_addr_i,
    destport
    );
    
    import pronoc_pkg::*;
    input regular_topo_router_addr_t current_router_addr_i;
    input regular_topo_router_addr_t dest_router_addr_i;
    output logic [DSTPw-1 : 0] destport;
    
    generate 
    if (IS_MESH_3D) begin 
        mesh_3d_route_xyz the_conventional_routing(
            .current_router_addr_i(current_router_addr_i),
            .dest_router_addr_i(dest_router_addr_i),
            .destport(destport)
        );
    end else if (IS_MESH || IS_FMESH) begin :mesh
    /* verilator lint_off WIDTH */ 
        if(ROUTE_NAME == "DOR") begin : xy_routing_blk
    /* verilator lint_on WIDTH */ 
            xy_mesh_routing #(
                .NX(NX),
                .NY(NY)                   
            ) xy_routing (
                .current_x(current_router_addr_i.x),
                .current_y(current_router_addr_i.y),
                .dest_x(dest_router_addr_i.x),
                .dest_y(dest_router_addr_i.y),
                .dstport_encoded(destport)
            );
        end //"DOR"
        /* verilator lint_off WIDTH */ 
        else if(ROUTE_NAME == "WEST_FIRST") begin : west_first_routing_blk
        /* verilator lint_on WIDTH */ 
            west_first_routing #(
                .NX (NX),
                .NY (NY)
            ) west_first (
                .current_x (current_router_addr_i.x),
                .current_y (current_router_addr_i.y),
                .dest_x (dest_router_addr_i.x),
                .dest_y (dest_router_addr_i.y),
                .destport (destport)
            );
        end // WEST_FIRST
        /* verilator lint_off WIDTH */ 
        else if(ROUTE_NAME == "NORTH_LAST") begin : north_last_routing_blk
        /* verilator lint_on WIDTH */ 
            north_last_routing #(
                .NX (NX),
                .NY (NY)
            ) north_last (
                .current_x (current_router_addr_i.x),
                .current_y (current_router_addr_i.y),
                .dest_x (dest_router_addr_i.x),
                .dest_y (dest_router_addr_i.y),
                .destport (destport)
            );
        end // NORTH_LAST
        /* verilator lint_off WIDTH */ 
        else if(ROUTE_NAME == "NEGETIVE_FIRST") begin : negetive_first_routing_blk
        /* verilator lint_on WIDTH */ 
            negetive_first_routing #(
                .NX (NX),
                .NY (NY)
            )  negetive_first (
                .current_x (current_router_addr_i.x),
                .current_y (current_router_addr_i.y),
                .dest_x (dest_router_addr_i.x),
                .dest_y (dest_router_addr_i.y),
                .destport (destport)
            );
        end // NEGETIVE_FIRST           
        /* verilator lint_off WIDTH */ 
        else if(ROUTE_NAME == "ODD_EVEN") begin : odd_even_routing_blk
        /* verilator lint_on WIDTH */ 
            odd_even_routing #(
                .NX (NX),
                .NY (NY),
                .LOCATED_IN_NI (LOCATED_IN_NI)
            ) odd_even (
                .current_x (current_router_addr_i.x),
                .current_y (current_router_addr_i.y),
                .dest_x (dest_router_addr_i.x),
                .dest_y (dest_router_addr_i.y),
                .destport (destport)
            );
        end //ODD_EVEN
        /* verilator lint_off WIDTH */ 
        else if(ROUTE_NAME == "FULL_ADPT") begin : duato_routing_blk
        /* verilator lint_on WIDTH */ 
            duato_mesh_routing #(
                .NX (NX),
                .NY (NY)
            ) duato_full_adaptive (
                .current_x (current_router_addr_i.x),
                .current_y (current_router_addr_i.y),
                .dest_x (dest_router_addr_i.x),
                .dest_y (dest_router_addr_i.y),
                .destport (destport)
            );
        end //FULL_ADPT
    `ifdef SIMULATION
        else begin : not_supported initial $display ("Error: %s is an unsupported routing algorithm for %s topology \n",ROUTE_NAME,TOPOLOGY);end
    `endif
    /* verilator lint_off WIDTH */ 
    end else if (TOPOLOGY == "TORUS" ) begin :torus
        if(ROUTE_NAME == "TRANC_DOR") begin : tranc_routing_blk
    /* verilator lint_on WIDTH */ 
            tranc_xy_routing #(
                .NX (NX),
                .NY (NY)
            ) tranc_xy (
                .current_x (current_router_addr_i.x),
                .current_y (current_router_addr_i.y),
                .dest_x (dest_router_addr_i.x),
                .dest_y (dest_router_addr_i.y),
                .destport_encoded (destport)
            );
        end //"TRANC_DOR"
        /* verilator lint_off WIDTH */ 
        else if(ROUTE_NAME == "TRANC_WEST_FIRST") begin : tranc_west_first_routing_blk
        /* verilator lint_on WIDTH */ 
            tranc_west_first_routing #(
                .NX (NX),
                .NY(NY)
            ) tranc_west_first (
                .current_x (current_router_addr_i.x),
                .current_y (current_router_addr_i.y),
                .dest_x (dest_router_addr_i.x),
                .dest_y (dest_router_addr_i.y),
                .destport (destport)
            );
        end // TRANC_WEST_FIRST
        /* verilator lint_off WIDTH */ 
        else if(ROUTE_NAME == "TRANC_NORTH_LAST") begin : tranc_north_last_routing_blk
        /* verilator lint_on WIDTH */ 
            tranc_north_last_routing #(
                .NX (NX),
                .NY (NY)
            ) tranc_north_last (
                .current_x (current_router_addr_i.x),
                .current_y (current_router_addr_i.y),
                .dest_x (dest_router_addr_i.x),
                .dest_y (dest_router_addr_i.y),
                .destport (destport)
            );
        end // TRANC_NORTH_LAST
        /* verilator lint_off WIDTH */ 
        else if(ROUTE_NAME == "TRANC_NEGETIVE_FIRST") begin : tranc_negetive_first_routing_blk
        /* verilator lint_on WIDTH */ 
            tranc_negetive_first_routing #(
                .NX (NX),
                .NY (NY)
            ) tranc_negetive_first(
                .current_x (current_router_addr_i.x),
                .current_y (current_router_addr_i.y),
                .dest_x (dest_router_addr_i.x),
                .dest_y (dest_router_addr_i.y),
                .destport (destport)
            );
        end // TRANC_NEGETIVE_FIRST
        /* verilator lint_off WIDTH */ 
        else if(ROUTE_NAME == "TRANC_FULL_ADPT") begin : tranc_duato_routing_blk
        /* verilator lint_on WIDTH */ 
            tranc_duato_routing #(
                .NX (NX),
                .NY (NY)
            ) duato_full_adaptive (
                .current_x (current_router_addr_i.x),
                .current_y (current_router_addr_i.y),
                .dest_x (dest_router_addr_i.x),
                .dest_y (dest_router_addr_i.y),
                .destport (destport)
            );
        end //TRANC_FULL_ADPT
        `ifdef SIMULATION
        else begin : not_supported2 initial $display("Error: %s is an unsupported routing algorithm for %s topology",ROUTE_NAME,TOPOLOGY);end
        `endif
    end //TORUS
    /* verilator lint_off WIDTH */ 
    else if (TOPOLOGY == "RING" ) begin :ring
        if(ROUTE_NAME == "TRANC_DOR") begin : tranc_ring_blk
    /* verilator lint_on WIDTH */ 
            tranc_ring_routing #(
                .NX(NX)       
            ) tranc_ring (
                .current_x(current_router_addr_i.x),
                .dest_x(dest_router_addr_i.x),
                .destport(destport)    
            );
        end // "TRANC"
        `ifdef SIMULATION
        else begin : not_supported2 initial $display("Error: %s is an unsupported routing algorithm for %s topology",ROUTE_NAME,TOPOLOGY);end  
        `endif    
        end //"RING"       
    /* verilator lint_off WIDTH */ 
    else if (TOPOLOGY == "LINE" ) begin :ring
        if(ROUTE_NAME == "DOR") begin : tranc_ring_blk
    /* verilator lint_on WIDTH */ 
            xy_line_routing #(
                .NX(NX)                    
            ) xy_routing (
                .current_x(current_router_addr_i.x),
                .dest_x(dest_router_addr_i.x),
                .destport(destport)
            );
        end // "DOR"
        `ifdef SIMULATION
        else begin : not_supported2 initial $display("Error: %s is an unsupported routing algorithm for %s topology",ROUTE_NAME,TOPOLOGY);end
        `endif           
        end //"LINE" 
    `ifdef SIMULATION
    else begin : wrong_topology initial $display("Error: %s is an unsupported topology",TOPOLOGY);end
    `endif
    endgenerate
endmodule


/*************************
*        TRANC_ring
**************************/
module tranc_ring_routing #(
    parameter NX = 4
)(
    current_x,
    dest_x,
    destport
    
);
    function integer log2;
    input integer number;begin   
        log2=(number <=1) ? 1: 0;
        while(2**log2<number) begin    
            log2=log2+1;
        end        
    end   
    endfunction // log2 
    
    localparam
        P = 3,
        Xw = log2(NX),
        DSTw = P-1;
    
    input [Xw-1 : 0] current_x;
    input [Xw-1 : 0] dest_x;
    output  [DSTw -1 : 0] destport;
    
    localparam      
        LOCAL = 3'b001,  
        PLUS = 3'b010,   
        MINUS = 3'b100;
    
    reg [P-1 : 0] destport_one_hot;
    reg tranc_x_plus;
    reg tranc_x_min;
    wire same_x;
    localparam SIGNED_X_WIDTH = (Xw<3) ? 4 : Xw+1;
    
    wire signed [SIGNED_X_WIDTH-1 : 0] xc;//current 
    wire signed [SIGNED_X_WIDTH-1 : 0] xd;//destination
    wire signed [SIGNED_X_WIDTH-1 : 0] xdiff;
    
    assign  xd ={{(SIGNED_X_WIDTH-Xw){1'b0}}, dest_x};
    assign  xc ={{(SIGNED_X_WIDTH-Xw){1'b0}}, current_x [Xw-1 : 0]};
    assign  xdiff = xd-xc;
    
    always@ (*)begin 
        tranc_x_plus =1'b0;
        tranc_x_min =1'b0;
        if(xdiff!=0)begin 
            if ((xdiff ==1) || 
                (xdiff == (-NX+1)) ||
                ((xc == (NX-4)) && (xd == (NX-2))) ||
                ((xc >= (NX-2)) && (xd <= (NX-4))) ||
                ((xdiff> 0) && (xd<= (NX-3)))) 
                    tranc_x_plus = 1'b1;
            else    tranc_x_min = 1'b1;
        end
    end//always
    assign same_x = (xdiff == 0);
    
    always@(*)begin
        destport_one_hot= LOCAL;
        if (same_x ) destport_one_hot= LOCAL;
        else begin 
            if (tranc_x_plus)  destport_one_hot= PLUS;
            else if (tranc_x_min)   destport_one_hot= MINUS;
        end
    end
    line_ring_encode_dstport encode(
        .dstport_one_hot(destport_one_hot),
        .dstport_encoded(destport)
    );
    
endmodule



/********************************************
*                        xy_line
*********************************************/
module xy_line_routing #(
    parameter NX = 8      
)(
    current_x,
    dest_x,
    destport
);
    function integer log2;
    input integer number;begin   
        log2=(number <=1) ? 1: 0;
        while(2**log2<number) begin    
            log2=log2+1;
        end        
    end   
    endfunction // log2 
    
    localparam  
        OUT_BIN = 0,
        P = 3,
        Xw = log2(NX);
    
    input [Xw-1 : 0] current_x;
    input [Xw-1 : 0] dest_x;
    output  [1 : 0] destport;
    
    localparam      
        LOCAL = (OUT_BIN)?  3'd0 : 3'b001,  
        PLUS = (OUT_BIN)?  3'd1 : 3'b010,
        MINUS = (OUT_BIN)?  3'd2 : 3'b100;
        
    reg [P-1 : 0] destport_one_hot;
    
    always@(*)begin
        destport_one_hot = LOCAL [2 : 0];
        if (dest_x    > current_x)        destport_one_hot = PLUS  [2 : 0];
        else if (dest_x    < current_x)        destport_one_hot = MINUS [2 : 0];
    end
    
    line_ring_encode_dstport encode(
        .dstport_one_hot(destport_one_hot),
        .dstport_encoded(destport)
    );
    
endmodule


module line_ring_encode_dstport (
    dstport_one_hot,
    dstport_encoded
);
    input [2 : 0] dstport_one_hot;
    output [1 : 0] dstport_encoded;
    
    
    localparam  
        FORWARD = 2'd1,
        BACKWARD = 2'd2;
    /************************   
    *   destination-port_in
    *       2'b11 : FORWARD or BACKWARD // can be sent to any of them
    *       2'b10 : BACKWARD
    *       2'b01 : FORWARD
    *       2'b00 : LOCAL
    *******************/
    // code the destination port
    assign dstport_encoded = {dstport_one_hot[BACKWARD], dstport_one_hot[FORWARD]};
endmodule


module line_ring_decode_dstport (
    dstport_one_hot,
    dstport_encoded
);
    output  reg [2 : 0] dstport_one_hot;
    input [1 : 0] dstport_encoded;
    
    always @(*)begin 
        dstport_one_hot = 3'b000;
        case(dstport_encoded)
            2'b10 : dstport_one_hot=3'b100;
            2'b01 : dstport_one_hot=3'b010;
            2'b00 : dstport_one_hot=3'b001;
            2'b11 : dstport_one_hot=3'b110;//invalid condition in determinstic routing
        endcase
    end //always
endmodule

module line_ring_destport_decode_decimal (
    destport_decimal,
    destport_encoded
);
    import pronoc_pkg::*;
    output  reg [1 : 0] destport_decimal;
    input [1 : 0] destport_encoded;
    localparam Pw=2;
    
    always @(*)begin 
        destport_decimal = Pw'(LOCAL);
        case(destport_encoded)
            2'b10 : destport_decimal=Pw'(BACKWARD);
            2'b01 : destport_decimal=Pw'(FORWARD);
            2'b00 : destport_decimal=Pw'(LOCAL);
            2'b11 : destport_decimal=Pw'(LOCAL);//invalid condition in determinstic routing
        endcase
    end //always
endmodule

module regular_topo_decode_dstport (
    dstport_encoded,
    dstport_one_hot
);
    input [3 : 0] dstport_encoded;
    output  reg [4 : 0] dstport_one_hot;
    wire x,y,a,b;
    assign {x,y,a,b} = dstport_encoded;
    always @(*)begin 
        dstport_one_hot = 5'd0;
        case({a,b})
            2'b10 : dstport_one_hot = {1'b0,~x,1'b0,x,1'b0};
            2'b01 : dstport_one_hot = {~y,1'b0,y,1'b0,1'b0};
            2'b11 : dstport_one_hot = {1'b0,~x,1'b0,x,1'b0};//illegal
            2'b00 : dstport_one_hot = 5'b00001;
        endcase
   end //always
endmodule 

module regular_topo_destport_decode_decimal (
    destport_encoded,
    destport_decimal
);
    import pronoc_pkg::*;
    input [3 : 0] destport_encoded;
    output reg [2 : 0] destport_decimal;
    localparam Pw=3;
    wire x,y,a,b;
    assign {x,y,a,b} = destport_encoded;
    
    always_comb begin
    destport_decimal = 0;
    case ({a, b})   
        2'b10: destport_decimal = (x) ? Pw'(EAST) : Pw'(WEST);// 1=East, 2=West
        2'b01: destport_decimal = (y) ? Pw'(NORTH) : Pw'(SOUTH);// 3=North, 4=South
        2'b11: begin
            // Both directions is illegal for decimal output
            destport_decimal = (x) ? Pw'(EAST) : Pw'(WEST);
        end
        2'b00: begin
            // Local node
            destport_decimal = Pw'(LOCAL);
        end
    endcase
    end
endmodule


module regular_topo_full_adapt_ovc_avail #(
    parameter P = 4
) (
    reset,clk,
    empty_all_next,
    full_all_next,
    nearly_full_all_next,
    ovc_status,
    ovc_avalable_all
);
    import pronoc_pkg::*;
    localparam PV = P * V;
    localparam [V-1 : 0] ADAPTIVE_VC_MASK = ~ ESCAP_VC_MASK;
    input [PV-1 : 0] empty_all_next, full_all_next,  nearly_full_all_next,ovc_status;
    output [PV-1 : 0]ovc_avalable_all;
    input reset,clk;
    reg [PV-1 : 0] full_adaptive_ovc_mask,full_adaptive_ovc_mask_next;
    always_comb begin
        for( int k=0;k<PV;k=k+1) begin
        //in full adaptive routing, adaptive VCs located in y axies can not be reallocated non-atomicly
            if( AVC_ATOMIC_EN == 0) begin :avc_atomic
                if((((k/V) == NORTH ) || ((k/V) == SOUTH )) && (  ADAPTIVE_VC_MASK[k%V]))  
                    full_adaptive_ovc_mask_next[k] = empty_all_next[k];
                else 
                    full_adaptive_ovc_mask_next[k] = (OVC_ALLOC_MODE)? ~full_all_next[k] : ~nearly_full_all_next[k];
            end else begin :avc_nonatomic
                if(  ADAPTIVE_VC_MASK[k%V])  
                    full_adaptive_ovc_mask_next[k] = empty_all_next[k];
                else    
                    full_adaptive_ovc_mask_next[k] = (OVC_ALLOC_MODE)? ~full_all_next[k] :~nearly_full_all_next[k];
            end
         end // for  
    end//always
    always_ff @ (`pronoc_clk_reset_edge) begin
        if (`pronoc_reset) begin
            full_adaptive_ovc_mask <= '0;
        end else begin
            full_adaptive_ovc_mask <= full_adaptive_ovc_mask_next;
        end
    end    
    assign ovc_avalable_all   = ~ovc_status & full_adaptive_ovc_mask;
endmodule
