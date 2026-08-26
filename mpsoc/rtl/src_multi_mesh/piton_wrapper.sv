/**************************************************************
 * File        : piton_wrapper.sv
 * Description : Contains the necessary modules for adapting
 *               Depth-First ProNoC with OpenPiton's Endpoints
 *
 * Authors     :  Davy Million, Alireza Monemi
 * Date        :  2025
 **************************************************************/
`include "define.tmp.h"
`include "jtag.vh"
`include "pronoc_def.v"


// The following modules allows the conversion of an OpenPiton Flit into a
// ProNoC Depth-First Flit, and the other way around.
//
// (A) Valid Flit, Additionnal Flags and Backpressure
// The OpenPiton valid flit signal is plugged directly into the ProNoC flit
// write signal.
//
// To keep track of the number of flits in a packet, OpenPiton has a dedicated
// LENGTH attributes in the header flit. This is not the case of ProNoC, which
// rely on explicit signals, which are asserted for the head and tail flits.
// The module piton_tail_hdr_detect (shared with the FMesh OpenPiton wrapper)
// is used to convert these two ways of managing the number of flits.
//
// As Depth-First relies on two VCs, and OpenPiton's endpoints only support a
// single source of credits, we modified the routing algorithm to only use VC0
// (Z-) for packet injection, and the other one (Z+) for packet reception,
// leveraging the fact that the algorithm supports passing from Z- to Z+ (but
// not the other way around). Switching between these two VCs is necessary to
// support all "Multi-Mesh" routing paths, because some X-Y/Z turns are
// disabled for both VC to garantee deadlock-freeness. Hence, the OpenPiton
// backpressure signal (yummy) is connected directly to the Z- ProNoC credit
// signal.
//
// (B) Data Payload
// The conversion is almost straightforward: the ProNoC data payload is the
// same as the OpenPiton data payload, except when the OpenPiton flit present
// the 1st 64-bit Header word (which is the case for any 1st Header Flit of an
// OpenPiton packet).
//
// For this corner case, the conversion consists of the following:
//  OpenPiton
// Fpay-1  ...  64-bit                      30-bit                           0
//   |____________|___________________________|______________________________|
//   |            |                           |                              |
//   |    ...     | CHIPID, XPOS, YPOS, FBITS | LENGTH, TYPE, MSHR, OPTIONS1 |
//   |____________|___________________________|______________________________|
//   |            |                           |<-------PRESERVED_DATw------->|
//   | Word 2...n |            (OpenPiton Header Flit Word 1)                |
//   |_____  _____|_________________________________________  _______________|
//         ||                                               ||
//         ||                      _________________________||
//         ||  MSB_BE + 1 +       ||
// FPAYw-1 ||  PRESERVED_DATw     ||   pronoc_pkg::MSB_BE+1                  0
//   |_____VV_____|_______________VV_____________|___________________________|
//   |            |                              | Depth-First ProNoC Header |
//   |    ...     | LENGTH, TYPE, MSHR, OPTIONS1 |    DST Addr | SRC Addr    |
//   |____________|______________________________|___________________________|
//   |<-----------|------DATA_w----------------->|                           |
//   |                   ProNoC Header Flit Payload                          |
//   |_______________________________________________________________________|
//   ProNoC
//
// Where:
// (*) Fpay, the size of the OpenPiton data flit
// --> Fpay NoC1: {64, 128, 256, 512}
// --> Fpay NoC2/3: {64, 128, 256, 512, 576, 704}
//
// (*) FPAYw, the size of the ProNoC data payload
//
// The size of FPAYw depends on the size of the Depth-First (DP) DST/SRC
// address fields. These fields are computed based on the original CHIPID,
// XPOS, YPOS and FBITS values. The width of the DP DST/SRC addresses can vary
// and depend primarily on the values of the CLUSTER_IDw, CLUSTER_Xw and
// CLUSTER_Yw parameters, which themselves depends on the max X/Y dimensions
// among all chips and the number of chips in the system.
// FPAYw will be larger than Fpay if:
// ==> size(DP DST Addr) + size(DP SRC Addr) > size(CHIPID, XPOS, YPOS, FBITS)
// which is likely the case for a large system.
//
// (C) Control Channels
// ProNoC has dedicated control channels to support different buffer depths
// (credit_init_val) and number of VCs between routers (hetero_ovc_presence).
// The credit_init_val signal is initialized with the same value as the buffer
// size in the OpenPiton endpoints. The hetero_ovc_presence is used to check if
// the Z+ VC exists on the interposer chip, and use Z- as a fallback VC for
// packet reception otherwise.


module piton_to_pronoc_multimesh_endp_src_addr_converter
    import pronoc_pkg::*;
(
    input  logic [`NOC_CHIPID_WIDTH-1:0] piton_chipid_i,
    input  logic [`NOC_X_WIDTH-1:0]      piton_coreid_x_i,
    input  logic [`NOC_Y_WIDTH-1:0]      piton_coreid_y_i,
    output logic [EAw-1:0]               pronoc_endp_src_addr_o
);
    // Encode endpoint source address
    assign pronoc_endp_src_addr_o = {
        piton_chipid_i[CLUSTER_IDw-1:0],
        {CLUSTER_Zw{1'b0}},
        piton_coreid_y_i[CLUSTER_Yw-1:0],
        piton_coreid_x_i[CLUSTER_Xw-1:0]
    };
endmodule


module piton_to_pronoc_multimesh_endp_dst_addr_converter
    import pronoc_pkg::*;
(
    input  logic [`NOC_CHIPID_WIDTH-1:0]    piton_chipid_i,
    input  logic [`NOC_X_WIDTH-1:0]         piton_coreid_x_i,
    input  logic [`NOC_Y_WIDTH-1:0]         piton_coreid_y_i,
    input  logic [`MSG_DST_FBITS_WIDTH-1:0] piton_fbits_i,
    output logic [DAw-1:0]                  pronoc_endp_dst_addr_o
);
    // Destination FBITS
    logic [DSTPw-1:0] pronoc_dest_fbits;
    // Global destination address
    logic [RAw-1:0] global_dst_i;

    assign pronoc_dest_fbits =
        (piton_fbits_i == `NOC_FBITS_NORTH) ? NORTH :
        (piton_fbits_i == `NOC_FBITS_WEST ) ? WEST  :
        (piton_fbits_i == `NOC_FBITS_SOUTH) ? SOUTH :
        (piton_fbits_i == `NOC_FBITS_EAST ) ? EAST  : LOCAL;

    assign global_dst_i = {piton_chipid_i[CLUSTER_IDw-1:0],
                           {CLUSTER_Zw{1'b0}},
                           piton_coreid_y_i[CLUSTER_Yw-1:0],
                           piton_coreid_x_i[CLUSTER_Xw-1:0]};

    // Endpoint destination address encoding
    assign pronoc_endp_dst_addr_o = {
        1'b0, // local_routing_en
        1'b0, // next_chip_vdir
        pronoc_dest_fbits,
        {RAw{1'b0}}, // local_dst
        global_dst_i
    };
endmodule


module pronoc_to_piton_multimesh_endp_addr_converter
    import pronoc_pkg::*;
(
    input  logic [DAw-1:0] piton_endp_dst_addr_i,
    output logic [`NOC_CHIPID_WIDTH-1:0] piton_chipid_o,
    output logic [`NOC_X_WIDTH-1:0] piton_coreid_x_o,
    output logic [`NOC_Y_WIDTH-1:0] piton_coreid_y_o,
    output logic [`MSG_DST_FBITS_WIDTH-1:0] piton_fbits_o
);
    // Starting Position of the CLUSTER_ID field
    localparam CLUSTER_ID_IDX = CLUSTER_Xw + CLUSTER_Yw + CLUSTER_Zw;

    // Destination FBITS encoded as a ProNoC port
    logic [DSTPw-1:0] piton_dest_fbits_enc;

    always_comb begin
        piton_coreid_x_o = {`MSG_DST_X_WIDTH{1'b0}};
        piton_coreid_y_o = {`MSG_DST_Y_WIDTH{1'b0}};
        piton_chipid_o   = {`NOC_CHIPID_WIDTH{1'b0}};
        piton_dest_fbits_enc = {DSTPw{1'b0}};

        // Extract x/y from the global destination
        {piton_coreid_y_o[CLUSTER_Yw-1:0],
         piton_coreid_x_o[CLUSTER_Xw-1:0]} =
         piton_endp_dst_addr_i[CLUSTER_Yw + CLUSTER_Xw-1:0];

        piton_chipid_o = piton_endp_dst_addr_i[CLUSTER_ID_IDX +: CLUSTER_IDw];
        piton_dest_fbits_enc = piton_endp_dst_addr_i[2*RAw +: DSTPw];
    end

    // Decode FBITS into OpenPiton format
    assign piton_fbits_o =
        (piton_dest_fbits_enc == EAST ) ? `NOC_FBITS_EAST  :
        (piton_dest_fbits_enc == NORTH) ? `NOC_FBITS_NORTH :
        (piton_dest_fbits_enc == WEST ) ? `NOC_FBITS_WEST  :
        (piton_dest_fbits_enc == SOUTH) ? `NOC_FBITS_SOUTH :
        `NOC_FBITS_PROCESSOR;
endmodule


module piton_to_pronoc_multimesh_wrapper
    import pronoc_pkg::*;
#(
    parameter TILE_NUM = 0,
    parameter FLATID_WIDTH = 8,
    parameter Z_MINUS_VC_INJECTION = 1,
    parameter CONNECTED_TO_ENDP = 1
)(
    input  logic clk,
    input  logic reset,
    // OpenPiton
    input  logic [`NOC_CHIPID_WIDTH-1:0] default_chipid,
    input  logic [`NOC_X_WIDTH-1:0] default_coreid_x,
    input  logic [`NOC_Y_WIDTH-1:0] default_coreid_y,
    input  logic [FLATID_WIDTH-1:0] flat_tileid,
    input  logic [Fpay-1:0] dataIn,
    input  logic validIn,
    input  logic yummyIn,
    // ProNoC
    input  logic [RAw-1:0] current_r_addr_i,
    input  logic [V-1:0] ovc_presence_i,
    output smartflit_chanel_t chan_out
);
    // Size of the OpenPiton header fields remaining in the ProNoC header
    localparam PRESERVED_DATw = (`MSG_LENGTH_WIDTH + `MSG_TYPE_WIDTH +
                                 `MSG_MSHRID_WIDTH + `MSG_OPTIONS_1_WIDTH);

    // NOTE: the OpenPiton NoC protocol contains some packet fields that are
    // not necessary for routing with ProNoC because they are either related to
    // the decoding of the packet, or to give necessary information to the
    // destination endpoint, so the destination can create a response. Also,
    // when the Piton NoC > 64-bit, the endpoint packs multiple 64-bit words
    // together in a single flit. If the message is a cache coherence request,
    // the header flit will contain the targeted address (and also details
    // about the source endpoint if Piton NoC > 128-bit), see Flit (2, 3) of
    // Table 1 in OpenPiton Microarchitecture Specification.
    // All these "non-necessary for routing" fields will be placed in the
    // ProNoC packet header, as additional payload data, so they can be
    // retrieved once the packet is arrived to the destination endpoint.
    // DATA_w is the size of the additionnal payload data.
    localparam DATA_w = Fpay - 64 + PRESERVED_DATw;

    logic [`MSG_DST_CHIPID_WIDTH-1:0] piton_dest_chipid;
    logic [`MSG_DST_X_WIDTH-1:0]      piton_dest_x;
    logic [`MSG_DST_Y_WIDTH-1:0]      piton_dest_y;
    logic [`MSG_DST_FBITS_WIDTH-1:0]  piton_dest_fbits;
    logic [`MSG_LENGTH_WIDTH-1:0]     piton_length;
    logic [`MSG_TYPE_WIDTH-1:0]       piton_msg_type;
    logic [`MSG_MSHRID_WIDTH-1:0]     piton_mshrid;
    logic [`MSG_OPTIONS_1_WIDTH-1:0]  piton_option1;

    logic [EAw-1:0] pronoc_src_endp_addr;
    logic [DAw-1:0] pronoc_dest_endp_addr;
    logic [DATA_w-1:0] pronoc_hdr_data;

    logic piton_is_tail;
    logic piton_is_head;

    logic [Fw-1:0] pronoc_hdr_flit;
    logic [WEIGHTw-1:0] pronoc_win;
    logic [V-1:0] pronoc_vc_num_in;

    piton_tail_hdr_detect #(
        .FLIT_WIDTH(Fpay)
    ) piton_hdr(
        .clk(clk),
        .reset(reset),
        .length_in(dataIn[`MSG_LENGTH]),
        .valid(validIn),
        .ready(1'b1),
        .is_tail(piton_is_tail),
        .is_header(piton_is_head)
    );

    piton_to_pronoc_multimesh_endp_src_addr_converter src_conv(
        .piton_chipid_i(default_chipid),
        .piton_coreid_x_i(default_coreid_x),
        .piton_coreid_y_i(default_coreid_y),
        .pronoc_endp_src_addr_o(pronoc_src_endp_addr)
    );

    assign piton_dest_chipid = dataIn[`MSG_DST_CHIPID];
    assign piton_dest_x      = dataIn[`MSG_DST_X];
    assign piton_dest_y      = dataIn[`MSG_DST_Y];
    assign piton_dest_fbits  = dataIn[`MSG_DST_FBITS];
    assign piton_length      = dataIn[`MSG_LENGTH];
    assign piton_msg_type    = dataIn[`MSG_TYPE];
    assign piton_mshrid      = dataIn[`MSG_MSHRID];
    assign piton_option1     = dataIn[`MSG_OPTIONS_1];

    piton_to_pronoc_multimesh_endp_dst_addr_converter dst_conv(
        .piton_chipid_i(piton_dest_chipid),
        .piton_coreid_x_i(piton_dest_x),
        .piton_coreid_y_i(piton_dest_y),
        .piton_fbits_i(piton_dest_fbits),
        .pronoc_endp_dst_addr_o(pronoc_dest_endp_addr)
    );

    generate
    if (Fpay == 64) begin: F64
        assign pronoc_hdr_data = {piton_length, piton_msg_type, piton_mshrid,
                                  piton_option1};
    end else begin: FL
        assign pronoc_hdr_data = {dataIn[Fpay-1:64], piton_length,
                                  piton_msg_type, piton_mshrid, piton_option1};
    end
    endgenerate

    always_comb begin
        pronoc_win = {WEIGHTw{1'b0}};
        pronoc_win[0] = 1'b1;
    end

    generate
    if (Z_MINUS_VC_INJECTION) begin
        // Injection of the packet on Z-
        assign pronoc_vc_num_in = Z_MIN_VC;
    end else begin
        // Injection of the packet on Z+
        // This is used to reconstruct a packet to cross a vertical link,
        // between two NoC domains with different channel widths
        assign pronoc_vc_num_in = Z_PLUS_VC;
    end
    endgenerate

    header_flit_generator #(
        .DATA_w(DATA_w)
    ) pronoc_hdr_gen(
        .flit_out(pronoc_hdr_flit),
        .src_e_addr_in(pronoc_src_endp_addr),
        .dest_e_addr_in(pronoc_dest_endp_addr),
        // NOTE: we do not really care about the destport here as the router
        // will override it anyway
        .destport_in({DSTPw{1'b0}}),
        .class_in(1'b0),
        .weight_in(pronoc_win),
        .vc_num_in(pronoc_vc_num_in),
        .be_in(1'b0),
        .option_in({OPTIONw{1'b0}}),
        .data_in(pronoc_hdr_data)
    );

    // ProNoC Control Channels
    assign chan_out.ctrl_chanel.endp_port = CONNECTED_TO_ENDP;
    assign chan_out.ctrl_chanel.endp_addr =
        (CONNECTED_TO_ENDP) ? pronoc_src_endp_addr : '0;
    assign chan_out.ctrl_chanel.router_addr =
        (CONNECTED_TO_ENDP) ? pronoc_src_endp_addr : current_r_addr_i;
    // By default, our implementation of Depth-First uses Z+ to place a packet
    // in the destination router's ports. If this VC is not available (on the
    // interposer, Z- could be the only VC), use Z- in this case.
    assign chan_out.ctrl_chanel.credit_init_val =
        // Select Z+ if it exists, otherwise Z-
        ovc_presence_i[Z_PLUS_VC_IDX] ?
            Z_PLUS_VC[0] ? {{CRDTw{1'b0}}, pronoc_pkg::B} :
                           {pronoc_pkg::B, {CRDTw{1'b0}}}
            : Z_MIN_VC[0] ? {{CRDTw{1'b0}}, pronoc_pkg::B} :
                            {pronoc_pkg::B, {CRDTw{1'b0}}};
    assign chan_out.ctrl_chanel.credit_release_en   = '0;
    assign chan_out.ctrl_chanel.hetero_ovc_presence = ovc_presence_i;

    // ProNoC Flit Channels
    assign chan_out.flit_chanel.flit.hdr_flag  = piton_is_head;
    assign chan_out.flit_chanel.flit.tail_flag = piton_is_tail;
    assign chan_out.flit_chanel.flit.vc        = pronoc_vc_num_in;
    assign chan_out.flit_chanel.flit_wr        = validIn;
    // "Z+" credit, an endpoint consumed the flit (arrived to its destination)
    assign chan_out.flit_chanel.credit = ovc_presence_i[Z_PLUS_VC_IDX] ?
        Z_PLUS_VC & {yummyIn, yummyIn} : Z_MIN_VC & {yummyIn, yummyIn};
    assign chan_out.flit_chanel.flit.payload = (piton_is_head) ?
        pronoc_hdr_flit[FPAYw-1:0] : dataIn;
    assign chan_out.smart_chanel = {SMART_CHANEL_w{1'b0}};
    assign chan_out.flit_chanel.congestion = {CONGw{1'b0}};

`ifndef ASIC_SYNTH
`ifndef DISABLE_ALL_MONITORS
`ifndef MINIMAL_MONITORING
    // synthesis translate_off
    always @ (posedge clk) begin
        if (CONNECTED_TO_ENDP && validIn == 1'b1 && piton_is_head) begin
            $display("%t Pi2Pr * Chip %d/Tile %d * NoC %d * payload length %d",
                     $time, default_chipid, TILE_NUM, NOC_ID[1:0], piton_length);
            $display("%t *** src (c=%d,x=%d,y=%d) sends to dst (c=%d,x=%d,y=%d chan_out=%x)",
                     $time, default_chipid, default_coreid_x, default_coreid_y, piton_dest_chipid,
                     piton_dest_x, piton_dest_y, chan_out);
        end
    end
    // synthesis translate_on
`endif // MINIMAL_MONITORING
`endif // DISABLE_ALL_MONITORS
`endif // ASIC_SYNTH
endmodule


module pronoc_to_piton_multimesh_wrapper
    import pronoc_pkg::*;
#(
    parameter TILE_NUM = 0,
    parameter FLATID_WIDTH = 8,
    parameter CONNECTED_TO_ENDP = 1
)(
    input  logic clk,
    input  logic reset,
    // OpenPiton
    input  logic [`NOC_CHIPID_WIDTH-1:0] default_chipid,
    input  logic [`NOC_X_WIDTH-1:0] default_coreid_x,
    input  logic [`NOC_Y_WIDTH-1:0] default_coreid_y,
    input  logic [FLATID_WIDTH-1:0] flat_tileid,
    output logic [Fpay-1:0] dataOut,
    output logic validOut,
    output logic yummyOut,
    output logic [RAw-1:0] current_r_addr_o,
    // ProNoC
    input  smartflit_chanel_t chan_in,
    output multimesh_router_addr_t received_packet_src_addr_o,
    output logic [V-1:0] ovc_presence_o
);
    // Size of the OpenPiton header fields remaining in the ProNoC header
    localparam
        PRESERVED_DATw = (`MSG_LENGTH_WIDTH + `MSG_TYPE_WIDTH +
                          `MSG_MSHRID_WIDTH + `MSG_OPTIONS_1_WIDTH);
    // Size of the OpenPiton payload remaining in the ProNoC header flit
    localparam DATA_w = Fpay - 64 + PRESERVED_DATw;

    hdr_flit_t pronoc_hdr_flit;
    logic pronoc_is_hdr;
    logic [DATA_w-1:0] pronoc_hdr_data;

    logic [Fpay-1:0] piton_hdr_flit;
    // Source FBITS encoded as a ProNoC port
    logic [DSTPw-1:0] piton_src_fbits_enc;

    logic [`MSG_DST_CHIPID_WIDTH-1:0] piton_dest_chipid;
    logic [`MSG_DST_X_WIDTH-1:0]      piton_dest_x;
    logic [`MSG_DST_Y_WIDTH-1:0]      piton_dest_y;
    logic [`MSG_DST_FBITS_WIDTH-1:0]  piton_dest_fbits;
    logic [`MSG_LENGTH_WIDTH-1:0]     piton_length;
    logic [`MSG_TYPE_WIDTH-1:0]       piton_msg_type;
    logic [`MSG_MSHRID_WIDTH-1:0]     piton_mshrid;
    logic [`MSG_OPTIONS_1_WIDTH-1:0]  piton_option1;

    // Extract ProNoC header flit data
    header_flit_info #(
        .DATA_w(DATA_w)
    ) extract(
        .flit(chan_in.flit_chanel.flit),
        .hdr_flit(pronoc_hdr_flit),
        .option_o(),
        .data_o(pronoc_hdr_data)
    );

    pronoc_to_piton_multimesh_endp_addr_converter addr_conv(
        .piton_endp_dst_addr_i(pronoc_hdr_flit.dest_e_addr),
        .piton_chipid_o(piton_dest_chipid),
        .piton_coreid_x_o(piton_dest_x),
        .piton_coreid_y_o(piton_dest_y),
        .piton_fbits_o(piton_dest_fbits)
    );

    assign {piton_length, piton_msg_type, piton_mshrid, piton_option1} =
        pronoc_hdr_data[PRESERVED_DATw-1:0];

    assign piton_hdr_flit[`MSG_DST_CHIPID] = piton_dest_chipid;
    assign piton_hdr_flit[`MSG_DST_X]      = piton_dest_x;
    assign piton_hdr_flit[`MSG_DST_Y]      = piton_dest_y;
    assign piton_hdr_flit[`MSG_DST_FBITS]  = piton_dest_fbits;
    assign piton_hdr_flit[`MSG_LENGTH ]    = piton_length;
    assign piton_hdr_flit[`MSG_TYPE ]      = piton_msg_type;
    assign piton_hdr_flit[`MSG_MSHRID ]    = piton_mshrid;
    assign piton_hdr_flit[`MSG_OPTIONS_1]  = piton_option1;

    generate
    if (Fpay > 64) begin: R_
        assign piton_hdr_flit[Fpay-1:64] =
            pronoc_hdr_data[DATA_w-1:PRESERVED_DATw];
    end
    endgenerate

    assign validOut = chan_in.flit_chanel.flit_wr;
    // "Z-" credit, a flit was removed from the router's internal port
    assign yummyOut = chan_in.flit_chanel.credit[Z_MIN_VC_IDX];
    assign pronoc_is_hdr = chan_in.flit_chanel.flit.hdr_flag;
    assign dataOut  = (pronoc_is_hdr)? piton_hdr_flit[Fpay-1:0] :
                                       chan_in.flit_chanel.flit.payload;

    // Signals used by the pronoc_to_piton endpointer encoder
    assign current_r_addr_o = chan_in.ctrl_chanel.router_addr;
    assign {piton_src_fbits_enc, received_packet_src_addr_o}
        = pronoc_hdr_flit.src_e_addr;
    assign ovc_presence_o = chan_in.ctrl_chanel.hetero_ovc_presence;

`ifndef ASIC_SYNTH
`ifndef DISABLE_ALL_MONITORS
`ifndef MINIMAL_MONITORING
    // synthesis translate_off
    always @ (posedge clk) begin
        if (CONNECTED_TO_ENDP && validOut==1'b1 && pronoc_is_hdr) begin
            $display("%t Pr2Pi * Chip %d/Tile %d * NoC %d * payload length %d",
                     $time, default_chipid, TILE_NUM, NOC_ID[1:0], piton_length);
            $display("%t *** Received Packet Header (chan_out=%x) from src (c=%d,x=%d,y=%d)",
                     $time, dataOut, received_packet_src_addr_o.c, received_packet_src_addr_o.x,
                     received_packet_src_addr_o.y);
        end
    end
    // synthesis translate_on
`endif // MINIMAL_MONITORING
`endif // DISABLE_ALL_MONITORS
`endif // ASIC_SYNTH
endmodule


module pronoc_noc
    import pronoc_pkg::*;
#(
    parameter CHIP_ID = 0,
    // Inherited from the base wrapper.sv file, kept for consistency
    parameter CHIP_SET_PORT = 3,
    parameter FLATID_WIDTH  = `JTAG_FLATID_WIDTH,
    parameter CLUSTER_NX = 1,
    parameter CLUSTER_NY = 1,
    parameter CLUSTER_NZ = 1,
    parameter CLUSTER_ID_OFFSET = 0,
`ifndef PITON_EXTRA_MEMS
`ifdef PITON_PRONOC
    localparam NE = (CHIP_ID == 0) ? CLUSTER_NX * CLUSTER_NY * CLUSTER_NZ + 1 :
                     CLUSTER_NX * CLUSTER_NY * CLUSTER_NZ
`else // PITON_PRONOC
    localparam NE = CLUSTER_NX * CLUSTER_NY * CLUSTER_NZ
`endif // PITON_PRONOC
`else // PITON_EXTRA_MEMS
    // For OpenPiton, the total number of available endpoints is one endpoint
    // per tile + an endpoint on each edge of the 2D-Mesh to connect an MC and
    // the chipset (only for the north-western one)
    localparam NE = (CHIP_ID == 0) ? CLUSTER_NX * CLUSTER_NY * CLUSTER_NZ +
                                     CLUSTER_NX * 2 + CLUSTER_NY * 2 :
                     CLUSTER_NX * CLUSTER_NY * CLUSTER_NZ
`endif // PITON_EXTRA_MEMS
)(
    input  logic clk,
    input  logic reset,
    input  logic [Fpay*NE-1:0] dataIn_flatten,
    input  logic [NE-1:0] validIn,
    input  logic [NE-1:0] yummyIn,
    output logic [Fpay*NE-1:0] dataOut_flatten,
    output logic [NE-1:0] validOut,
    output logic [NE-1:0] yummyOut,
    input  logic [`NOC_X_WIDTH*NE-1:0] default_coreid_x_flatten,
    input  logic [`NOC_Y_WIDTH*NE-1:0] default_coreid_y_flatten,
    input  logic [FLATID_WIDTH*NE-1:0] flat_tileid_flatten
`ifdef PITON_MULTICHIP
    ,
    // NoC Vertical Links
    input  smartflit_chanel_t pronoc_inter_chip_in [CLUSTER_NX*CLUSTER_NY*2-1:0],
    output smartflit_chanel_t pronoc_inter_chip_out[CLUSTER_NX*CLUSTER_NY*2-1:0]
`endif // PITON_MULTICHIP
);

    logic [Fpay-1:0] dataIn[NE-1:0];
    logic [Fpay-1:0] dataOut[NE-1:0];
    logic [`NOC_X_WIDTH-1:0] default_coreid_x[NE-1:0];
    logic [`NOC_Y_WIDTH-1:0] default_coreid_y[NE-1:0];
    logic [FLATID_WIDTH-1:0] flat_tileid[NE-1:0];

    smartflit_chanel_t pronoc_chan_in [NE-1:0];
    smartflit_chanel_t pronoc_chan_out[NE-1:0];
    logic [RAw-1:0] current_r_addr[NE-1:0];
    logic [V-1:0] ovc_presence[NE-1:0];

    genvar i;
    generate
    for (i = 0; i < NE; i++) begin: E_
        assign dataIn[i] = dataIn_flatten[(i+1)*Fpay-1:i*Fpay];
        assign dataOut_flatten[(i+1)*Fpay-1:i*Fpay] = dataOut[i];
        assign default_coreid_x[i] = default_coreid_x_flatten[(i+1)*`NOC_X_WIDTH-1:i*`NOC_X_WIDTH];
        assign default_coreid_y[i] = default_coreid_y_flatten[(i+1)*`NOC_Y_WIDTH-1:i*`NOC_Y_WIDTH];
        assign flat_tileid[i] = flat_tileid_flatten[(i+1)*FLATID_WIDTH-1:i*FLATID_WIDTH];

        pronoc_to_piton_multimesh_wrapper
        #(
            .TILE_NUM(i),
            .FLATID_WIDTH(FLATID_WIDTH),
            .CONNECTED_TO_ENDP(1)
        ) pr2pi(
            .default_chipid(CHIP_ID[`NOC_CHIPID_WIDTH-1:0]),
            .default_coreid_x(default_coreid_x[i]),
            .default_coreid_y(default_coreid_y[i]),
            .flat_tileid(flat_tileid[i]),
            .reset(reset),
            .clk(clk),
            .dataOut(dataOut[i]),
            .validOut(validOut[i]),
            .yummyOut(yummyOut[i]),
            .current_r_addr_o(current_r_addr[i]),
            .chan_in(pronoc_chan_out[i]),
            .received_packet_src_addr_o(/* unused */),
            .ovc_presence_o(ovc_presence[i])
        );

        piton_to_pronoc_multimesh_wrapper
        #(
            .TILE_NUM(i),
            .FLATID_WIDTH(FLATID_WIDTH),
            .CONNECTED_TO_ENDP(1)
        ) pi2pr(
            .default_chipid(CHIP_ID[`NOC_CHIPID_WIDTH-1:0]),
            .default_coreid_x(default_coreid_x[i]),
            .default_coreid_y(default_coreid_y[i]),
            .flat_tileid(flat_tileid[i]),
            .reset(reset),
            .clk(clk),
            .dataIn(dataIn[i]),
            .validIn(validIn[i]),
            .yummyIn(yummyIn[i]),
            .current_r_addr_i(current_r_addr[i]),
            .chan_out(pronoc_chan_in[i]),
            .ovc_presence_i(ovc_presence[i])
        );
    end
    endgenerate

    // Instanciate directly the mesh_cluster
    mesh_cluster #(
        .CLUSTER_ID(CHIP_ID),
        .RID_INIT(CLUSTER_ID_OFFSET),
        .CLUSTER_NX(CLUSTER_NX),
        .CLUSTER_NY(CLUSTER_NY),
        .CLUSTER_NZ(CLUSTER_NZ),
        .CLUSTER_NE(NE)
    ) local_noc(
        .reset(reset),
        .clk(clk),
        .cluster_id(CHIP_ID[CLUSTER_IDw-1:0]),
        .endpoint_chan_in(pronoc_chan_in),
        .endpoint_chan_out(pronoc_chan_out),
`ifdef PITON_MULTICHIP
        .inter_cluster_chan_in(pronoc_inter_chip_in),
        .inter_cluster_chan_out(pronoc_inter_chip_out),
`else
        .inter_cluster_chan_in('{default: '{default: '0}}),
        .inter_cluster_chan_out(/* unused */),
`endif // PITON_MULTICHIP
        .router_event(/* unused */)
    );
endmodule
