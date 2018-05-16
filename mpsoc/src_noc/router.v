`timescale     1ns/1ps

/***********************************************************************
**	File: router.v
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
**	NoC router top level module.
**
**************************************************************/


module router # (
    parameter V = 4,     // vc_num_per_port
    parameter P = 5,     // router port num
    parameter B = 4,     // buffer space :flit per VC 
    parameter NX = 8,    // number of node in x axis
    parameter NY = 8,    // number of node in y axis
    parameter C = 2,    //    number of flit class 
    parameter Fpay = 32,
    parameter TOPOLOGY= "MESH", 
    parameter MUX_TYPE= "ONE_HOT",    //"ONE_HOT" or "BINARY"
    parameter VC_REALLOCATION_TYPE = "NONATOMIC",// "ATOMIC" , "NONATOMIC"
    parameter COMBINATION_TYPE= "COMB_SPEC1",// "BASELINE", "COMB_SPEC1", "COMB_SPEC2", "COMB_NONSPEC"
    parameter FIRST_ARBITER_EXT_P_EN = 0,
    parameter ROUTE_TYPE = "FULL_ADAPTIVE",// "DETERMINISTIC", "FULL_ADAPTIVE", "PAR_ADAPTIVE"
    parameter ROUTE_NAME = "DUATO",
    parameter CONGESTION_INDEX = 7,
    parameter DEBUG_EN=0,
    parameter ROUTE_SUBFUNC= "XY",
    parameter AVC_ATOMIC_EN= 0,
    parameter CONGw = 3, //congestion width per port
    parameter ADD_PIPREG_AFTER_CROSSBAR=0,
    parameter CVw=(C==0)? V : C * V,
    parameter [CVw-1:  0] CLASS_SETTING = {CVw{1'b1}}, // shows how each class can use VCs   
    parameter [V-1 :  0] ESCAP_VC_MASK = 4'b1000,  // mask scape vc, valid only for full adaptive
    parameter SSA_EN="YES", // "YES" , "NO"
    parameter SWA_ARBITER_TYPE = "RRA",//"RRA","WRRA". RRA: Round Robin Arbiter WRRA weighted Round Robin Arbiter 
    parameter WEIGHTw = 4 // WRRA width
    
)(
    current_x,
    current_y,
    flit_in_all,
    flit_in_we_all,
    credit_out_all,
    congestion_in_all,
    
    flit_out_all,
    flit_out_we_all,
    credit_in_all,
    congestion_out_all,
    
    clk,reset

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
        PV = V * P,
        PVV = PV * V,    
        P_1 = P-1,
        PP_1 = P_1 * P,
        PVP_1 = PV * P_1,
        Fw = 2+V+Fpay,    //flit width;    
        PFw = P*Fw,
        Xw = log2(NX),
        Yw = log2(NY),
        CONG_ALw = CONGw* P,    //  congestion width per router
        W = WEIGHTw,
        WP = W * P, 
        WPP=  WP * P;  
        
    localparam 
        CLASS_HDR_WIDTH =8,
        ROUTING_HDR_WIDTH =8,
        DST_ADR_HDR_WIDTH =8,
        SRC_ADR_HDR_WIDTH =8;               
                   

    
    input  [Xw-1 :  0]  current_x;
    input  [Yw-1 :  0]  current_y;
    
    input  [PFw-1 :  0]  flit_in_all;
    input  [P-1 :  0]  flit_in_we_all;
    output [PV-1 :  0]  credit_out_all;
    input  [CONG_ALw-1 :  0]  congestion_in_all;
    
    output [PFw-1 :  0]  flit_out_all;
    output [P-1 :  0]  flit_out_we_all;
    input  [PV-1 :  0]  credit_in_all;
    output [CONG_ALw-1 :  0]  congestion_out_all;
    
    input clk,reset;

    
    //internal wires
    wire  [PV-1 : 0] ovc_allocated_all;
    wire  [PVV-1 : 0] granted_ovc_num_all;
    wire  [PV-1 : 0] ivc_num_getting_sw_grant;
    wire  [PV-1 : 0] ivc_num_getting_ovc_grant;
    wire  [PVV-1 : 0] spec_ovc_num_all;
    wire  [PV-1 : 0] nonspec_first_arbiter_granted_ivc_all;
    wire  [PV-1 : 0] spec_first_arbiter_granted_ivc_all;
    wire  [PP_1-1 : 0] nonspec_granted_dest_port_all;
    wire  [PP_1-1 : 0] spec_granted_dest_port_all;    
    wire  [PP_1-1 : 0] granted_dest_port_all;
    wire  [P-1 : 0] any_ivc_sw_request_granted_all;
    wire  [P-1 :  0] any_ovc_granted_in_outport_all;    
    
    // to vc/sw allocator
    wire  [PVP_1-1 :  0] dest_port_all;
    wire  [PV-1 :  0] ovc_is_assigned_all;
    wire  [PV-1 :  0] ivc_request_all;
    wire  [PV-1 :  0] assigned_ovc_not_full_all;
    wire  [PVV-1 :  0] masked_ovc_request_all;
    wire  [PVP_1-1 :  0] lk_destination_all;  
    wire  [PV-1 :  0] vc_weight_is_consumed_all;
    wire  [P-1 :  0]iport_weight_is_consumed_all;    


    
        
    // to the crossbar
    wire  [PFw-1 : 0] iport_flit_out_all;
    wire  [P-1 : 0] ssa_flit_wr_all;
    wire  [PFw-1 :  0] cross_bar_flit_out_all;
    reg   [PP_1-1 : 0] granted_dest_port_all_delayed;
    
    
    //to weight control
    wire [WP-1 : 0] iport_weight_all;
    wire [WPP-1: 0] oports_weight_all;
    wire refresh_w_counter;
    
    inout_ports
    #(
        .V(V),
        .P(P),
        .B(B), 
        .NX(NX),
        .NY(NY),
        .C(C),    
        .Fpay(Fpay),    
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .COMBINATION_TYPE(COMBINATION_TYPE),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_TYPE(ROUTE_TYPE),
        .ROUTE_NAME(ROUTE_NAME),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .DEBUG_EN(DEBUG_EN),
        .ROUTE_SUBFUNC(ROUTE_SUBFUNC),
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .CONGw(CONGw),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING),   
        .ESCAP_VC_MASK(ESCAP_VC_MASK),
        .CLASS_HDR_WIDTH(CLASS_HDR_WIDTH),
        .ROUTING_HDR_WIDTH(ROUTING_HDR_WIDTH),
        .DST_ADR_HDR_WIDTH(DST_ADR_HDR_WIDTH),
        .SRC_ADR_HDR_WIDTH(SRC_ADR_HDR_WIDTH),
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE (SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw),
        .WRRA_CONFIG_INDEX(0) 
        
    )
    the_inout_ports
    (
        .current_x(current_x),
        .current_y(current_y),
        .flit_in_all(flit_in_all),
        .flit_in_we_all(flit_in_we_all),
        .credit_out_all(credit_out_all),
        .credit_in_all(credit_in_all),
        .masked_ovc_request_all(masked_ovc_request_all),
        .ovc_allocated_all(ovc_allocated_all), 
        .granted_ovc_num_all(granted_ovc_num_all), 
        .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant), 
        .ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant), 
        .spec_ovc_num_all(spec_ovc_num_all), 
        .nonspec_first_arbiter_granted_ivc_all(nonspec_first_arbiter_granted_ivc_all), 
        .spec_first_arbiter_granted_ivc_all(spec_first_arbiter_granted_ivc_all), 
        .nonspec_granted_dest_port_all(nonspec_granted_dest_port_all), 
        .spec_granted_dest_port_all(spec_granted_dest_port_all), 
        .granted_dest_port_all(granted_dest_port_all), 
        .any_ivc_sw_request_granted_all(any_ivc_sw_request_granted_all), 
        .any_ovc_granted_in_outport_all(any_ovc_granted_in_outport_all),
        .dest_port_all(dest_port_all), 
        .ovc_is_assigned_all(ovc_is_assigned_all), 
        .ivc_request_all(ivc_request_all), 
        .assigned_ovc_not_full_all(assigned_ovc_not_full_all), 
        .flit_out_all(iport_flit_out_all),
        .congestion_in_all(congestion_in_all),
        .congestion_out_all(congestion_out_all),
        .lk_destination_all(lk_destination_all),
        .ssa_flit_wr_all(ssa_flit_wr_all),
        .iport_weight_all(iport_weight_all),
        .oports_weight_all(oports_weight_all),
        .vc_weight_is_consumed_all(vc_weight_is_consumed_all),
        .iport_weight_is_consumed_all(iport_weight_is_consumed_all), 
        .refresh_w_counter(refresh_w_counter), 
        .clk(clk), 
        .reset(reset)
    );


    combined_vc_sw_alloc #(
        .V(V),    
        .P(P), 
        .COMBINATION_TYPE(COMBINATION_TYPE),
        .FIRST_ARBITER_EXT_P_EN (FIRST_ARBITER_EXT_P_EN),
        .SWA_ARBITER_TYPE (SWA_ARBITER_TYPE ), 
        .DEBUG_EN(DEBUG_EN)
    )
    the_combined_vc_sw_alloc
    (
        .dest_port_all(dest_port_all), 
        .masked_ovc_request_all(masked_ovc_request_all),
        .ovc_is_assigned_all(ovc_is_assigned_all), 
        .ivc_request_all(ivc_request_all), 
        .assigned_ovc_not_full_all(assigned_ovc_not_full_all), 
        .ovc_allocated_all(ovc_allocated_all), 
        .granted_ovc_num_all(granted_ovc_num_all), 
        .ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant), 
        .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant), 
        .spec_first_arbiter_granted_ivc_all(spec_first_arbiter_granted_ivc_all), 
        .nonspec_first_arbiter_granted_ivc_all(nonspec_first_arbiter_granted_ivc_all), 
        .nonspec_granted_dest_port_all(nonspec_granted_dest_port_all), 
        .spec_granted_dest_port_all(spec_granted_dest_port_all), 
        .granted_dest_port_all(granted_dest_port_all), 
        .any_ivc_sw_request_granted_all(any_ivc_sw_request_granted_all), 
        .any_ovc_granted_in_outport_all(any_ovc_granted_in_outport_all),
        .spec_ovc_num_all(spec_ovc_num_all), 
        .lk_destination_all(lk_destination_all),  
        .vc_weight_is_consumed_all(vc_weight_is_consumed_all),  
        .iport_weight_is_consumed_all(iport_weight_is_consumed_all),  
        .clk(clk), 
        .reset(reset)
        );
        
   
    always @( posedge clk or posedge reset)begin
        if(reset) begin 
            granted_dest_port_all_delayed<= {PP_1{1'b0}};            
        end else begin
            granted_dest_port_all_delayed<= granted_dest_port_all;            
        end    
    end//always
    
   crossbar #(
        .V (V),     // vc_num_per_port
        .P (P),     // router port num
        .Fpay (Fpay),
        .MUX_TYPE (MUX_TYPE),
        .ADD_PIPREG_AFTER_CROSSBAR (ADD_PIPREG_AFTER_CROSSBAR),
        .SSA_EN (SSA_EN)
    )
    the_crossbar
    (
        .granted_dest_port_all (granted_dest_port_all_delayed),
        .flit_in_all (iport_flit_out_all),
        .flit_out_all (cross_bar_flit_out_all),
        .flit_out_we_all (flit_out_we_all),
        .ssa_flit_wr_all (ssa_flit_wr_all),
        .clk (clk),
        .reset (reset)
        
    );    
     
      
    generate
    /* verilator lint_off WIDTH */ 
    if (SWA_ARBITER_TYPE != "RRA" ) begin : wrra_arb 
    /* verilator lint_on WIDTH */ 
   
        wire [WP-1 : 0] contention_all;
        wire [WP-1 : 0] limited_oport_weight_all;
   
        wrra_contention_gen #(
            .WEIGHTw(WEIGHTw),
            .WRRA_CONFIG_INDEX(0),
            .V(V),
            .P(P)
        )
        contention_gen
        (
            .limited_oport_weight_all(limited_oport_weight_all),
            .dest_port_all(dest_port_all),
            .ivc_request_all(ivc_request_all),
            .ovc_is_assigned_all(ovc_is_assigned_all), 
            .contention_all(contention_all),
            .iport_weight_all(iport_weight_all),
            .oports_weight_all(oports_weight_all)
            
        ); 
        
        weights_update #(
            .ARBITER_TYPE(SWA_ARBITER_TYPE),
        	.V(V),
        	.P(P),
        	.Fpay(Fpay),
        	.WEIGHTw(WEIGHTw),
        	.WRRA_CONFIG_INDEX(0),
        	.C(C),
        	.ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        	.CLASS_HDR_WIDTH(CLASS_HDR_WIDTH),
        	.ROUTING_HDR_WIDTH(ROUTING_HDR_WIDTH),
        	.DST_ADR_HDR_WIDTH(DST_ADR_HDR_WIDTH),
        	.SRC_ADR_HDR_WIDTH(SRC_ADR_HDR_WIDTH)
        )
        updater
        (
        	.limited_oports_weight(limited_oport_weight_all),
        	.refresh_w_counter(refresh_w_counter),
        	.iport_weight_all(iport_weight_all),
        	.contention_all(contention_all),
        	.flit_in_all(cross_bar_flit_out_all),
        	.flit_out_all(flit_out_all),
        	.flit_out_we_all(flit_out_we_all),
        	.clk(clk),
        	.reset(reset)
        );        
         
    end // WRRA
    else begin : rra_arb
    
        assign flit_out_all  =  cross_bar_flit_out_all;  
    
    end
    endgenerate 
     
    
    //synthesis translate_off 
    //synopsys  translate_off
    localparam     EAST = 1,
                NORTH = 2,
                WEST = 3,
                SOUTH = 4;

    generate 
    if(DEBUG_EN)begin :dbg
        /* verilator lint_off WIDTH */ 
        if(TOPOLOGY == "MESH")begin
        /* verilator lint_on WIDTH */ 
            always @(posedge clk) begin 
           
                if(current_x == {Xw{1'b0}}         && flit_out_we_all[WEST]) $display ( "%t\t   Error: a packet is going to the WEST in a router located in first column in mesh topology %m",$time ); 
                if(current_x == NX-1     && flit_out_we_all[EAST]) $display ( "%t\t   Error: a packet is going to the EAST in a router located in last column in mesh topology %m",$time ); 
                if(current_y == {Yw{1'b0}}         && flit_out_we_all[NORTH])$display ( "%t\t  Error: a packet is going to the NORTH in a router located in first row in mesh topology %m",$time ); 
                if(current_y == NY-1    && flit_out_we_all[SOUTH])$display ( "%t\t  Error: a packet is going to the SOUTH in a router located in last row in mesh topology %b  %m",$time,flit_out_all[(SOUTH+1)*Fw-1 : SOUTH*Fw] ); 
            
            
            end//always
        end////MESH 
    end// DEBUG
    endgenerate
    
   
    
    /*
    // for testing the route path
    reg tt;
    always @(posedge clk) begin
        if(reset) tt<=0;
        else begin 
            if(flit_in_we_all>0 && tt==0)begin 
                $display("%t : x=%d,Y=%d",$time,current_x,current_y);
                tt<=1;
            end
        end
    end
    */
    /*
    reg [10 :  0]  counter;
    reg [31 :  0]  flit_counter;
    
    always @(posedge clk or posedge reset) begin
        if(reset) begin 
            flit_counter <=0;
            counter <= 0;
        end else begin 
            if(flit_in_we_all>0 )begin 
                counter <=0;
                flit_counter<=flit_counter+1'b1;
                          
            end else begin 
                counter <= counter+1'b1;
                if( counter == 512 ) $display("%t : total flits received in (x=%d,Y=%d) is %d ",$time,current_x,current_y,flit_counter);
            end
        end
    end
    */
//synopsys  translate_on
//synthesis translate_on 


endmodule

