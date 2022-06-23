`include "pronoc_def.v"
//`define MONITORE_PATH

/**********************************************************************
**	File: input_ports.v
**    
**	Copyright (C) 2014-2017  Alireza Monemi
**    
**	This file is part of ProNoC 
**
**	ProNoC ( stands for Prototype Network-on-chip)  is free software: 
**	you can redistribute it and/or modify it under the terms of the GNU
**	Lesser General Public License as published by the Free Software Foundation,
**	either version 2 of the License, or (at your option) any later version.
**
** 	ProNoC is distributed in the hope that it will be useful, but WITHOUT
** 	ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
** 	or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General
** 	Public License for more details.
**
** 	You should have received a copy of the GNU Lesser General Public
** 	License along with ProNoC. If not, see <http:**www.gnu.org/licenses/>.
**
**
**	Description: 
**	NoC router input Port. It consists of input buffer, control FIFO 
**	and request masking/generation control modules
**
**************************************************************/


/**************************

    iport_reg_base

**************************/

module iport_reg_base  #(
    parameter PCK_TYPE = "MULTI_FLIT",
    parameter V = 4,     // vc_num_per_port
    parameter P = 5,     // router port num
    parameter B = 4,     // buffer space :flit per VC 
    parameter T1= 8,
    parameter T2= 8,
    parameter T3= 8,
    parameter T4= 8,
    parameter RAw = 3,  
    parameter EAw = 3,  
    parameter C = 4,    //    number of flit class 
    parameter Fpay = 32,
    parameter SW_LOC = 0,
    parameter VC_REALLOCATION_TYPE =  "ATOMIC",
    parameter COMBINATION_TYPE= "BASELINE",// "BASELINE", "COMB_SPEC1", "COMB_SPEC2", "COMB_NONSPEC"
    parameter TOPOLOGY =  "MESH",//"MESH","TORUS"
    parameter ROUTE_NAME="XY",// "XY", "TRANC_XY"
    parameter ROUTE_TYPE="DETERMINISTIC",// "DETERMINISTIC", "FULL_ADAPTIVE", "PAR_ADAPTIVE"
    parameter DEBUG_EN =1,
    parameter AVC_ATOMIC_EN= 0,
    parameter CVw=(C==0)? V : C * V,
    parameter [CVw-1: 0] CLASS_SETTING = {CVw{1'b1}}, // shows how each class can use VCs   
    parameter [V-1  : 0] ESCAP_VC_MASK = 4'b1000,  // mask scape vc, valid only for full adaptive
    parameter DSTPw = P-1,
    parameter SSA_EN="YES", // "YES" , "NO"      
    parameter SWA_ARBITER_TYPE ="RRA",// "RRA","WRRA"
    parameter WEIGHTw=4,
    parameter WRRA_CONFIG_INDEX=0,
    parameter PPSw=4,
    parameter MIN_PCK_SIZE=2, //minimum packet size in flits. The minimum value is 1.
    parameter BYTE_EN=0

)(
    current_r_addr,
    neighbors_r_addr,
    ivc_num_getting_sw_grant,// for non spec ivc_num_getting_first_sw_grant,
    any_ivc_sw_request_granted,
    flit_in,
    flit_in_wr,
    reset_ivc,
    flit_is_tail,
    ivc_request,
    dest_port_encoded,
    dest_port,
    candidate_ovcs,
    flit_out,
    assigned_ovc_num,
    sel,
    port_pre_sel,
    swap_port_presel,
    reset,
    clk,
    nonspec_first_arbiter_granted_ivc,
    destport_clear,
    ssa_ivc_num_getting_sw_grant,
    iport_weight,
    oports_weight,  
    vc_weight_is_consumed,
    iport_weight_is_consumed,
    refresh_w_counter,
    granted_dest_port    
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
        VV = V * V,
        VDSTPw = V * DSTPw,
        Cw = (C>1)? log2(C): 1,
        Fw = 2+V+Fpay,   //flit width;    
        W = WEIGHTw,
        WP = W * P,
        P_1=P-1,
        VP_1 = V * P_1;    

    localparam
         /* verilator lint_off WIDTH */
         OFFSET = (B%MIN_PCK_SIZE)? 1 :0,
         NON_ATOM_PCKS =  (B>MIN_PCK_SIZE)?  (B/MIN_PCK_SIZE)+ OFFSET : 1,
         MAX_PCK = (VC_REALLOCATION_TYPE== "ATOMIC")?  1 : NON_ATOM_PCKS;// min packet size is two hence the max packet number in buffer is (B/2)
        /* verilator lint_on WIDTH */            

     localparam 
        ELw = log2(T3),
        VELw= V * ELw,
        PRAw= P * RAw;
   
 
    input reset, clk;
    input   [RAw-1 : 0] current_r_addr;
    input   [PRAw-1:  0]  neighbors_r_addr;
    input   [V-1 : 0] ivc_num_getting_sw_grant;
    input                      any_ivc_sw_request_granted;
    input   [Fw-1 : 0] flit_in;
    input                       flit_in_wr;
    input   [V-1 : 0] reset_ivc;
    output  [V-1 : 0] flit_is_tail;
    output  [V-1 : 0] ivc_request;
    output  [VDSTPw-1 : 0] dest_port_encoded;
    output  [VP_1-1 : 0] dest_port;
    output  [VV-1 : 0] candidate_ovcs;
    output  [Fw-1 : 0] flit_out;
    input   [VV-1 : 0] assigned_ovc_num;
    input   [V-1 : 0] sel;    
    input   [V-1 : 0] nonspec_first_arbiter_granted_ivc;
    input   [V-1 : 0] ssa_ivc_num_getting_sw_grant;    
    input   [(DSTPw*V)-1 : 0] destport_clear;            
    output  [WEIGHTw-1 : 0] iport_weight;
    output  [V-1 : 0] vc_weight_is_consumed;
    output  iport_weight_is_consumed;
    input   refresh_w_counter;
    input   [P_1-1 : 0] granted_dest_port; 
    output  [WP-1 : 0] oports_weight;  
    input   [PPSw-1 : 0] port_pre_sel;
    input   [V-1  : 0]  swap_port_presel;
  
            
    
    wire [Cw-1 : 0] class_in;
    wire [DSTPw-1 : 0] destport_in,destport_in_encoded;
    wire [VDSTPw-1 : 0] lk_destination_encoded;
    wire [EAw-1 : 0] dest_e_addr_in;
    wire [EAw-1 : 0] src_e_addr_in;
    wire [V-1 : 0] vc_num_in;
    wire [V-1 : 0] hdr_flit_wr,flit_wr;
    wire [V-1 : 0] hdr_flit_wr_delayed;
    wire [V-1 : 0] class_rd_fifo,dst_rd_fifo;
    wire [V-1 : 0] lk_dst_rd_fifo;
    wire [DSTPw-1 : 0] lk_destination_in_encoded;
    wire [WEIGHTw-1  : 0] weight_in;   
    wire [Fw-1 : 0] buffer_out;
    wire hdr_flg_in,tail_flg_in;  
    wire [V-1 : 0] ivc_not_empty;
    wire [Cw-1 : 0] class_out [V-1 : 0];
    wire  [VELw-1 : 0] endp_localp_num;
    wire [ELw-1 : 0] endp_l_in;
    logic  [WEIGHTw-1 : 0] iport_weight_next;       

//extract header flit info
    extract_header_flit_info #(
        .DATA_w(0)
     )
     header_extractor
     (
         .flit_in(flit_in),
         .flit_in_wr(flit_in_wr),         
         .class_o(class_in),
         .destport_o(destport_in),
         .dest_e_addr_o(dest_e_addr_in),
         .src_e_addr_o(src_e_addr_in),
         .vc_num_o(vc_num_in),
         .hdr_flit_wr_o(hdr_flit_wr),
         .hdr_flg_o(hdr_flg_in),
         .tail_flg_o(tail_flg_in),
         .weight_o(weight_in),
         .be_o( ),
         .data_o( )
     );
     
            
     
     
    // synopsys  translate_off
    // synthesis translate_off                                      
     `ifdef MONITORE_PATH
     
    genvar j;
    reg[V-1 :0] t1;
    generate
    for (j=0;j<V;j=j+1)begin : lp        
    always @(posedge clk) begin
        if(reset)begin 
             t1[j]<=1'b0;               
        end else begin 
            if(flit_in_wr >0 && vc_num_in[j] && t1[j]==0)begin 
                $display("%t : Parser: class_in=%x, destport_in=%x, dest_e_addr_in=%x, src_e_addr_in=%x, vc_num_in=%x,hdr_flit_wr=%x, hdr_flg_in=%x,tail_flg_in=%x ",$time,class_in, destport_in, dest_e_addr_in, src_e_addr_in, vc_num_in,hdr_flit_wr, hdr_flg_in,tail_flg_in);
                t1[j]<=1;
            end           
        end
    end
    end
    endgenerate
    `endif
    // synthesis translate_on
    // synopsys  translate_on       
     

    pronoc_register #(.W(WEIGHTw), .RESET_TO(1)) reg5(
    		.in		(iport_weight_next ), 
    		.reset  (reset ), 
    		.clk    (clk   ), 
    		.out    (iport_weight  ));
	
	
    always @ (*)begin 
    	iport_weight_next = iport_weight;
    	if(hdr_flit_wr != {V{1'b0}})  iport_weight_next = (weight_in=={WEIGHTw{1'b0}})? 1 : weight_in; // the minimum weight is 1
    end


// genrate write enable for lk_routing result with one clock cycle latency after reciveing the flit
    
    pronoc_register #(.W(V)) reg1(
    		.in		(hdr_flit_wr ), 
    		.reset  (reset ), 
    		.clk    (clk   ), 
    		.out    (hdr_flit_wr_delayed  ));




genvar i;
generate
    /* verilator lint_off WIDTH */  
    if (( TOPOLOGY == "RING" || TOPOLOGY == "LINE" || TOPOLOGY == "MESH" || TOPOLOGY == "TORUS") && (T3>1)) begin : multi_local
    /* verilator lint_on WIDTH */  
        mesh_tori_endp_addr_decode #(
            .TOPOLOGY("MESH"),
            .T1(T1),
            .T2(T2),
            .T3(T3),
            .EAw(EAw)
        )
        endp_addr_decode
        (
            .e_addr(dest_e_addr_in),
            .ex( ),
            .ey( ),
            .el(endp_l_in),
            .valid( )
        );
   end

    /* verilator lint_off WIDTH */  
    if(TOPOLOGY=="FATTREE" && ROUTE_NAME == "NCA_STRAIGHT_UP") begin : fat
    /* verilator lint_on WIDTH */  
     
     fattree_destport_up_select #(
         .K(T1),
         .SW_LOC(SW_LOC)
     )
     static_sel
     (
        .destport_in(destport_in),
        .destport_o(destport_in_encoded)
     );
     
    end else begin : other
        assign destport_in_encoded = destport_in;    
    end


      wire odd_column = current_r_addr[0]; 

    for (i=0;i<V; i=i+1) begin: V_loop
        
        class_ovc_table #(
            .CVw(CVw),
            .CLASS_SETTING(CLASS_SETTING),   
            .C(C),
            .V(V)
        )
        class_table
        (
            .class_in(class_out[i]),
            .candidate_ovcs(candidate_ovcs [(i+1)*V-1 : i*V])
        );    
        
        //tail fifo
        fwft_fifo #(
            .DATA_WIDTH(1),
            .MAX_DEPTH (B),
            .IGNORE_SAME_LOC_RD_WR_WARNING(SSA_EN)
        )
        tail_fifo
        (
            .din (tail_flg_in),
            .wr_en (flit_wr[i]),   // Write enable
            .rd_en (ivc_num_getting_sw_grant[i]),   // Read the next word
            .dout (flit_is_tail[i]),    // Data out
            .full ( ),
            .nearly_full ( ),
            .recieve_more_than_0 ( ),
            .recieve_more_than_1 ( ),
            .reset (reset),
            .clk (clk)            
        );
    
        //class_fifo
        if(C>1)begin :cb1
            fwft_fifo #(
                .DATA_WIDTH(Cw),
                .MAX_DEPTH (MAX_PCK)
            )
            class_fifo
            (
                .din (class_in),
                .wr_en (hdr_flit_wr[i]),   // Write enable
                .rd_en (class_rd_fifo[i]),   // Read the next word
                .dout (class_out[i]),    // Data out
                .full ( ),
                .nearly_full ( ),
                .recieve_more_than_0 ( ),
                .recieve_more_than_1 ( ),
                .reset (reset),
                .clk (clk)
            
            );
       end else begin :c_num_1
           assign class_out[i] = 1'b0;
       end
       
       //lk_dst_fifo
        fwft_fifo #(
            .DATA_WIDTH(DSTPw),
            .MAX_DEPTH (MAX_PCK)
        )
        lk_dest_fifo
        (
             .din (lk_destination_in_encoded),
             .wr_en (hdr_flit_wr_delayed [i]),   // Write enable
             .rd_en (lk_dst_rd_fifo [i]),   // Read the next word
             .dout (lk_destination_encoded  [(i+1)*DSTPw-1 : i*DSTPw]),    // Data out
             .full (),
             .nearly_full (),
             .recieve_more_than_0 (),
             .recieve_more_than_1 (),
             .reset (reset),
             .clk (clk)
             
        );
        
        /* verilator lint_off WIDTH */    
        if( ROUTE_TYPE=="DETERMINISTIC") begin : dtrmn_dest
        /* verilator lint_on WIDTH */
            //destport_fifo
            fwft_fifo #(
                 .DATA_WIDTH(DSTPw),
                 .MAX_DEPTH (MAX_PCK)
            )
            dest_fifo
            (
                 .din(destport_in_encoded),
                 .wr_en(hdr_flit_wr[i]),   // Write enable
                 .rd_en(dst_rd_fifo[i]),   // Read the next word
                 .dout(dest_port_encoded[(i+1)*DSTPw-1 : i*DSTPw]),    // Data out
                 .full(),
                 .nearly_full(),
                 .recieve_more_than_0(),
                 .recieve_more_than_1(),
                 .reset(reset),
                 .clk(clk) 
            );               
                         
        end else begin : adptv_dest   

            fwft_fifo_with_output_clear #(
                .DATA_WIDTH(DSTPw),
                .MAX_DEPTH (MAX_PCK)
            )
            dest_fifo
            (
                .din(destport_in_encoded),
                .wr_en(hdr_flit_wr[i]),   // Write enable
                .rd_en(dst_rd_fifo[i]),   // Read the next word
                .dout(dest_port_encoded[(i+1)*DSTPw-1 : i*DSTPw]),    // Data out
                .full(),
                .nearly_full(),
                .recieve_more_than_0(),
                .recieve_more_than_1(),
                .reset(reset),
                .clk(clk),
                .clear(destport_clear[(i+1)*DSTPw-1 : i*DSTPw])   // clear other destination ports once one of them is selected
            );                  
    
                
        end        	
        
                     
                     
        destp_generator #(
            .TOPOLOGY(TOPOLOGY),
            .ROUTE_NAME(ROUTE_NAME),
            .ROUTE_TYPE(ROUTE_TYPE),
            .T1(T1),
            .NL(T3),
            .P(P),
            .DSTPw(DSTPw),
            .ELw(ELw),
            .PPSw(PPSw),
            .SW_LOC(SW_LOC)
        )
        decoder
        (
            .destport_one_hot(),
            .dest_port_encoded(dest_port_encoded[(i+1)*DSTPw-1 : i*DSTPw]),             
            .dest_port_out(dest_port[(i+1)*P_1-1 : i*P_1]),   
            .endp_localp_num(endp_localp_num[(i+1)*ELw-1 : i*ELw]),
            .swap_port_presel(swap_port_presel[i]),
            .port_pre_sel(port_pre_sel),
            .odd_column(odd_column)
        );
         
         
         /* verilator lint_off WIDTH */  
        if (( TOPOLOGY == "RING" || TOPOLOGY == "LINE" || TOPOLOGY == "MESH" || TOPOLOGY == "TORUS") && (T3>1)) begin : multi_local
          /* verilator lint_on WIDTH */  
            // the router has multiple local ports. Save the destination local port 
                  
            
            fwft_fifo #(
                 .DATA_WIDTH(ELw),
                 .MAX_DEPTH (MAX_PCK)
            )
            local_dest_fifo
            (
                 .din(endp_l_in),
                 .wr_en(hdr_flit_wr[i]),   // Write enable
                 .rd_en(dst_rd_fifo[i]),   // Read the next word
                 .dout(endp_localp_num[(i+1)*ELw-1 : i*ELw]),    // Data out
                 .full( ),
                 .nearly_full( ),
                 .recieve_more_than_0(),
                 .recieve_more_than_1(),
                 .reset(reset),
                 .clk(clk) 
            );       
  
        end else begin : slp 
            assign endp_localp_num[(i+1)*ELw-1 : i*ELw] = {ELw{1'bx}}; 
        end
        
        /* verilator lint_off WIDTH */    
        if(SWA_ARBITER_TYPE != "RRA")begin  : wrra
        /* verilator lint_on WIDTH */
               /*
                weight_control #(
                    .WEIGHTw(WEIGHTw)
                )
                wctrl_per_vc
                (   
                    .sw_is_granted(ivc_num_getting_sw_grant[i]),
                    .flit_is_tail(flit_is_tail[i]),               
                    .weight_is_consumed_o(vc_weight_is_consumed[i]),    
                    .iport_weight(1),  //(iport_weight),               
                    .clk(clk),
                    .reset(reset)           
                );
                */     
            assign vc_weight_is_consumed[i] = 1'b1;
        end else begin :no_wrra
            assign vc_weight_is_consumed[i] = 1'bX;        
        end                  
            
    end//for i
    

    /* verilator lint_off WIDTH */    
    if(SWA_ARBITER_TYPE != "RRA")begin  : wrra
    /* verilator lint_on WIDTH */
        wire granted_flit_is_tail;
        
        onehot_mux_1D #(
        	.W(1),
        	.N(V)
        )
        onehot_mux(
        	.in(flit_is_tail),
        	.out(granted_flit_is_tail),
        	.sel(ivc_num_getting_sw_grant)
        );
    
        weight_control#(
            .ARBITER_TYPE(SWA_ARBITER_TYPE),
            .SW_LOC(SW_LOC),
            .WEIGHTw(WEIGHTw),
            .WRRA_CONFIG_INDEX(WRRA_CONFIG_INDEX),
            .P(P)
        )
        wctrl_iport
        (   
            .sw_is_granted(any_ivc_sw_request_granted),
            .flit_is_tail(granted_flit_is_tail),               
            .weight_is_consumed_o(iport_weight_is_consumed),    
            .iport_weight(iport_weight),
            .oports_weight(oports_weight),
            .granted_dest_port(granted_dest_port), 
            .refresh_w_counter(refresh_w_counter),              
            .clk(clk),
            .reset(reset)           
        );     
  
        end else begin :no_wrra
            assign iport_weight_is_consumed=1'bX;
            assign oports_weight = {WP{1'bX}};          
        end   
        
    /* verilator lint_off WIDTH */
    if(COMBINATION_TYPE == "COMB_NONSPEC") begin  : nonspec  
    /* verilator lint_on WIDTH */ 
           
        flit_buffer #(
            .B(B),   // buffer space :flit per VC 
            .SSA_EN(SSA_EN)
        )
        the_flit_buffer
        (
            .din(flit_in),     // Data in
            .vc_num_wr(vc_num_in),//write vertual chanel   
            .vc_num_rd(nonspec_first_arbiter_granted_ivc),//read vertual chanel     
            .wr_en(flit_in_wr),   // Write enable
            .rd_en(any_ivc_sw_request_granted),     // Read the next word
            .dout(buffer_out),    // Data out
            .vc_not_empty(ivc_not_empty),
            .reset(reset),
            .clk(clk),
            .ssa_rd(ssa_ivc_num_getting_sw_grant),
            .multiple_dest(),
            .sub_rd_ptr_ld(),
            .flit_is_tail()
        );
        
        
        
         localparam VCw = V *Cw;
        wire [Fw-1:0] new_buffer_out;
        wire [V-1 : 0] new_ivc_not_empty;
        wire [VCw-1 : 0] class_all;
        
        
        
        flit_buffer_reg_base #(
            .PCK_TYPE(PCK_TYPE),
            .V(V),
            .B(B),
            .Fpay(Fpay),
            .DEBUG_EN(DEBUG_EN),
            
            .DSTPw(DSTPw)
           
        )
        nn
        (
            .din(flit_in),
            .vc_num_wr(vc_num_in),
            .wr_en(flit_in_wr),
            .vc_num_rd(nonspec_first_arbiter_granted_ivc),
            .rd_en(any_ivc_sw_request_granted),
            .dout(new_buffer_out),
            .vc_not_empty(new_ivc_not_empty),
            .reset(reset),
            .clk(clk),
            .class_all()
        );
        
        //synthesis translate_off 
        //synopsys  translate_off
        reg check_dout;        
        always @(posedge clk )begin 
            check_dout<=any_ivc_sw_request_granted;
            if(new_ivc_not_empty != ivc_not_empty) begin 
                $display("%t: Error: new_iv_not_empty (%h) != iv_not_empty (%h)",$time, new_ivc_not_empty, ivc_not_empty);
                $stop; 
            end
            
           if( check_dout & ( new_buffer_out[Fpay-1 : 0] != buffer_out[Fpay-1 : 0])) begin 
                $display("%t: Error: new_buffer_out (%h) != buffer_out (%h)",$time, new_buffer_out, buffer_out);
                $stop; 
           end
        end
        //synopsys  translate_on
        //synthesis translate_on 
       
        
        
        
        // for (i=0;i<V; i=i+1) begin: V_loop3
         
        // end
        
        
   
    end else begin :spec//not nonspec comb
 

        flit_buffer #(
            .B(B),   // buffer space :flit per VC 
            .SSA_EN(SSA_EN)
        )
        the_flit_buffer
        (
            .din(flit_in),     // Data in
            .vc_num_wr(vc_num_in),//write vertual chanel   
            .vc_num_rd(ivc_num_getting_sw_grant),//read vertual chanel     
            .wr_en(flit_in_wr),   // Write enable
            .rd_en(any_ivc_sw_request_granted),     // Read the next word
            .dout(buffer_out),    // Data out
            .vc_not_empty(ivc_not_empty),
            .reset(reset),
            .clk(clk),
            .ssa_rd(ssa_ivc_num_getting_sw_grant),
            .multiple_dest(),
            .sub_rd_ptr_ld(),
            .flit_is_tail()  
           
        );  
  
    end       
endgenerate    

    look_ahead_routing #(
    	.T1(T1),
        .T2(T2),
        .T3(T3),
        .T4(T4), 
        .P(P),       
        .RAw(RAw),  
        .EAw(EAw), 
    	.DSTPw(DSTPw),
    	.SW_LOC(SW_LOC),
    	.TOPOLOGY(TOPOLOGY),
    	.ROUTE_NAME(ROUTE_NAME),
    	.ROUTE_TYPE(ROUTE_TYPE)
    )
    lk_routing
    (
        .current_r_addr(current_r_addr),
        .neighbors_r_addr(neighbors_r_addr),
        .dest_e_addr(dest_e_addr_in),
        .src_e_addr(src_e_addr_in),
        .destport_encoded(destport_in_encoded),
        .lkdestport_encoded(lk_destination_in_encoded),
        .reset(reset),
        .clk(clk)
     );

    header_flit_update_lk_route_ovc #(
        .V(V),
        .P(P),
      
        .TOPOLOGY(TOPOLOGY),     
        .EAw(EAw),
        .DSTPw(DSTPw),
        .SSA_EN(SSA_EN),          
        .ROUTE_TYPE(ROUTE_TYPE)
    
    )
    the_flit_update
    (
        .flit_in (buffer_out),
        .flit_out (flit_out),
        .vc_num_in(ivc_num_getting_sw_grant),
        .lk_dest_all_in (lk_destination_encoded),
        .assigned_ovc_num (assigned_ovc_num),
        .any_ivc_sw_request_granted(any_ivc_sw_request_granted),
        .lk_dest_not_registered(lk_destination_in_encoded),
        .sel (sel),
        .reset (reset),
        .clk (clk)
    );
    
    assign flit_wr =(flit_in_wr )? vc_num_in : {V{1'b0}};
        
    
    pronoc_register #(.W(V)) reg2(
    		.in		(dst_rd_fifo ), 
    		.reset  (reset ), 
    		.clk    (clk   ), 
    		.out    (lk_dst_rd_fifo  ));

   
    assign    dst_rd_fifo = reset_ivc;
    assign    class_rd_fifo = (C>1)? reset_ivc : {V{1'bx}};
    assign    ivc_request = ivc_not_empty;    

//synthesis translate_off
//synopsys  translate_off
generate 
if(DEBUG_EN) begin :dbg

    debug_IVC_flit_type_order_check #(
    	.V(V)
    )
    IVC_flit_type_check
    (
    	.clk(clk),
    	.reset(reset),
    	.hdr_flg_in(hdr_flg_in),
    	.tail_flg_in(tail_flg_in),
    	.flit_in_wr(flit_in_wr),
    	.vc_num_in(vc_num_in),
    	.reset_all_errors(1'b0),
    	.active_IVC_hdr_flit_received_err( ),
    	.inactive_IVC_tail_flit_received_err( ),
    	.inactive_IVC_body_flit_received_err( )
    );

     /* verilator lint_off WIDTH */  
     if (( TOPOLOGY == "RING" || TOPOLOGY == "LINE" || TOPOLOGY == "MESH" || TOPOLOGY == "TORUS")) begin : mesh_based
     /* verilator lint_on WIDTH */  

        debug_mesh_tori_route_ckeck #(
            .T1(T1),
            .T2(T2),
            .T3(T3),
            .ROUTE_TYPE(ROUTE_TYPE),
            .V(V),
            .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
            .SW_LOC(SW_LOC),
            .ESCAP_VC_MASK(ESCAP_VC_MASK),
            .TOPOLOGY(TOPOLOGY),
            .DSTPw(DSTPw),
            .RAw(RAw),
            .EAw(EAw)
        )
        route_ckeck
        (
            .reset(reset),
            .clk(clk),
            .hdr_flg_in(hdr_flg_in),
            .flit_in_wr(flit_in_wr),
            .vc_num_in(vc_num_in),
            .flit_is_tail(flit_is_tail),
            .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant),
            .current_r_addr(current_r_addr),
            .dest_e_addr_in(dest_e_addr_in),
            .src_e_addr_in(src_e_addr_in),
            .destport_in(destport_in)      
        );   
    end//mesh  
end//DEBUG_EN 
endgenerate 
//synopsys  translate_on  
//synthesis translate_on


endmodule
