/****************************************************************************
 * wrapper.sv
 ****************************************************************************/

/**
 * Module: pronoc_to_piton_wrapper
 * 
 * TODO: Add module documentation
 */
`timescale      1ns/1ps

`include "define.tmp.h"
`include "pronoc_def.v"



module piton_to_pronoc_endp_addr_converter
#(
    parameter CHIP_SET_PORT = 3,
    parameter NOC_ID=0
) (
    default_chipid_i,
    piton_chipid_i,
    piton_coreid_x_i,
    piton_coreid_y_i,
    piton_fbits_i,
    pronoc_endp_addr_o,
    piton_end_addr_coded_o
);

    `NOC_CONF

    localparam  
        PRESERVED_DATw = (`MSG_LENGTH_WIDTH + `MSG_TYPE_WIDTH + `MSG_MSHRID_WIDTH + `MSG_OPTIONS_1_WIDTH ),
        HEAD_DATw      = (64-MSB_BE-1),
        ADDR_CODED     = (HEAD_DATw - PRESERVED_DATw);
    
    input  [`NOC_CHIPID_WIDTH-1:0]  default_chipid_i;
    input  [`NOC_CHIPID_WIDTH-1:0]  piton_chipid_i;
    input  [`NOC_X_WIDTH-1:0]       piton_coreid_x_i;
    input  [`NOC_Y_WIDTH-1:0]       piton_coreid_y_i;
    input  [`MSG_SRC_FBITS_WIDTH-1:0]  piton_fbits_i;       
    output [EAw-1 : 0] pronoc_endp_addr_o;
    output [ADDR_CODED-1 : 0] piton_end_addr_coded_o;
    
    generate 
        if(T3==1) begin:same
            piton_to_pronoc_endp_addr_converter_same_topology  #(
                .CHIP_SET_PORT(CHIP_SET_PORT),
                .NOC_ID(NOC_ID)
            ) conv (
                .default_chipid_i  (default_chipid_i),
                .piton_chipid_i    (piton_chipid_i),
                .piton_coreid_x_i  (piton_coreid_x_i),
                .piton_coreid_y_i  (piton_coreid_y_i),
                .piton_fbits_i     (piton_fbits_i ),                    
                .pronoc_endp_addr_o (pronoc_endp_addr_o),
                .piton_end_addr_coded_o(piton_end_addr_coded_o)        
            );    
        end else begin :diff
            piton_to_pronoc_endp_addr_converter_diffrent_topology  #(
                .CHIP_SET_PORT(CHIP_SET_PORT),
                .NOC_ID(NOC_ID)
            ) conv (
                .default_chipid_i  (default_chipid_i),
                .piton_chipid_i    (piton_chipid_i),
                .piton_coreid_x_i  (piton_coreid_x_i),
                .piton_coreid_y_i  (piton_coreid_y_i),
                .piton_fbits_i     (piton_fbits_i ),                    
                .pronoc_endp_addr_o (pronoc_endp_addr_o),
                .piton_end_addr_coded_o(piton_end_addr_coded_o)        
            );    
        end 
    endgenerate
endmodule


module piton_to_pronoc_endp_addr_converter_diffrent_topology
#(
    parameter CHIP_SET_PORT = 3,
    parameter NOC_ID=0
)(
    default_chipid_i,
    piton_chipid_i,
    piton_coreid_x_i,
    piton_coreid_y_i,
    piton_fbits_i,
    pronoc_endp_addr_o,
    piton_end_addr_coded_o
);

    `NOC_CONF
    localparam  
        PRESERVED_DATw = (`MSG_LENGTH_WIDTH + `MSG_TYPE_WIDTH + `MSG_MSHRID_WIDTH + `MSG_OPTIONS_1_WIDTH ),
        HEAD_DATw      = (64-MSB_BE-1),
        ADDR_CODED     = (HEAD_DATw - PRESERVED_DATw);
    input  [`NOC_CHIPID_WIDTH-1:0]  default_chipid_i;
    input  [`NOC_CHIPID_WIDTH-1:0]  piton_chipid_i;
    input  [`NOC_X_WIDTH-1:0]       piton_coreid_x_i;
    input  [`NOC_Y_WIDTH-1:0]       piton_coreid_y_i;
    input  [`MSG_SRC_FBITS_WIDTH-1:0]  piton_fbits_i;       
    output reg [EAw-1 : 0] pronoc_endp_addr_o;
    output reg [ADDR_CODED-1 : 0] piton_end_addr_coded_o;
    localparam [3:0] 
        FBIT_NONE = 4'b0000,
        FBIT_W  = 4'b0010,
        FBIT_S  = 4'b0011,
        FBIT_E  = 4'b0100,
        FBIT_N  = 4'b0101;
    localparam       
        Xw = log2(NX),    // number of node in x axis
        Yw = log2(NY);    // number of node in y axis       
    localparam 
        PITON_TOPOLOGY = "FMESH",
        PITON_Xw = log2(`PITON_X_TILES),    // number of node in x axis
        PITON_Yw = log2(`PITON_Y_TILES),    // number of node in y axis         
        PITON_NE =(`PITON_X_TILES * `PITON_Y_TILES) + 2 * (`PITON_X_TILES+`PITON_Y_TILES),
        PITON_MAX_P = 5, 
        PITON_NLw= log2(PITON_MAX_P),
        PITON_EAw = PITON_Xw + PITON_Yw + log2(PITON_MAX_P),
        PITON_NEw = log2(PITON_NE);
    wire [PITON_NLw-1: 0] piton_edge_port;
    assign piton_edge_port =
        (piton_fbits_i [3:0] == FBIT_NONE) ? LOCAL:
        (piton_fbits_i [3:0] == FBIT_W   ) ? WEST:
        (piton_fbits_i [3:0] == FBIT_S   ) ? SOUTH:
        (piton_fbits_i [3:0] == FBIT_E   ) ? EAST: NORTH;
    wire [PITON_Xw-1 : 0] piton_x =  piton_coreid_x_i;
    wire [PITON_Xw-1 : 0] piton_y =  piton_coreid_y_i;
    wire [EAw-1 : 0] pronoc_endp_addr , chipset_endp_addr;
    wire [EAw-1 : 0] pronoc_endp_addr1,pronoc_endp_addr2;
    wire [PITON_NLw-1: 0] piton_l = (piton_chipid_i == default_chipid_i ) ? piton_edge_port  : CHIP_SET_PORT;
    //find  piton index
    wire [PITON_EAw-1 : 0] piton_e_addr = {piton_l,piton_y,piton_x}; 
    wire [PITON_NEw-1 : 0] piton_id;
    endp_addr_decoder #( .TOPOLOGY(PITON_TOPOLOGY),   .T1(`PITON_X_TILES), .T2(`PITON_Y_TILES), .T3(1), .EAw(PITON_EAw),  .NE(PITON_NE))
        encode1 ( .id(piton_id), .code(piton_e_addr ));
    reg [NEw-1 : 0] ProNoC_id;
    generate 
        if (PITON_NEw < NEw) begin 
            always @ (*) begin 
                ProNoC_id =0;
                ProNoC_id [PITON_NEw-1 : 0] = piton_id;
            end
        end else begin 
            always @ (*) begin                 
                ProNoC_id =0;
                ProNoC_id  = piton_id [ NEw-1 : 0];
            end
        end
    endgenerate 
    endp_addr_encoder #( .TOPOLOGY(TOPOLOGY), .T1(T1), .T2(T2), .T3(T3), .EAw(EAw),  .NE(NE)) 
        encode2 ( .id(ProNoC_id), .code( pronoc_endp_addr1 ));
    // The address2 is generated for pronoc in OP and its not coded based on OP so no need to convert it.
    // It is indicated when msb of fbit is one  
    wire   [`NOC_X_WIDTH + `NOC_Y_WIDTH-1 : 0]   input_merged = {piton_coreid_y_i ,    piton_coreid_x_i};
    assign pronoc_endp_addr2 = input_merged [EAw-1 : 0];
    assign pronoc_endp_addr  = (piton_fbits_i[3]) ? pronoc_endp_addr2 : pronoc_endp_addr1;
    localparam [NEw-1 : 0] CHIP_SET_ID = T1*T2*T3+2*T1; // endp connected  of west port of router 0-0
    endp_addr_encoder #( .TOPOLOGY(TOPOLOGY), .T1(T1), .T2(T2), .T3(T3), .EAw(EAw),  .NE(NE)) 
        encode3 ( .id(CHIP_SET_ID), .code( chipset_endp_addr ));
    assign pronoc_endp_addr_o =  (piton_chipid_i == default_chipid_i ) ? pronoc_endp_addr : chipset_endp_addr;
    always @ (*) begin 
        piton_end_addr_coded_o = {ADDR_CODED{1'b0}};
        piton_end_addr_coded_o [Yw+Xw-1 : 0] =   {piton_coreid_y_i[Yw-1 : 0],  piton_coreid_x_i[Xw-1 : 0]};
        if(piton_chipid_i == 8192 ) begin 
            piton_end_addr_coded_o[ADDR_CODED-1]=1'b1;
        end// TODO need to know how chip id coded from zero to max or from 8192 to zero
    end
endmodule



module piton_to_pronoc_endp_addr_converter_same_topology 
#(
    parameter CHIP_SET_PORT = 3,
    parameter NOC_ID=0
)(
    default_chipid_i,
    piton_chipid_i,
    piton_coreid_x_i,
    piton_coreid_y_i,
    piton_fbits_i,
    pronoc_endp_addr_o,
    piton_end_addr_coded_o
);

    `NOC_CONF
    
    localparam  
        PRESERVED_DATw = (`MSG_LENGTH_WIDTH + `MSG_TYPE_WIDTH + `MSG_MSHRID_WIDTH + `MSG_OPTIONS_1_WIDTH ),
        HEAD_DATw      = (64-MSB_BE-1),
        ADDR_CODED     = (HEAD_DATw - PRESERVED_DATw);
    input  [`NOC_CHIPID_WIDTH-1:0]  default_chipid_i;
    input  [`NOC_CHIPID_WIDTH-1:0]  piton_chipid_i;
    input  [`NOC_X_WIDTH-1:0]       piton_coreid_x_i;
    input  [`NOC_Y_WIDTH-1:0]       piton_coreid_y_i;
    input  [`MSG_SRC_FBITS_WIDTH-1:0]  piton_fbits_i;
    
    output reg [EAw-1 : 0] pronoc_endp_addr_o;
    output reg    [ADDR_CODED-1 : 0] piton_end_addr_coded_o;
    
    localparam [3:0] 
        FBIT_NONE    =4'b0000,
        FBIT_W    =4'b0010,
        FBIT_S    =4'b0011,
        FBIT_E    =4'b0100,
        FBIT_N    =4'b0101;
    localparam        
        Xw = log2(NX),    // number of node in x axis
        Yw = log2(NY);    // number of node in y axis
    
    wire [EAw-Yw-Xw-1 : 0] edge_port;
        assign edge_port = 
            (piton_fbits_i [3:0] == FBIT_NONE) ? LOCAL:
            (piton_fbits_i [3:0] == FBIT_W   ) ? WEST:
            (piton_fbits_i [3:0] == FBIT_S   ) ? SOUTH:
            (piton_fbits_i [3:0] == FBIT_E   ) ? EAST: NORTH;
    
    //coded for FMESH topology
    generate     
    if(TOPOLOGY == "FMESH") begin 
        always @ (*) begin 
            pronoc_endp_addr_o = {EAw{1'b0}};
            if(piton_chipid_i == default_chipid_i ) begin 
                pronoc_endp_addr_o [Yw+Xw-1 : 0] =  {piton_coreid_y_i[Yw-1 : 0],  piton_coreid_x_i[Xw-1 : 0]};
                `ifdef PITON_EXTRA_MEMS
                pronoc_endp_addr_o [EAw-1 : Yw+Xw] = edge_port ;
                `endif
            end else begin //send it to next chip
                pronoc_endp_addr_o [EAw-1 : Yw+Xw] =  CHIP_SET_PORT;  // router 0,0 west port; 
            end
        end    
    end else begin //"mesh" 
        always @ (*) begin 
            pronoc_endp_addr_o = {EAw{1'b0}};
            pronoc_endp_addr_o [Yw+Xw-1 : 0] =  {piton_coreid_y_i[Yw-1 : 0],  piton_coreid_x_i[Xw-1 : 0]};            
        end    
    end
    endgenerate
    
    always @ (*) begin 
        piton_end_addr_coded_o = {ADDR_CODED{1'b0}};
        piton_end_addr_coded_o [Yw+Xw-1 : 0] =   {piton_coreid_y_i[Yw-1 : 0],  piton_coreid_x_i[Xw-1 : 0]};
        if(piton_chipid_i == 8192 ) begin 
            piton_end_addr_coded_o[ADDR_CODED-1]=1'b1;
        end// TODO need to know how chip id coded from zero to max or from 8192 to zero
    end    
endmodule    


module pronoc_to_piton_endp_addr_converter #(
    parameter NOC_ID=0
)(
    piton_end_addr_coded_i,    
    piton_chipid_o,
    piton_coreid_x_o,
    piton_coreid_y_o
);
    `NOC_CONF
    
    //coded for FMESH topology
    localparam    
        Xw = log2(NX),    // number of node in x axis
        Yw = log2(NY);    // number of node in y axis
    localparam  
        PRESERVED_DATw = (`MSG_LENGTH_WIDTH + `MSG_TYPE_WIDTH + `MSG_MSHRID_WIDTH + `MSG_OPTIONS_1_WIDTH ),
        HEAD_DATw      = (64-MSB_BE-1),
        ADDR_CODED     = (HEAD_DATw - PRESERVED_DATw);
    
output  [`NOC_CHIPID_WIDTH-1:0]  piton_chipid_o;
output  reg [`NOC_X_WIDTH-1:0]   piton_coreid_x_o;
output  reg [`NOC_Y_WIDTH-1:0]   piton_coreid_y_o;
input   [ADDR_CODED-1 : 0] piton_end_addr_coded_i;
    
    always @(*)begin 
        piton_coreid_x_o = {`MSG_DST_X_WIDTH{1'b0}}; 
        piton_coreid_y_o = {`MSG_DST_Y_WIDTH{1'b0}}; 
        {piton_coreid_y_o[Yw-1 : 0],  piton_coreid_x_o[Xw-1 : 0]}=piton_end_addr_coded_i [Yw+Xw-1 : 0];
    end
    //TODO regen chip ID 
    assign piton_chipid_o = (piton_end_addr_coded_i[ADDR_CODED-1]==1'b1)? 8192 : 0;
endmodule



module piton_to_pronoc_wrapper  #(
    parameter NOC_ID=0,
    parameter TILE_NUM =0,
    parameter CHIP_SET_PORT = 3,
    parameter FLATID_WIDTH=8
)(
    default_chipid,  default_coreid_x, default_coreid_y, flat_tileid,    
    reset, clk,
    dataIn, validIn, yummyIn,
    current_r_addr_i,
    chan_out
);    
    
    `NOC_CONF
    localparam  
        PRESERVED_DATw = (`MSG_LENGTH_WIDTH + `MSG_TYPE_WIDTH + `MSG_MSHRID_WIDTH + `MSG_OPTIONS_1_WIDTH ),
        HEAD_DATw      = (64-MSB_BE-1),
        ADDR_CODED     = (HEAD_DATw - PRESERVED_DATw);
    
    //piton 
    input  [`NOC_CHIPID_WIDTH-1:0]  default_chipid;
    input  [`NOC_X_WIDTH-1:0]       default_coreid_x;
    input  [`NOC_Y_WIDTH-1:0]       default_coreid_y;
    input  [FLATID_WIDTH-1:0] flat_tileid;
    input [Fpay-1:0]         dataIn;
    input                               validIn;
    input                               yummyIn;
    
    //pronoc
    input [RAw-1 : 0] current_r_addr_i;
    output  smartflit_chanel_t chan_out; 
    input reset,clk;
    
    wire [`MSG_DST_CHIPID_WIDTH-1   :0] dest_chipid = dataIn [ `MSG_DST_CHIPID];
    wire [`MSG_DST_X_WIDTH-1        :0] dest_x      = dataIn [ `MSG_DST_X];
    wire [`MSG_DST_Y_WIDTH-1        :0] dest_y      = dataIn [ `MSG_DST_Y];
    wire [`MSG_DST_FBITS_WIDTH-1    :0] dest_fbits  = dataIn [ `MSG_DST_FBITS];
    wire [`MSG_LENGTH_WIDTH-1       :0] length      = dataIn [ `MSG_LENGTH ];
    wire [`MSG_TYPE_WIDTH-1         :0] msg_type    = dataIn [ `MSG_TYPE ]; 
    wire [`MSG_MSHRID_WIDTH-1       :0] mshrid      = dataIn [ `MSG_MSHRID ];
    wire [`MSG_OPTIONS_1_WIDTH-1    :0] option1     = dataIn [ `MSG_OPTIONS_1];
    
    wire tail,head;
    tail_hdr_detect #(
        .FLIT_WIDTH(Fpay)
    )piton_hdr(
        .reset(reset),
        .clk(clk),
        .flit_in(dataIn),
        .valid(validIn),
        .ready(1'b1),
        .is_tail(tail),
        .is_header(head)
    );    
    
    wire [EAw-1 : 0] src_e_addr, dest_e_addr;
    wire [DSTPw-1 : 0] destport;
    wire [ADDR_CODED-1 : 0] dest_coded;
    
    piton_to_pronoc_endp_addr_converter #(
        .NOC_ID(NOC_ID),
        .CHIP_SET_PORT(CHIP_SET_PORT)
        ) src_conv (
        .default_chipid_i  (default_chipid),
        .piton_chipid_i    (default_chipid),
        .piton_coreid_x_i  (default_coreid_x),
        .piton_coreid_y_i  (default_coreid_y),
        .piton_fbits_i     (4'd0),
            
        .pronoc_endp_addr_o (src_e_addr),
        .piton_end_addr_coded_o()
        
    );    
    
    piton_to_pronoc_endp_addr_converter  #(
        .NOC_ID(NOC_ID)
    )dst_conv (
        .default_chipid_i  (default_chipid),
        .piton_chipid_i    (dest_chipid),
        .piton_coreid_x_i  (dest_x),
        .piton_coreid_y_i  (dest_y),
        .piton_fbits_i     (dest_fbits),
        .pronoc_endp_addr_o (dest_e_addr),
        .piton_end_addr_coded_o(dest_coded)
        
    );     
    
    conventional_routing #(
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),
        .ROUTE_TYPE(ROUTE_TYPE),
        .T1(T1),
        .T2(T2),
        .T3(T3),
        .RAw(RAw),
        .EAw(EAw),
        .DAw(DAw),
        .DSTPw(DSTPw),
        .LOCATED_IN_NI(1)
    ) routing_module (
        .reset(reset),
        .clk(clk),
        .current_r_addr(current_r_addr_i),
        .dest_e_addr(dest_e_addr),
        .src_e_addr(src_e_addr),
        .destport(destport)
    );
    
    //endp_addr_decoder  #( .TOPOLOGY(TOPOLOGY), .T1(T1), .T2(T2), .T3(T3), .EAw(EAw),  .NE(NE)) decod1 ( .id(TILE_NUM), .code(current_e_addr));
    localparam DATA_w = HEAD_DATw + Fpay - 64; 
    wire [DATA_w-1 : 0] head_data;
    generate 
        if(Fpay == 64) begin :F64
            assign head_data=  {dest_coded ,length, msg_type,  mshrid,option1}; 
        end else begin : FL 
            assign head_data=  {dataIn[Fpay -1  : 64],dest_coded ,length, msg_type,  mshrid,option1}; 
        end
    endgenerate
    
    wire [Fw-1 : 0] header_flit;
    reg [WEIGHTw-1 : 0] win;
    always @(*) begin 
        win={WEIGHTw{1'b0}};
        win[0]=1'b1;
    end    
    
    header_flit_generator    #(
        .NOC_ID(NOC_ID),
        .DATA_w(DATA_w) // header flit can carry Optional data. The data will be placed after control data.  Fpay >= DATA_w + CTRL_BITS_w  
    )head_gen(
        .flit_out(header_flit),    
        .src_e_addr_in(src_e_addr),
        .dest_e_addr_in(dest_e_addr),
        .destport_in(destport),
        .class_in(1'b0),
        .weight_in(win), 
        .vc_num_in(1'b1),
        .be_in(1'b0),
        .data_in(head_data)    
    );
    
    assign chan_out.ctrl_chanel.credit_init_val = 4;
    assign chan_out.flit_chanel.flit.hdr_flag =head;
    assign chan_out.flit_chanel.flit.tail_flag=tail;
    assign chan_out.flit_chanel.flit.vc=1'b1;
    assign chan_out.flit_chanel.flit_wr=validIn;
    assign chan_out.flit_chanel.credit=yummyIn;
    assign chan_out.flit_chanel.flit.payload = (head)? header_flit[Fpay-1 : 0] : dataIn;
    assign chan_out.smart_chanel = {SMART_CHANEL_w{1'b0}};
    assign chan_out.flit_chanel.congestion = {CONGw{1'b0}};
    /*
    always @ (posedge clk) begin 
        if(validIn==1'b1 && flit_type==    HEADER)begin 
            $display("%t***Tile %d ***NoC %d************payload length =%d*************************",$time,TILE_NUM,NOC_ID,length);
            $display("%t*** src (c=%d,x=%d,y=%d) sends to dst (c=%d,x=%d,y=%d chan_out=%x)",$time,
                    default_chipid, default_coreid_x, default_coreid_y, dest_chipid,dest_x,dest_y,chan_out);
//$finish;
        end
    end
    */
    /*
    //synthesis translate_off
    reg [7: 0] yy;
    initial begin //make sure address decoding match between ProNoC and Openpiton 
        #100
        yy = (TILE_NUM / `X_TILES )%`Y_TILES ;
        if((default_coreid_y != yy ) || 
        (default_coreid_x != (TILE_NUM % `X_TILES ))) begin 
        $display ("ERROR: Address missmatch! ");
        $finish;
        end        
    end
    //synthesis translate_on
    */
endmodule


/********************************
 *         pronoc_to_piton_wrapper  
 * ***************************/
module pronoc_to_piton_wrapper #(
    parameter NOC_ID=0,
    parameter PORT_NUM=0,
    parameter TILE_NUM =0,
    parameter FLATID_WIDTH=8
)(
    default_chipid,  default_coreid_x, default_coreid_y, flat_tileid,    
    reset, clk,
    dataOut, validOut, yummyOut,
    current_r_addr_o,
    chan_in
);    
    `NOC_CONF
    localparam  
        PRESERVED_DATw = (`MSG_LENGTH_WIDTH + `MSG_TYPE_WIDTH + `MSG_MSHRID_WIDTH + `MSG_OPTIONS_1_WIDTH ),
        HEAD_DATw      = (64-MSB_BE-1),
        ADDR_CODED     = (HEAD_DATw - PRESERVED_DATw);
    //piton out
    input  [`NOC_CHIPID_WIDTH-1:0]  default_chipid;
    input  [`NOC_X_WIDTH-1:0]       default_coreid_x;
    input  [`NOC_Y_WIDTH-1:0]       default_coreid_y;
    input  [FLATID_WIDTH-1:0] flat_tileid;
    output [Fpay-1:0]        dataOut;
    output                              validOut;
    output                              yummyOut;
    output [RAw-1 : 0] current_r_addr_o;
    //pronoc in
    input  smartflit_chanel_t chan_in; 
    input reset,clk;
    
    assign current_r_addr_o = chan_in.ctrl_chanel.router_addr;
    
    localparam        
        Xw = log2(NX),    // number of node in x axis
        Yw = log2(NY);    // number of node in y axis
    
    enum bit [1:0] {HEADER, BODY,TAIL} flit_type,flit_type_next;
    localparam DATA_w = HEAD_DATw + Fpay - 64; 
    hdr_flit_t hdr_flit;
    wire [DATA_w-1 : 0] head_dat;
    //extract ProNoC header flit data
    header_flit_info #(
        .NOC_ID(NOC_ID),
        .DATA_w(DATA_w)
    )extract(
        .flit(chan_in.flit_chanel.flit),
        .hdr_flit(hdr_flit),        
        .data_o(head_dat)    
    );
    
    wire [Fpay-1:0] header_flit;
    wire [`MSG_DST_CHIPID_WIDTH-1   :0] dest_chipid;
    reg  [`MSG_DST_X_WIDTH-1        :0] dest_x     ;
    reg  [`MSG_DST_Y_WIDTH-1        :0] dest_y     ;
    wire [`MSG_DST_FBITS_WIDTH-1    :0] dest_fbits ;
    wire [`MSG_LENGTH_WIDTH-1       :0] length     ;
    wire [`MSG_TYPE_WIDTH-1         :0] msg_type   ;
    wire [`MSG_MSHRID_WIDTH-1       :0] mshrid     ;
    wire [`MSG_OPTIONS_1_WIDTH-1    :0] option1    ;
    wire [ADDR_CODED-1 : 0] dest_coded;
    
    assign {dest_coded, length, msg_type, mshrid, option1}  =  head_dat [HEAD_DATw-1 : 0]; 
    pronoc_to_piton_endp_addr_converter#(
        .NOC_ID(NOC_ID)
        )addr_conv ( 
        .piton_end_addr_coded_i(dest_coded),        
        .piton_chipid_o (dest_chipid),
        .piton_coreid_x_o(dest_x),
        .piton_coreid_y_o(dest_y)    
    );
    wire [MAX_P-1:0] destport_one_hot;
    //    FBITS coding
    localparam [3: 0] 
        FBITS_WEST         =  4'b0010, 
        FBITS_SOUTH      =  4'b0011,   
        FBITS_EAST       =  4'b0100,   
        FBITS_NORTH      =  4'b0101,   
        FBITS_PROCESSOR  =  4'b0000;  
    /*    
        ProNoC destination port order num
        LOCAL   =   0
        EAST    =   1
        NORTH   =   2 
        WEST    =   3
        SOUTH   =   4         
    */    
        
    //assign dest_fbits =        (PORT_NUM==0) ? 4'b0000:4'b0010;//offchip    
    
    /*
    always @(posedge clk) begin
        if(validOut) begin 
            $display("********************************************destport_one_hot=%b; dest_fbits=%b",destport_one_hot,dest_fbits);
            $finish;
        end
    end
    */
    assign dest_fbits = 
        (destport_one_hot [LOCAL]) ? FBITS_PROCESSOR:
        (destport_one_hot [EAST ]) ? FBITS_EAST:
        (destport_one_hot [NORTH]) ? FBITS_NORTH:
        (destport_one_hot [WEST ]) ? FBITS_WEST:
        (destport_one_hot [SOUTH ]) ? FBITS_SOUTH: FBITS_PROCESSOR;
    
    wire [DSTPw-1 : 0] dstp_encoded = hdr_flit.destport;
    localparam 
        ELw = log2(T3),
        Pw  = log2(MAX_P),
        PLw = (TOPOLOGY == "FMESH") ? Pw : ELw;
    wire [PLw-1 : 0] endp_p_in;
    generate
    if(TOPOLOGY == "FMESH") begin : fmesh
        fmesh_endp_addr_decode #(
            .T1(T1),
            .T2(T2),
            .T3(T3),
            .EAw(EAw)
        ) endp_addr_decode  (
            .e_addr(hdr_flit.dest_e_addr),
            .ex(),
            .ey(),
            .ep(endp_p_in),
            .valid()
        );
    end else begin : mesh
        mesh_tori_endp_addr_decode #(
            .TOPOLOGY("MESH"),
            .T1(T1),
            .T2(T2),
            .T3(T3),
            .EAw(EAw)
        )  endp_addr_decode (
            .e_addr(hdr_flit.dest_e_addr),
            .ex( ),
            .ey( ),
            .el(endp_p_in),
            .valid( )
        );
    end
    endgenerate
    destp_generator #(
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),
        .ROUTE_TYPE(ROUTE_TYPE),
        .T1(T1),
        .NL(T3),
        .P(MAX_P),
        .PLw(PLw),
        .DSTPw(DSTPw),        
        .SELF_LOOP_EN (SELF_LOOP_EN),
        .SW_LOC(PORT_NUM)
    ) decoder (
        .destport_one_hot (destport_one_hot),
        .dest_port_encoded(dstp_encoded),             
        .dest_port_out(),   
        .endp_localp_num(endp_p_in),
        .swap_port_presel(),
        .port_pre_sel(),
        .odd_column(1'b0)
    );
    
    assign header_flit [ `MSG_DST_CHIPID] = dest_chipid; 
    assign header_flit [ `MSG_DST_X]      = dest_x; 
    assign header_flit [ `MSG_DST_Y]      = dest_y; 
    assign header_flit [ `MSG_DST_FBITS]  = dest_fbits; 
    assign header_flit [ `MSG_LENGTH ]    = length; 
    assign header_flit [ `MSG_TYPE ]      = msg_type; 
    assign header_flit [ `MSG_MSHRID ]    = mshrid; 
    assign header_flit [ `MSG_OPTIONS_1]  = option1; 
    
    generate 
    if(Fpay > 64) begin :R_           
        assign  header_flit [Fpay - 1 : 64] =  head_dat[Fpay + HEAD_DATw -65 :HEAD_DATw]; 
    end
    endgenerate
    
    wire head = chan_in.flit_chanel.flit.hdr_flag;
    wire tail = chan_in.flit_chanel.flit.tail_flag;
    
    assign validOut = chan_in.flit_chanel.flit_wr;
    assign yummyOut = chan_in.flit_chanel.credit;
    assign dataOut  = (head)? header_flit[Fpay-1 : 0] : chan_in.flit_chanel.flit.payload;
endmodule


/*********************
 *   pack noc_top ports 
 * ******************/
module  noc_top_packed #(
    parameter NOC_ID=0
)(
    reset,
    clk,    
    chan_in_all,
    chan_out_all  
);
    `NOC_CONF
    localparam  
        PRESERVED_DATw = (`MSG_LENGTH_WIDTH + `MSG_TYPE_WIDTH + `MSG_MSHRID_WIDTH + `MSG_OPTIONS_1_WIDTH ),
        HEAD_DATw      = (64-MSB_BE-1),
        ADDR_CODED     = (HEAD_DATw - PRESERVED_DATw);
    input   clk,reset;
    //local ports 
    input   smartflit_chanel_t [NE-1 : 0] chan_in_all  ;
    output  smartflit_chanel_t [NE-1 : 0] chan_out_all ;    
    smartflit_chanel_t chan_in_all_unpacked  [NE-1 : 0];
    smartflit_chanel_t chan_out_all_unpacked [NE-1 : 0];
    
    genvar i;
    generate
    for (i=0;i<NE;i++) begin: E_
        assign chan_in_all_unpacked[i]=chan_in_all[i];
        assign chan_out_all[i] = chan_out_all_unpacked[i];
    end//for
    endgenerate
    
    noc_top #(
        .NOC_ID(NOC_ID)
        )unpacked (
        .reset(reset),
        .clk(clk),    
        .chan_in_all(chan_in_all_unpacked),
        .chan_out_all(chan_out_all_unpacked)            
    );
    
    //synthesis translate_off
    initial begin 
        display_noc_parameters();         
    end     
    //synthesis translate_on
    
endmodule    


module ground_pronoc_end_port         
    #(
        parameter TILE_NUM=0,
        parameter NOC_ID=0
    )(
        clk,
        reset,
        chan_in,
        chan_out        
    );
    
    `NOC_CONF
    input  reset,clk;
    input   smartflit_chanel_t chan_in;
    output  smartflit_chanel_t    chan_out;
    assign chan_out = {SMARTFLIT_CHANEL_w{1'b0}};
    //synthesis translate_off
    always @(posedge clk) begin 
        if(chan_in.flit_chanel.flit_wr) begin
            $display("%t: ERROR: a flit has been recived in grounded NoC %d port %d:flit:%h",$time,NOC_ID,TILE_NUM,chan_in.flit_chanel.flit);
            $finish;
        end
    end
    //synthesis translate_on
endmodule




module pronoc_noc     
    #(
    parameter NOC_ID=0,
    parameter CHIP_SET_PORT=3,
    parameter FLATID_WIDTH=8
    )(
        dataIn_flatten,
        validIn,
        yummyIn,
        dataOut_flatten,
        validOut,
        yummyOut,
        default_chipid,
        default_coreid_x_flatten,
        default_coreid_y_flatten,
        flat_tileid_flatten,
        reset,
        clk
    );

    `NOC_CONF
    input clk,reset;
    input [Fpay*NE-1:0] dataIn_flatten;
    input [NE-1 : 0] validIn;
    input [NE-1 : 0] yummyIn;
    output [Fpay*NE-1:0] dataOut_flatten;
    output [NE-1 : 0] validOut;
    output [NE-1 : 0] yummyOut; 
    input  [`NOC_CHIPID_WIDTH-1:0]  default_chipid;
    input  [`NOC_X_WIDTH*NE-1:0]    default_coreid_x_flatten;
    input  [`NOC_Y_WIDTH*NE-1:0]    default_coreid_y_flatten;
    input  [FLATID_WIDTH*NE-1:0]    flat_tileid_flatten;
    
    wire [Fpay-1:0] dataIn [NE-1 : 0];
    wire [Fpay-1:0] dataOut [NE-1 : 0];    
    wire [`NOC_X_WIDTH-1:0]  default_coreid_x[NE-1 : 0];
    wire [`NOC_Y_WIDTH-1:0]  default_coreid_y[NE-1 : 0];
    wire [FLATID_WIDTH-1:0]  flat_tileid[NE-1 : 0];
    smartflit_chanel_t pronoc_chan_in  [NE-1 : 0];
    smartflit_chanel_t pronoc_chan_out [NE-1 : 0];
    wire [RAw-1 : 0] current_r_addr  [NE-1 : 0];    
    
    genvar i;
    generate
    for (i=0;i<NE;i++) begin: E_
        
        assign dataIn [i] = dataIn_flatten [(i+1)* Fpay -1 :  i * Fpay];
        assign dataOut_flatten [(i+1)* Fpay -1 :  i * Fpay] = dataOut [i];
        assign default_coreid_x[i]=default_coreid_x_flatten[(i+1)*`NOC_X_WIDTH-1 : i*`NOC_X_WIDTH];
        assign default_coreid_y[i]=default_coreid_y_flatten[(i+1)*`NOC_Y_WIDTH-1 : i*`NOC_Y_WIDTH];
        assign flat_tileid[i]=flat_tileid_flatten[(i+1)*FLATID_WIDTH-1 : i*FLATID_WIDTH];
        pronoc_to_piton_wrapper 
        #(
            .NOC_ID(NOC_ID),
            .PORT_NUM(0),
            .TILE_NUM(i),
            .FLATID_WIDTH(FLATID_WIDTH)
        )pr2pi (
            .default_chipid(default_chipid),
            .default_coreid_x(default_coreid_x[i]), 
            .default_coreid_y(default_coreid_y[i]),
            .flat_tileid(flat_tileid[i]),    
            .reset(reset),
            .clk(clk),
            .dataOut(dataOut[i]),
            .validOut(validOut[i]),
            .yummyOut(yummyOut[i]),
            .current_r_addr_o(current_r_addr[i]),
            .chan_in(pronoc_chan_out[i])
        );    
        
        piton_to_pronoc_wrapper      
        #(
            .NOC_ID(NOC_ID),
            .TILE_NUM(i),
            .CHIP_SET_PORT(CHIP_SET_PORT),
            .FLATID_WIDTH(FLATID_WIDTH)
        )pi2pr (
            .default_chipid (default_chipid),
            .default_coreid_x(default_coreid_x[i]),
            .default_coreid_y(default_coreid_y[i]),
            .flat_tileid(flat_tileid[i]),    
            .reset(reset),
            .clk(clk),
            .dataIn(dataIn[i]),
            .validIn(validIn[i]),
            .yummyIn(yummyIn[i]),
            .current_r_addr_i(current_r_addr[i]),
            .chan_out(pronoc_chan_in[i])
        );    
    end//for
    endgenerate
    
    noc_top #(
        .NOC_ID(NOC_ID)
        )noc (
        .reset(reset),
        .clk(clk),    
        .chan_in_all (pronoc_chan_in ),
        .chan_out_all(pronoc_chan_out),
        .router_event()            
    );
endmodule
