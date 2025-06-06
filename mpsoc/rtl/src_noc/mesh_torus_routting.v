`include "pronoc_def.v"
/************************************
*
*    mesh_torus_look_ahead_routing
*
*************************************/

module mesh_torus_look_ahead_routing #(
    parameter NX = 4,
    parameter NY = 4,
    parameter SW_LOC = 0,
    parameter TOPOLOGY = "MESH",//"MESH","TORUS"
    parameter ROUTE_NAME = "XY",// 
    parameter ROUTE_TYPE = "DETERMINISTIC"// "DETERMINISTIC", "FULL_ADAPTIVE", "PAR_ADAPTIVE"
)
(
    current_x,  //current router x address
    current_y,  //current router y address
    dest_x,  // destination router x address          
    dest_y,  // destination router y address                  
    destport_encoded,   // current router destination port number       
    lkdestport_encoded, // look ahead destination port number
    reset,
    clk
);
    
     /* verilator lint_off WIDTH */ 
    localparam  P = (TOPOLOGY == "MESH" || TOPOLOGY == "FMESH" || TOPOLOGY == "TORUS")?  5:3;
     /* verilator lint_on WIDTH */ 
    
    function integer log2;
    input integer number; begin   
        log2=(number <=1) ? 1: 0;    
        while(2**log2<number) begin    
            log2=log2+1;    
        end        
    end   
    endfunction // log2 
    
    localparam  
        P_1 = P-1,
        Xw = log2(NX),   // number of node in x axis
        Yw = (TOPOLOGY=="RING" || TOPOLOGY == "LINE") ? 1 : log2(NY);    // number of node in y axis
    
    input [Xw-1 : 0]  current_x;
    input [Yw-1 : 0]  current_y;                  
    input [Xw-1 : 0]  dest_x;
    input [Yw-1 : 0]  dest_y;
    input [P_1-1 : 0]  destport_encoded;
    output  [P_1-1 : 0]  lkdestport_encoded;
    input          reset,clk;
    
    wire [Xw-1 : 0]  destx_delayed;
    wire [Yw-1 : 0]  desty_delayed;
    wire [P_1-1 : 0]  destport_delayed;
    // routing algorithm
    generate 
    /* verilator lint_off WIDTH */ 
    if(ROUTE_TYPE=="DETERMINISTIC") begin :dtrmst
    /* verilator lint_on WIDTH */ 
        mesh_torus_deterministic_look_ahead_routing #(
            .P(P),
            .NX(NX),
            .NY(NY),
            .SW_LOC(SW_LOC),
            .TOPOLOGY(TOPOLOGY),
            .ROUTE_NAME(ROUTE_NAME)
        ) deterministic_look_ahead(
            .current_x(current_x),
            .current_y(current_y),
            .dest_x(destx_delayed),
            .dest_y(desty_delayed),
            .destport(destport_delayed),
            .lkdestport(lkdestport_encoded)
        );
    end else begin :adapt
        mesh_torus_adaptive_look_ahead_routing #(
            .P(P),
            .NX(NX),
            .NY(NY),
            .TOPOLOGY(TOPOLOGY),
            .ROUTE_NAME(ROUTE_NAME),
            .ROUTE_TYPE(ROUTE_TYPE)
        ) adaptive_look_ahead (
            .current_x(current_x),
            .current_y(current_y),
            .dest_x(destx_delayed),
            .dest_y(desty_delayed),
            .destport_encoded(destport_delayed),
            .lkdestport_encoded(lkdestport_encoded)
        );
    end
    endgenerate

    pronoc_register #(.W(Xw) ) reg1 (.D_in(dest_x ), .Q_out(destx_delayed), .reset(reset), .clk(clk));
    pronoc_register #(.W(Yw) ) reg2 (.D_in(dest_y ), .Q_out(desty_delayed), .reset(reset), .clk(clk));
    pronoc_register #(.W(P_1)) reg3 (.D_in(destport_encoded ), .Q_out(destport_delayed), .reset(reset), .clk(clk));
endmodule


/************************************************
*    deterministic_look_ahead_routing
**********************************************/

module  mesh_torus_deterministic_look_ahead_routing #(
    parameter P =5,
    parameter NX =4,
    parameter NY =4,
    parameter SW_LOC =0,
    parameter TOPOLOGY ="MESH",//"MESH","TORUS"
    parameter ROUTE_NAME="XY"// "XY", "TRANC_XY"
) (
    current_x,  //current router x address
    current_y,  //current router y address
    dest_x,  // destination router x address          
    dest_y,  // destination router y address                  
    destport,   // current router destination port number       
    lkdestport // look ahead destination port number
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
        P_1 = P-1,
        Xw = log2(NX),   // number of node in x axis
        Yw = (TOPOLOGY=="RING" || TOPOLOGY == "LINE") ? 1 : log2(NY);    // number of node in y axis
    
    input [Xw-1 : 0]  current_x;
    input [Yw-1 : 0]  current_y;                  
    input [Xw-1 : 0]  dest_x;
    input [Yw-1 : 0]  dest_y;
    input [P_1-1 : 0]  destport;
    output  [P_1-1 : 0]  lkdestport;
    
    wire [Xw-1 : 0]  next_x;
    wire [Yw-1 : 0]  next_y; 
    wire [P-1 : 0]  destport_one_hot;
    generate 
    /* verilator lint_off WIDTH */ 
    if (TOPOLOGY == "MESH" || TOPOLOGY == "TORUS" || TOPOLOGY == "FMESH" ) begin: twoD
    /* verilator lint_on WIDTH */   
    mesh_tori_decode_dstport decoder(
        .dstport_encoded(destport),
        .dstport_one_hot(destport_one_hot)
    );
    end else begin :oneD
        line_ring_decode_dstport decoder(
            .dstport_encoded(destport),
            .dstport_one_hot(destport_one_hot)
        );
    end
    endgenerate 
    
    mesh_torus_next_router_addr_predictor #(
        .P(P),
        .TOPOLOGY(TOPOLOGY),
        .NX(NX),
        .NY(NY)
    ) addr_predictor(
        .destport(destport_one_hot),
        .current_x(current_x),
        .current_y(current_y),
        .next_x(next_x),
        .next_y(next_y)
    );
    wire [P_1-1 : 0] lkdestport_encoded;
    
    mesh_torus_conventional_routing #(
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),
        .ROUTE_TYPE("DETERMINISTIC"),
        .NX(NX),
        .NY(NY),
        .LOCATED_IN_NI(0)
    ) conv_routing (
        .current_x(next_x),
        .current_y(next_y),
        .dest_x(dest_x),
        .dest_y(dest_y),
        .destport(lkdestport_encoded)
    );
    
    //take the value of a&b only.  x&y can be obtained from destport in the router
    assign lkdestport = lkdestport_encoded;//[1: 0];
endmodule


/************************************************
*        adaptive_look_ahead_routing
**********************************************/
module  mesh_torus_adaptive_look_ahead_routing #(
    parameter P =5,
    parameter NX =4,
    parameter NY =4,
    parameter TOPOLOGY ="MESH",//"MESH","TORUS"
    parameter ROUTE_NAME="WEST_FIRST",
    parameter ROUTE_TYPE="DETERMINISTIC"
)(
    current_x,  //current router x address
    current_y,  //current router y address
    dest_x,  // destination router x address          
    dest_y,  // destination router y address                  
    destport_encoded,   // current router destination port      
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
        P_1 = P-1,
        Xw = log2(NX),   // number of node in x axis
        Yw = log2(NY);    // number of node in y axis
    
    input [Xw-1 : 0]  current_x;
    input [Yw-1 : 0]  current_y;                  
    input [Xw-1 : 0]  dest_x;
    input [Yw-1 : 0]  dest_y;
    input [P_1-1 : 0]  destport_encoded;
    output  [P_1-1 : 0]  lkdestport_encoded;
    /**************************
    *    destination-port coded
    *            x: 1 EAST, 0 WEST  
    *            y: 1 NORTH, 0 SOUTH
    *            ab: 00 : LOCAL, 10: xdir, 01: ydir, 11 x&y dir 
    **************************/       
    wire x,y,a,b;
    wire [Xw-1 : 0]  next_x;
    wire [Yw-1 : 0]  next_y; 
    wire [P_1-1 : 0]  lkdestport_x,lkdestport_y;
    reg [P-1 : 0]  destport_x, destport_y;
    
    assign {x,y,a,b} = destport_encoded;
    always @(*)begin 
        destport_x = 5'd0;
        destport_y = 5'd0;
        case({a,b})
            2'b10 : destport_x = {1'b0,~x,1'b0,x,1'b0};
            2'b01 : destport_y = {~y,1'b0,y,1'b0,1'b0};
            2'b11 : begin destport_x = {1'b0,~x,1'b0,x,1'b0}; destport_y = {~y,1'b0,y,1'b0,1'b0}; end
            2'b00 : begin destport_x = 5'b00001;destport_y = 5'b00001; end 
        endcase
   end //always
    
    mesh_torus_next_router_addr_predictor #(
        .P(P),
        .TOPOLOGY(TOPOLOGY),
        .NX(NX),
        .NY(NY)
    ) addr_predictor_x (
        .destport(destport_x),
        .current_x(current_x),
        .current_y(current_y),
        .next_x(next_x),
        .next_y()
    );
    
    mesh_torus_next_router_addr_predictor #(
        .P(P),
        .TOPOLOGY(TOPOLOGY),
        .NX(NX),
        .NY(NY)
    )  addr_predictor_y (
        .destport(destport_y),
        .current_x(current_x),
        .current_y(current_y),
        .next_x(),
        .next_y(next_y)
    );
    
    mesh_torus_conventional_routing #(
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),
        .ROUTE_TYPE(ROUTE_TYPE),
        .NX(NX),
        .NY(NY),
        .LOCATED_IN_NI(0)
    ) conv_route_x (
        .current_x(next_x),
        .current_y(current_y),
        .dest_x(dest_x),
        .dest_y(dest_y),
        .destport(lkdestport_x)
    );
    
    mesh_torus_conventional_routing #(
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),
        .ROUTE_TYPE(ROUTE_TYPE),
        .NX(NX),
        .NY(NY),
        .LOCATED_IN_NI(0)
    ) conv_route_y (
        .current_x(current_x),
        .current_y(next_y),
        .dest_x(dest_x),
        .dest_y(dest_y),
        .destport(lkdestport_y)
    );
    //take the value of a&b only.  x&y can be obtained from destport in the router
    assign lkdestport_encoded = {lkdestport_x[1: 0],lkdestport_y[1: 0]};
endmodule

/********************************************************
*         next_router_addr_predictor
*    Determine the next router address based 
*    on the packet destination port   
********************************************************/

module mesh_torus_next_router_addr_predictor #(
    parameter P = 5,
    parameter TOPOLOGY ="MESH",
    parameter NX = 4,//toutal number of router in x direction 
    parameter NY = 4//toutal number of router in y direction 
)(
    destport,
    current_x,
    current_y,
    next_x,
    next_y  
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
        Xw = log2(NX),
        Yw = (TOPOLOGY=="RING" || TOPOLOGY == "LINE")? 1 : log2(NY);
    // mesh torus            
    localparam
        EAST = 3'd1, 
        NORTH = 3'd2,  
        WEST = 3'd3,  
        SOUTH = 3'd4;
    //ring line            
    localparam  
        FORWARD = 2'd1,
        BACKWARD = 2'd2;
    
    localparam [Xw-1 : 0] LAST_X_ADDR =(NX[Xw-1 : 0]-1'b1);
    localparam [Yw-1 : 0] LAST_Y_ADDR =(NY[Yw-1 : 0]-1'b1);                
    
    input [P-1 : 0]  destport;
    input [Xw-1 : 0]  current_x;
    input [Yw-1 : 0]  current_y;
    output reg [Xw-1 : 0]  next_x;
    output reg [Yw-1 : 0]  next_y;  
    
    generate 
    /* verilator lint_off WIDTH */                                             
    if(TOPOLOGY=="MESH" || TOPOLOGY == "TORUS" || TOPOLOGY == "FMESH" ) begin : mesh
    /* verilator lint_on WIDTH */ 
        always @(*) begin
             //default values 
            next_x= current_x;
            next_y= current_y;
            if(destport[EAST]) begin   
                next_x= (current_x==LAST_X_ADDR ) ? {Xw{1'b0}} : current_x+1'b1;
                next_y = current_y;    
            end       
            else if(destport[NORTH])  begin   
                next_x= current_x;
                next_y= (current_y==0)? LAST_Y_ADDR : current_y-1'b1;
            end
            else  if(destport[WEST])       begin 
                next_x= (current_x==0) ? LAST_X_ADDR : current_x-1'b1;
                next_y = current_y;
            end
            else  if(destport[SOUTH])  begin
                next_x= current_x;
                next_y= (current_y== LAST_Y_ADDR ) ? {Yw{1'b0}}: current_y+1'b1;
            end
        end//always
    /* verilator lint_off WIDTH */     
    end else  if(TOPOLOGY=="RING" || TOPOLOGY == "LINE") begin : ring
    /* verilator lint_on WIDTH */ 
        always @(*) begin
             //default values 
            next_x= current_x;
            next_y= 1'b0;
            if(destport[FORWARD]) begin   
                next_x= (current_x==LAST_X_ADDR ) ? {Xw{1'b0}} : current_x+1'b1;
                
            end       
            else if(destport[BACKWARD])  begin   
                next_x= (current_x=={Xw{1'b0}} ) ? LAST_X_ADDR : current_x-1'b1;
            end
        end//always
    end
    `ifdef SIMULATION
    else begin : wrong_topology initial $display("Error: next router inport is not predicted for %s   topology",TOPOLOGY); end
    `endif       
    endgenerate 
endmodule       

/*******************************************************
*            next_router_inport_predictor
*********************************************************/
module mesh_torus_next_router_inport_predictor #(
    parameter TOPOLOGY ="MESH",
    parameter P =5
)(
    destport,
    receive_port
);
    input [P-1 : 0] destport;
    output  [P-1 : 0] receive_port; 
    
    localparam  
        LOCAL = 3'd0, 
        EAST = 3'd1, 
        NORTH = 3'd2,  
        WEST = 3'd3,  
        SOUTH = 3'd4; 
    generate
    /* verilator lint_off WIDTH */ 
    if(TOPOLOGY=="MESH" || TOPOLOGY == "TORUS" || TOPOLOGY == "FMESH") begin : mesh
    /* verilator lint_on WIDTH */ 
        assign  receive_port[LOCAL] = destport[LOCAL];
        assign  receive_port[WEST] = destport[EAST];
        assign  receive_port[EAST] = destport[WEST];
        assign  receive_port[NORTH] = destport[SOUTH];
        assign  receive_port[SOUTH] = destport[NORTH];
    /* verilator lint_off WIDTH */ 
    end else  if(TOPOLOGY=="RING" || TOPOLOGY == "LINE") begin : ring
    /* verilator lint_on WIDTH */ 
        assign  receive_port[0] = destport[0];
        assign  receive_port[1] = destport[2];
        assign  receive_port[2] = destport[1];
    end
    `ifdef SIMULATION
            else begin : wrong_topology initial $display("Error: next router inport is not predicted for %s   topology",TOPOLOGY); end
    `endif
    endgenerate
endmodule 

/***********************************
*            remove_sw_loc_one_hot
*remove port number that is holdind the packet               
*
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
    
    function integer log2;
    input integer number; begin   
        log2=(number <=1) ? 1: 0;    
        while(2**log2<number) begin    
            log2=log2+1;    
        end        
    end   
    endfunction // log2 
    
    localparam 
        P_1 = P-1,
        Pw = log2(P),
        P_1w = log2(P_1);
    input [P-1 : 0]  destport_in;
    input [P-1 : 0]  receiver_port;
    output [P_1-1 : 0]  destport_out;
    wire [Pw-1 : 0]  receiver_port_bin,destport_in_bin;
    wire [P_1w-1 : 0]  destport_out_bin;
    
    one_hot_to_bin #(
        .ONE_HOT_WIDTH(P),
        .BIN_WIDTH(Pw)
    ) convert1(
        .one_hot_code(receiver_port),
        .bin_code(receiver_port_bin)
    );
    
    one_hot_to_bin #(
        .ONE_HOT_WIDTH(P),
        .BIN_WIDTH(Pw)
    )convert2(
        .one_hot_code(destport_in),
        .bin_code(destport_in_bin)
    );
    
    wire [Pw-1 : 0] temp;
    assign temp = (receiver_port_bin > destport_in_bin ) ? destport_in_bin : destport_in_bin  -1'b1;
    assign destport_out_bin=temp[P_1w-1 : 0];
    
    bin_to_one_hot #(
        .BIN_WIDTH(P_1w),
        .ONE_HOT_WIDTH(P_1)
    ) convert3 (
        .bin_code(destport_out_bin),
        .one_hot_code(destport_out)
    );
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
    
    integer i;   
    always @(*)begin 
        for(i=0;i<P;i=i+1)begin :port_loop
            if (i>SW_LOC)      destport_out[i] = destport_in[i-1];
            else if (i==SW_LOC)     destport_out[i] = 1'b0;
            else                    destport_out[i] = destport_in[i];
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
module mesh_torus_conventional_routing #(
    parameter TOPOLOGY = "MESH", 
    parameter ROUTE_NAME = "XY",
    parameter ROUTE_TYPE = "DETERMINISTIC",    
    parameter NX   = 4,
    parameter NY   = 4,
    parameter LOCATED_IN_NI = 0//use for add even only
    ) (   
    current_x,
    current_y,
    dest_x,
    dest_y,
    destport
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
        /* verilator lint_off WIDTH */ 
        P = (TOPOLOGY=="RING" || TOPOLOGY=="LINE" )? 3 : 5,
        Yw = (TOPOLOGY=="RING" || TOPOLOGY=="LINE" )? 1 : log2(NY),
        /* verilator lint_on WIDTH */ 
        P_1 = P-1,
        Xw = log2(NX),        
        DSTw = P_1;               
    
    input [Xw-1 : 0] current_x;
    input [Yw-1 : 0] current_y;
    input [Xw-1 : 0] dest_x;
    input [Yw-1 : 0] dest_y;    
    output  [DSTw-1 : 0] destport;
    
    generate 
    /* verilator lint_off WIDTH */ 
    if (TOPOLOGY == "MESH" || TOPOLOGY == "FMESH")begin :mesh
        if(ROUTE_NAME == "XY") begin : xy_routing_blk
    /* verilator lint_on WIDTH */ 
            xy_mesh_routing #(
                .NX(NX),
                .NY(NY)                   
            ) xy_routing (
                .current_x(current_x),
                .current_y(current_y),
                .dest_x(dest_x),
                .dest_y(dest_y),
                .dstport_encoded(destport)
            );        
        end //"XY"
        /* verilator lint_off WIDTH */ 
        else if(ROUTE_NAME == "WEST_FIRST") begin : west_first_routing_blk
        /* verilator lint_on WIDTH */ 
            west_first_routing #(
                .NX (NX),
                .NY (NY)
            ) west_first (
                .current_x (current_x),
                .current_y (current_y),
                .dest_x (dest_x),
                .dest_y (dest_y),
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
                .current_x (current_x),
                .current_y (current_y),
                .dest_x (dest_x),
                .dest_y (dest_y),
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
                .current_x (current_x),
                .current_y (current_y),
                .dest_x (dest_x),
                .dest_y (dest_y),
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
                .current_x (current_x),
                .current_y (current_y),
                .dest_x (dest_x),
                .dest_y (dest_y),
                .destport (destport)
            );
        end //ODD_EVEN
        /* verilator lint_off WIDTH */ 
        else if(ROUTE_NAME == "DUATO") begin : duato_routing_blk
        /* verilator lint_on WIDTH */ 
            duato_mesh_routing #(
                .NX (NX),
                .NY (NY)                    
            ) duato_full_adaptive (
                .current_x (current_x),
                .current_y (current_y),
                .dest_x (dest_x),
                .dest_y (dest_y),
                .destport (destport)
            );
        end //DUATO
    `ifdef SIMULATION
        else begin : not_supported initial $display ("Error: %s is an unsupported routing algorithm for %s topology \n",ROUTE_NAME,TOPOLOGY); end
    `endif
    /* verilator lint_off WIDTH */ 
    end else if (TOPOLOGY == "TORUS" ) begin :torus
        if(ROUTE_NAME == "TRANC_XY") begin : tranc_routing_blk
    /* verilator lint_on WIDTH */ 
            tranc_xy_routing #(
                .NX (NX),
                .NY (NY)
            ) tranc_xy (
                .current_x (current_x),
                .current_y (current_y),
                .dest_x (dest_x),
                .dest_y (dest_y),
                .destport_encoded (destport)
            );
        end //"TRANC_XY"
        /* verilator lint_off WIDTH */ 
        else if(ROUTE_NAME == "TRANC_WEST_FIRST") begin : tranc_west_first_routing_blk
        /* verilator lint_on WIDTH */ 
            tranc_west_first_routing #(
                .NX (NX),
                .NY(NY)
            ) tranc_west_first (
                .current_x (current_x),
                .current_y (current_y),
                .dest_x (dest_x),
                .dest_y (dest_y),
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
                .current_x (current_x),
                .current_y (current_y),
                .dest_x (dest_x),
                .dest_y (dest_y),
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
                .current_x (current_x),
                .current_y (current_y),
                .dest_x (dest_x),
                .dest_y (dest_y),
                .destport (destport)
            );
        end // TRANC_NEGETIVE_FIRST
        /* verilator lint_off WIDTH */ 
        else if(ROUTE_NAME == "TRANC_DUATO") begin : tranc_duato_routing_blk
        /* verilator lint_on WIDTH */ 
            tranc_duato_routing #(
                .NX (NX),
                .NY (NY)
            ) duato_full_adaptive (
                .current_x (current_x),
                .current_y (current_y),
                .dest_x (dest_x),
                .dest_y (dest_y),
                .destport (destport)
            );
        end //TRANC_DUATO
        `ifdef SIMULATION
        else begin : not_supported2 initial $display("Error: %s is an unsupported routing algorithm for %s topology",ROUTE_NAME,TOPOLOGY); end
        `endif
    end //TORUS
    /* verilator lint_off WIDTH */ 
    else if (TOPOLOGY == "RING" ) begin :ring
        if(ROUTE_NAME == "TRANC_XY") begin : tranc_ring_blk
    /* verilator lint_on WIDTH */ 
            tranc_ring_routing #(
                .NX(NX)       
            ) tranc_ring (
                .current_x(current_x),
                .dest_x(dest_x),
                .destport(destport)    
            );
        end // "TRANC"
        `ifdef SIMULATION
        else begin : not_supported2 initial $display("Error: %s is an unsupported routing algorithm for %s topology",ROUTE_NAME,TOPOLOGY); end  
        `endif    
        end //"RING"       
    /* verilator lint_off WIDTH */ 
    else if (TOPOLOGY == "LINE" ) begin :ring
        if(ROUTE_NAME == "XY") begin : tranc_ring_blk
    /* verilator lint_on WIDTH */ 
            xy_line_routing #(
                .NX(NX)                    
            ) xy_routing (
                .current_x(current_x),
                .dest_x(dest_x),
                .destport(destport)
            );       
        end // "XY"
        `ifdef SIMULATION
        else begin : not_supported2 initial $display("Error: %s is an unsupported routing algorithm for %s topology",ROUTE_NAME,TOPOLOGY); end
        `endif           
        end //"LINE" 
    `ifdef SIMULATION
    else begin : wrong_topology initial $display("Error: %s is an unsupported topology",TOPOLOGY); end
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
    input integer number; begin   
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
        if (same_x ) destport_one_hot= LOCAL;
        else    begin 
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
    input integer number; begin   
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
            2'b11 : dstport_one_hot=3'b110; //invalid condition in determinstic routing
        endcase
    end //always
endmodule


module mesh_tori_decode_dstport (
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
            2'b11 : dstport_one_hot = {1'b0,~x,1'b0,x,1'b0}; //illegal
            2'b00 : dstport_one_hot = 5'b00001;
        endcase
   end //always
endmodule 