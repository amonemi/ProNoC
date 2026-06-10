`include "pronoc_def.v"

/**************************************
* Module: chi_wrapper
* Date:2019-05-03
* Author: alireza
*
* Description: 
***************************************/


module chi_to_pronoc_wrapper (
    chi_flit_i,
    chi_flitpend_i,
    chi_flitv_i,
    chi_lcrdv_i,
    current_r_addr_i,
    pronoc_chan_out,
    clk,
    reset
);
    import pronoc_pkg::*;
    import amba_5_chi_pkg::*;
    
    input chi_flitpend_i, chi_flitv_i, chi_lcrdv_i, clk,reset;  
    input [Fpay-1 : 0]  chi_flit_i;
    input [RAw-1 : 0] current_r_addr_i;
    output smartflit_chanel_t pronoc_chan_out;
    
    wire [QOS_REQ-1 : 0] qos;
    wire [TGTID_REQ-1 : 0] target_id;
    wire [SRCID_REQ-1 : 0] src_id;
    wire [Fpay-QOS_REQ-TGTID_REQ-SRCID_REQ-1 : 0] rest_flit;
    assign {qos,target_id,src_id,rest_flit} = chi_flit_i;    
    
    wire [ EAw-1 : 0] dest_e_addr;// = target_id[ EAw-1 : 0];//TODO need to check how they code the destiation adreeses
    wire [ EAw-1 : 0] src_e_addr;// = src_id[ EAw-1 : 0];//TODO need to check how they code the source adreeses
    wire [DSTPw-1: 0] destport;   
    wire [Fw-1 : 0] pronoc_hdr_flit;
    
    endp_addr_encoder des_addr_encoder (
        .id_in(target_id[NEw-1:0]),
        .code_out(dest_e_addr)
    );
    
    endp_addr_encoder src_addr_encoder (
        .id_in(src_id[NEw-1:0]),
        .code_out(src_e_addr)
    );
    
    generate 
    if((CAST_TYPE == "UNICAST") && (IS_LOOKAHEAD==1'b1)) begin : uni
    //The router is configured with lookaheadrouting. 
    //The header flit is supposed to carry the destinaion output port
        conventional_routing #(
            .LOCATED_IN_NI(1)
        ) route_compute (
            .reset(1'b0), //only needed for fattree
            .clk(1'b0), // only needed for fattree
            .current_r_addr(current_r_addr_i),
            .dest_e_addr(dest_e_addr),
            .src_e_addr(src_e_addr),
            .destport(destport)
        );
    end
    endgenerate 
    localparam [WEIGHTw-1 : 0] WINIT = 1;
    
    header_flit_generator #(
        .DATA_w(Fpay)
    ) hdr_flit_gen (
        .flit_out(pronoc_hdr_flit),
        .class_in(1'b0),
        .dest_e_addr_in(dest_e_addr),
        .src_e_addr_in(src_e_addr),
        .destport_in(destport),
        .vc_num_in(1'b0),
        .weight_in(WINIT),
        .data_in(chi_flit_i),
        .be_in(1'b0)
    );
    
    assign  pronoc_chan_out.flit_chanel.flit_wr = chi_flitv_i;
    assign  pronoc_chan_out.flit_chanel.credit = chi_lcrdv_i;
    assign  pronoc_chan_out.flit_chanel.flit.hdr_flag = 1'b1;
    assign  pronoc_chan_out.flit_chanel.flit.tail_flag = 1'b1;
    assign  pronoc_chan_out.flit_chanel.flit.vc = 1'b1;
    assign  pronoc_chan_out.flit_chanel.flit.payload = pronoc_hdr_flit[FPAYw-1 : 0];
    //credit release should be asserted externaly via register. For simulation we just use a counter to set it few cycles after reset
    reg [3:0] counter;
    always @(posedge clk or posedge reset)begin 
        if(reset)  counter<=0;
        else if(counter<4) counter<=counter+1'b1;
    end
    
    wire credit_release = counter==4;
    genvar i;
    generate
    for (i=0; i<V;i++) begin :V_
        assign pronoc_chan_out.ctrl_chanel.credit_init_val[i]= 0;
        assign pronoc_chan_out.ctrl_chanel.credit_release_en[i]= credit_release;
    end
    endgenerate
    
    `ifdef SIMULATION
    always @(posedge clk) begin 
        if((dest_e_addr == src_e_addr ) & chi_flitv_i ) begin 
            $display("%t:Error: The src and destination address of injected packet is the same in core (%d) %m",$time,src_id);
            $stop;
        end
    end
    `endif
endmodule


//snoop chanel doesnot have target id. our home node does not support broad casting so we need to add target id from home node  
module  snp_chi_to_pronoc_wrapper (
    chi_flit_i,
    chi_flitpend_i,
    chi_flitv_i,
    chi_lcrdv_i,
    snp_target_id,
    current_r_addr_i,
    pronoc_chan_out,
    clk,
    reset
);
    import pronoc_pkg::*;
    import amba_5_chi_pkg::*;
    
    input chi_flitpend_i, chi_flitv_i, chi_lcrdv_i, clk, reset;  
    input [Fpay-1 : 0]  chi_flit_i;
    input [RAw-1 : 0] current_r_addr_i;
    input [TGTID_DAT-1 : 0] snp_target_id;
    output smartflit_chanel_t pronoc_chan_out;
    
    wire [QOS_SNP-1 : 0] qos;
    wire [TGTID_REQ-1 : 0] target_id =  snp_target_id;
    wire [SRCID_SNP-1 : 0] src_id;
    wire [Fpay-QOS_SNP-SRCID_SNP-1 : 0] rest_flit;
    assign {qos,src_id,rest_flit} = chi_flit_i;
    
    wire [ EAw-1 : 0] dest_e_addr;
    wire [ EAw-1 : 0] src_e_addr;// = src_id[ EAw-1 : 0];//TODO need to check how they code the source adreeses
    wire [DSTPw-1: 0] destport;
    wire [Fw-1 : 0] pronoc_hdr_flit;
    
    endp_addr_encoder  des_addr_encoder  (
        .id_in(target_id[NEw-1:0]),
        .code_out(dest_e_addr)
    );
    
    endp_addr_encoder src_addr_encoder (
        .id_in(src_id[NEw-1:0]),
        .code_out(src_e_addr)
    );
    generate 
    if((CAST_TYPE == "UNICAST") && (IS_LOOKAHEAD==1'b1)) begin : uni
    //The router is configured with lookaheadrouting. 
    //The header flit is supposed to carry the destinaion output port
        conventional_routing #(
            .LOCATED_IN_NI(1)
        ) route_compute (
            .reset(1'b0), //only needed for fattree
            .clk(1'b0), // only needed for fattree
            .current_r_addr(current_r_addr_i),
            .dest_e_addr(dest_e_addr),
            .src_e_addr(src_e_addr),
            .destport(destport)
        );
    end
    endgenerate
    localparam [WEIGHTw-1 : 0] WINIT = 1;
    
    header_flit_generator #(
        .DATA_w(Fpay)
    ) hdr_flit_gen (
        .flit_out(pronoc_hdr_flit),
        .class_in(1'b0),
        .dest_e_addr_in(dest_e_addr),
        .src_e_addr_in(src_e_addr),
        .destport_in(destport),
        .vc_num_in(1'b0),
        .weight_in(WINIT),
        .data_in(chi_flit_i),
        .be_in(1'b0)
    );
    
    assign  pronoc_chan_out.flit_chanel.flit_wr  = chi_flitv_i;
    assign  pronoc_chan_out.flit_chanel.credit   = chi_lcrdv_i;
    assign  pronoc_chan_out.flit_chanel.flit.hdr_flag = 1'b1;
    assign  pronoc_chan_out.flit_chanel.flit.tail_flag= 1'b1;
    assign  pronoc_chan_out.flit_chanel.flit.vc= 1'b1;
    assign  pronoc_chan_out.flit_chanel.flit.payload= pronoc_hdr_flit[FPAYw-1 : 0];    
    //credit release should be asserted externaly via register. For simulation we just use a counter to set it few cycles after reset
    reg [3:0] counter;
    always @(posedge clk or posedge reset)begin 
        if(reset)  counter<=0;
        else if(counter<4) counter<=counter+1'b1;
    end
    wire credit_release = counter==4;
    
    genvar i;
    generate
    for (i=0; i<V;i++) begin :V_
        assign pronoc_chan_out.ctrl_chanel.credit_init_val[i]= 0;
        assign pronoc_chan_out.ctrl_chanel.credit_release_en[i]= credit_release;
    end
    endgenerate
    
    `ifdef SIMULATION
    always @(posedge clk) begin 
        if((dest_e_addr == src_e_addr ) & chi_flitv_i ) begin 
            $display("%t:Error: The src and destination address of injected packet is the same in core (%d) %m",$time,src_id);
            $stop;
        end
    end
    `endif
endmodule


module pronoc_to_chi_wrapper (
    pronoc_chan_in,
    chi_flit_o,
    chi_flitpend_o,
    chi_flitv_o,
    chi_lcrdv_o
);
    import pronoc_pkg::*; 
    input smartflit_chanel_t pronoc_chan_in;
    output [Fpay-1 : 0]  chi_flit_o;
    output  chi_flitpend_o,   chi_flitv_o, chi_lcrdv_o;
    
    assign chi_flitv_o = pronoc_chan_in.flit_chanel.flit_wr;
    assign chi_lcrdv_o = pronoc_chan_in.flit_chanel.credit; 
    assign chi_flitpend_o = 1'b1;
    
    header_flit_info #(
        .DATA_w(Fpay)
    )extr(
        .flit(pronoc_chan_in.flit_chanel.flit),
        .hdr_flit(),
        .data_o(chi_flit_o)
    );
endmodule



module  chi_noc (
    reset,
    clk,
    /*--------- Interface with NoC ---------------------------------*/    
    //TX // snoop tx home node
    // wire   [TGTID_REQ-1 : 0] chi_noc_tx__target_id_all ; // we are not supporting braod casting on snoop chanel so need target ID
    chi_noc_txflitpend_all, 
    chi_noc_txflitv_all,
    chi_noc_txflit_all,
    noc_chi_txlcrdv_all,
    
    // /RX
    noc_chi_rxflitpend_all,
    noc_chi_rxflitv_all,
    noc_chi_rxflit_all,
    chi_noc_rxlcrdv_all,
    
    snp_target_id_all //only needed for snp
    );
    
    import pronoc_pkg::*;
    import amba_5_chi_pkg::*;
    
    // Clock and Reset
    input clk,reset;
    input [TGTID_DAT * NE-1 : 0]  snp_target_id_all;
    
    
    /*--------- Interface with NoC ---------------------------------*/
    // RX
    output   [NE-1 : 0] noc_chi_rxflitpend_all ;
    output   [NE-1 : 0] noc_chi_rxflitv_all ;
    output   [Fpay*NE-1:0]  noc_chi_rxflit_all ;
    input  [NE-1 : 0] chi_noc_rxlcrdv_all ;
    
    //TX 
    input   [NE-1 : 0] chi_noc_txflitpend_all ;
    input   [NE-1 : 0] chi_noc_txflitv_all ;
    input   [Fpay*NE-1:0]    chi_noc_txflit_all ;
    output  [NE-1 : 0] noc_chi_txlcrdv_all ;
    
    wire  [Fpay-1:0]    noc_chi_rxflit [NE-1 : 0];
    wire  [Fpay-1:0]    chi_noc_txflit [NE-1 : 0]; 
    wire  [TGTID_DAT-1  :0]   snp_target_id [NE-1 : 0];

    /*----------------------------------------------------------------------------*/
    /*ProNoC interface */
    /*----------------------------------------------------------------------------*/
    //local ports 
    smartflit_chanel_t pronoc_chan_in  [NE-1 : 0];
    smartflit_chanel_t pronoc_chan_out [NE-1 : 0];
    noc_top the_noc (
        .reset(reset),
        .clk(clk),
        .chan_in_all (pronoc_chan_in),
        .chan_out_all(pronoc_chan_out)
    );
    
    genvar i;
    generate 
    for(i=0;i<NE;i=i+1)begin :ne
     //connected router encoded address
        localparam CURRENTR=  i/T3;
        localparam CURRENTX=  CURRENTR%T1;
        localparam CURRENTY=  CURRENTR/T1;
        localparam [RAw-1 : 0] CURRENT_ADDR =  (CURRENTY<<NXw) + CURRENTX; 
        
        assign snp_target_id [i] = snp_target_id_all[(i+1)* TGTID_DAT-1 : i* TGTID_DAT];
        assign chi_noc_txflit[i] = chi_noc_txflit_all[(i+1)*Fpay-1 : i*Fpay];
        assign noc_chi_rxflit_all [(i+1)*Fpay-1 : i*Fpay] = noc_chi_rxflit[i];  
        
        if(NOC_ID == "snp") begin : _snp
            snp_chi_to_pronoc_wrapper chi_to_pronoc (
                .chi_flitpend_i(chi_noc_txflitpend_all[i]),
                .chi_flitv_i(chi_noc_txflitv_all[i]),
                .chi_lcrdv_i(chi_noc_rxlcrdv_all[i]),
                .chi_flit_i(chi_noc_txflit[i]),
                .snp_target_id(snp_target_id[i]),//comes from home nodes
                .current_r_addr_i(CURRENT_ADDR),
                .pronoc_chan_out(pronoc_chan_in[i]),
                .clk(clk),
                .reset(reset)
            );
        end else begin 
            chi_to_pronoc_wrapper chi_to_pronoc (
                .chi_flitpend_i(chi_noc_txflitpend_all[i]),
                .chi_flitv_i(chi_noc_txflitv_all[i]),
                .chi_lcrdv_i(chi_noc_rxlcrdv_all[i]),
                .chi_flit_i(chi_noc_txflit[i]),
                .current_r_addr_i(CURRENT_ADDR),
                .pronoc_chan_out(pronoc_chan_in[i]),
                .clk(clk),
                .reset(reset)
            );
        end
        pronoc_to_chi_wrapper pronoc_to_chi (
            .chi_flit_o(noc_chi_rxflit[i]),
            .chi_flitpend_o(noc_chi_rxflitpend_all[i]),
            .chi_flitv_o(noc_chi_rxflitv_all[i]),
            .chi_lcrdv_o(noc_chi_txlcrdv_all[i]),
            .pronoc_chan_in(pronoc_chan_out[i])
        );
    end
    endgenerate
endmodule

