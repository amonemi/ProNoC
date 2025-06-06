`include "pronoc_def.v"
/**********************************************************************
**    File: mesh_torus.v
**    
**    Copyright (C) 2014-2017  Alireza Monemi
**    
**    This file is part of ProNoC 
**
**    ProNoC ( stands for Prototype Network-on-chip)  is free software: 
**    you can redistribute it and/or modify it under the terms of the GNU
**    Lesser General Public License as published by the Free Software Foundation,
**    either version 2 of the License, or (at your option) any later version.
**
**     ProNoC is distributed in the hope that it will be useful, but WITHOUT
**     ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
**     or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General
**     Public License for more details.
**
**     You should have received a copy of the GNU Lesser General Public
**     License along with ProNoC. If not, see <http:**www.gnu.org/licenses/>.
**
**
**    Description: 
**        
**
***************************************/


/**************************
*        pre-sel[xy]
*            y
*        1   |   3
*        ---------x
*        0   |   2
***************************/
module  mesh_torus_vc_alloc_request_gen_adaptive #(
    parameter ROUTE_TYPE = "FULL_ADAPTIVE",    // "FULL_ADAPTIVE", "PAR_ADAPTIVE"  
    parameter V = 4,
    parameter DSTPw=4,
    parameter SSA_EN = 0,
    parameter PPSw=4,
    parameter [V-1 : 0] ESCAP_VC_MASK = 4'b1000   // mask scape vc, valid only for full adaptive       
)(
    ovc_avalable_all,
    dest_port_coded_all,
    candidate_ovc_all,
    ivc_request_all,
    ovc_is_assigned_all,
    masked_ovc_request_all,
    port_pre_sel,
    swap_port_presel,
    destport_clear_all,
    ivc_num_getting_ovc_grant, 
    ssa_ivc_num_getting_ovc_grant_all,
    sel,
    reset,
    clk    
);
    localparam  
        P = 5,
        P_1 = P-1,
        PV = V * P,
        PVV = PV * V,
        VP_1 = V * P_1,
        PVDSTPw = PV * DSTPw;
        
    localparam 
        LOCAL = 3'd0,  
        EAST = 3'd1, 
        NORTH = 3'd2,  
        WEST = 3'd3,  
        SOUTH = 3'd4;  

    input   [PV-1 : 0]  ovc_avalable_all;
    input   [PVDSTPw-1 : 0]  dest_port_coded_all;
    input   [PV-1 : 0]  ivc_request_all;
    input   [PV-1 : 0]  ovc_is_assigned_all;  
    output  [PVV-1 : 0]  masked_ovc_request_all;
    input   [PVV-1 : 0]  candidate_ovc_all;
    input   [PPSw-1 : 0]  port_pre_sel;
    output  [PV-1 : 0]  swap_port_presel;   
    output  [PV-1 : 0]  sel;
    output  [PVDSTPw-1 : 0] destport_clear_all;
    input   [PV-1 : 0] ivc_num_getting_ovc_grant; 
    input   [PV-1 : 0] ssa_ivc_num_getting_ovc_grant_all;       
    input                       reset,clk;  
    
    
    wire    [PV-1 : 0]  non_assigned_ovc_request_all; 
    wire    [PV-1 : 0]  y_evc_forbiden,x_evc_forbiden;
    wire    [V-1 : 0]  ovc_avb_x_plus,ovc_avb_x_minus,ovc_avb_y_plus,ovc_avb_y_minus,ovc_avb_local;
    wire    [VP_1-1 : 0]  ovc_avalable_perport            [P-1 : 0];
    wire    [PPSw-1 : 0]  port_pre_sel_perport            [P-1 : 0];
    wire    [PVV-1 : 0]  candidate_ovc_x_all, candidate_ovc_y_all;
    
    
    assign non_assigned_ovc_request_all = ivc_request_all & ~ovc_is_assigned_all;   
    assign {ovc_avb_y_minus,ovc_avb_x_minus,ovc_avb_y_plus,ovc_avb_x_plus,ovc_avb_local} = ovc_avalable_all;
    assign ovc_avalable_perport[LOCAL] = {ovc_avb_x_plus,ovc_avb_x_minus,ovc_avb_y_plus,ovc_avb_y_minus};
    assign ovc_avalable_perport[EAST] = {ovc_avb_local,ovc_avb_x_minus,ovc_avb_y_plus,ovc_avb_y_minus};
    assign ovc_avalable_perport[NORTH] = {ovc_avb_x_plus,ovc_avb_x_minus,ovc_avb_local,ovc_avb_y_minus};
    assign ovc_avalable_perport[WEST] = {ovc_avb_x_plus,ovc_avb_local,ovc_avb_y_plus,ovc_avb_y_minus};
    assign ovc_avalable_perport[SOUTH] = {ovc_avb_x_plus,ovc_avb_x_minus,ovc_avb_y_plus,ovc_avb_local};
    assign port_pre_sel_perport[LOCAL] = port_pre_sel;
    assign port_pre_sel_perport[EAST] = {2'b00,port_pre_sel[1:0]};
    assign port_pre_sel_perport[NORTH] = {1'b0,port_pre_sel[2],1'b0,port_pre_sel[0]};
    assign port_pre_sel_perport[WEST] = {port_pre_sel[3:2],2'b0};
    assign port_pre_sel_perport[SOUTH] = {port_pre_sel[3],1'b0,port_pre_sel[1],1'b0};
    
    wire    [PV-1 : 0]  avc_unavailable; 
    genvar i;
    generate   
    for(i=0;i< PV;i=i+1) begin : PV_
        mesh_torus_adaptive_avb_ovc_mux #(
            .V(V)           
        ) ovc_mux (
            .ovc_avalable               (ovc_avalable_perport   [i/V]),
            .sel                        (sel                    [i]),
            .candidate_ovc_x            (candidate_ovc_x_all    [((i+1)*V)-1 : i*V]),
            .candidate_ovc_y            (candidate_ovc_y_all    [((i+1)*V)-1 : i*V]),
            .non_assigned_ovc_request   (non_assigned_ovc_request_all[i]),
            .xydir                      (dest_port_coded_all     [((i+1)*DSTPw)-1 : ((i+1)*DSTPw)-2]),
            .masked_ovc_request         (masked_ovc_request_all [((i+1)*V)-1 : i*V])
        );
        
        mesh_torus_port_selector #(
            .SW_LOC     (i/V),
            .PPSw(PPSw)
        ) the_portsel (
            .port_pre_sel       (port_pre_sel_perport[i/V]),
            .swap_port_presel   (swap_port_presel[i]),
            .sel                (sel[i]),
            .dest_port_in       (dest_port_coded_all[((i+1)*DSTPw)-1 : i*DSTPw]),
            .y_evc_forbiden     (y_evc_forbiden[i]),
            .x_evc_forbiden     (x_evc_forbiden[i])
        );
        
        mesh_tori_dspt_clear_gen #(
            .SSA_EN(SSA_EN),
            .DSTPw(DSTPw),
            .SW_LOC(i/V)
        ) dspt_clear_gen (
            .destport_clear(destport_clear_all[((i+1)*DSTPw)-1 : i*DSTPw]),
            .ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant[i]),
            .sel(sel[i]),
            .ssa_ivc_num_getting_ovc_grant(ssa_ivc_num_getting_ovc_grant_all[i])
        );                              
        
        /* verilator lint_off WIDTH */   
        if(ROUTE_TYPE == "FULL_ADAPTIVE") begin: full_adpt
        /* verilator lint_on WIDTH */ 
            assign candidate_ovc_y_all[((i+1)*V)-1 : i*V] = (y_evc_forbiden[i]) ? candidate_ovc_all[((i+1)*V)-1 : i*V] & (~ESCAP_VC_MASK) : candidate_ovc_all[((i+1)*V)-1 : i*V];
            assign candidate_ovc_x_all[((i+1)*V)-1 : i*V] = (x_evc_forbiden[i]) ? candidate_ovc_all[((i+1)*V)-1 : i*V] & (~ESCAP_VC_MASK) : candidate_ovc_all[((i+1)*V)-1 : i*V];
            assign avc_unavailable[i] = (masked_ovc_request_all [((i+1)*V)-1 : i*V] & ~ESCAP_VC_MASK) == {V{1'b0}};
            
            mesh_torus_swap_port_presel_gen #(
                .V(V),
                .ESCAP_VC_MASK(ESCAP_VC_MASK),       
                .VC_NUM(i)
            ) swap_presel (
                .avc_unavailable(avc_unavailable[i]),
                .y_evc_forbiden(y_evc_forbiden[i]),
                .x_evc_forbiden(x_evc_forbiden[i]),
                .non_assigned_ovc_request(non_assigned_ovc_request_all[i]),
                .sel(sel[i]),
                .clk(clk),
                .reset(reset),
                .swap_port_presel(swap_port_presel[i])
            );
        end else begin : partial_adpt
            assign candidate_ovc_y_all[((i+1)*V)-1 : i*V] = candidate_ovc_all [((i+1)*V)-1 : i*V];
            assign candidate_ovc_x_all[((i+1)*V)-1 : i*V] = candidate_ovc_all [((i+1)*V)-1 : i*V];
            assign swap_port_presel[i]=1'b0;
            assign avc_unavailable[i]=1'b0;
        end// ROUTE_TYPE
    end//for    
endgenerate
endmodule


module mesh_tori_dspt_clear_gen #(
    parameter SSA_EN = 1,
    parameter DSTPw =4,
    parameter SW_LOC=0
)(
    destport_clear,
    ivc_num_getting_ovc_grant,
    sel,
    ssa_ivc_num_getting_ovc_grant
);
    
    output [DSTPw-1 : 0] destport_clear;
    input ivc_num_getting_ovc_grant;
    input sel;
    input ssa_ivc_num_getting_ovc_grant;
    
    localparam 
        LOCAL = 3'd0,
        EAST = 3'd1,
        WEST = 3'd3;
    generate
    if ( SSA_EN==1 ) begin :predict_if
        if (SW_LOC == LOCAL ) begin :local_if
            assign destport_clear= (ivc_num_getting_ovc_grant)?{2'b00,sel,~sel} :{DSTPw{1'b0}};                  
        end else if (SW_LOC == EAST || SW_LOC == WEST ) begin :xdir_if
            assign destport_clear = (ivc_num_getting_ovc_grant)? 
                {2'b00,sel,~sel} : 
                (ssa_ivc_num_getting_ovc_grant)? 4'b0001: //clear b
                4'b0000;
        end else begin : ydir_if
            assign destport_clear = (ivc_num_getting_ovc_grant)? 
                {2'b00,sel,~sel} :
                (ssa_ivc_num_getting_ovc_grant)? 4'b0010: //clear a
                4'b0000;
        end
        end else begin :nopredict_if 
            assign destport_clear = (ivc_num_getting_ovc_grant )? {2'b00,sel,~sel} :{DSTPw{1'b0}}; 
        end//   nopredict_if
    endgenerate
endmodule


module   mesh_torus_mask_non_assignable_destport #(
    parameter TOPOLOGY="MESH",
    parameter ROUTE_NAME="XY",
    parameter SW_LOC=0,
    parameter P=5,
    parameter SELF_LOOP_EN=0
) (
    odd_column,// use only for odd even routing
    dest_port_in,
    dest_port_out
);
    
    localparam P_1 = (SELF_LOOP_EN )?  P : P-1;
    input  [P_1-1 : 0 ] dest_port_in;
    output [P_1-1 : 0 ] dest_port_out;
    input odd_column;
    
    wire  [P-2 : 0] dest_port_in_tmp,dest_port_out_tmp;
    generate 
    if(SELF_LOOP_EN == 0) begin :nslp
        assign dest_port_in_tmp = dest_port_in;
        assign dest_port_out = dest_port_out_tmp;
    end else begin :slp
        remove_sw_loc_one_hot #(
            .P(P),
            .SW_LOC(SW_LOC)
        ) remove_sw_loc (
            .destport_in(dest_port_in),
            .destport_out(dest_port_in_tmp)
        );
        //currently loop-back only can happen in local ports. 
        //Current supported routing algorithms does not results in loop-back in other ports
        wire sw_loc_val = (SW_LOC>0 && SW_LOC<5) ? 1'b0 : dest_port_in [SW_LOC];
        
        add_sw_loc_one_hot_val #(
            .P(P),
            .SW_LOC(SW_LOC)
        )add_sw_loc (
            .sw_loc_val(sw_loc_val),
            .destport_in (dest_port_out_tmp),
            .destport_out(dest_port_out)
        );
    end    
    endgenerate
    
    mesh_torus_mask_non_assignable_destport_no_self_loop # (
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),
        .SW_LOC(SW_LOC),
        .P(P)    
    ) mask_no_self_loop (
        .dest_port_in(dest_port_in_tmp),
        .dest_port_out(dest_port_out_tmp),
        .odd_column(odd_column)
    );
endmodule

module mesh_torus_mask_non_assignable_destport_no_self_loop #(
    parameter TOPOLOGY="MESH",
    parameter ROUTE_NAME="XY",
    parameter SW_LOC=0,
    parameter P=5
)(
    odd_column,// use only for odd even routing
    dest_port_in,
    dest_port_out
);
    
    localparam
        EAST = 1, 
        NORTH = 2, 
        WEST = 3,
        SOUTH = 4; 
    //port number in north port 
    localparam 
        N_LOCAL = 0, 
        N_EAST = 1, 
        N_WEST = 2,  
        N_SOUTH = 3; 
    // port number in south port   
    localparam
        S_LOCAL = 0, 
        S_EAST = 1, 
        S_NORTH = 2,  
        S_WEST = 3;
    // port number in east port   
    localparam
        E_LOCAL = 0, 
        E_NORTH = 1,  
        E_WEST = 2,  
        E_SOUTH = 3; 
    // port number in east port   
    localparam
        W_LOCAL = 0,
        W_EAST = 1, 
        W_NORTH = 2,  
        W_SOUTH = 3;   
    localparam 
        P_1 = P-1;
    input [P_1-1 : 0 ] dest_port_in;
    output [P_1-1 : 0 ] dest_port_out;
    input odd_column;
    
    generate    
    /* verilator lint_off WIDTH */ 
    if (TOPOLOGY == "RING" || TOPOLOGY == "LINE") begin : oneD // A port can send packets to all other ports in these topologies
    /* verilator lint_on WIDTH */ 
        assign  dest_port_out = dest_port_in;    
    end else begin : towD
        if(P>5)begin :p5
            assign dest_port_out[P_1-1:4] = dest_port_in[P_1-1:4]; //other local ports
        end    
        /* verilator lint_off WIDTH */ 
        if ( ROUTE_NAME == "XY" || ROUTE_NAME == "TRANC_XY") begin :xy
        /* verilator lint_on WIDTH */ 
            if (SW_LOC == NORTH  ) begin : nort_p // The port located in y axsis does not send packets to x dimension
                assign dest_port_out[N_LOCAL]= dest_port_in[N_LOCAL]; 
                assign dest_port_out[N_EAST]= 1'b0; // mask east port
                assign dest_port_out[N_WEST]= 1'b0; // mask west port   
                assign dest_port_out[N_SOUTH]= dest_port_in[N_SOUTH];                              
            end else if ( SW_LOC == SOUTH) begin : south_p
                assign dest_port_out[S_LOCAL]= dest_port_in[S_LOCAL]; 
                assign dest_port_out[S_EAST]= 1'b0; // mask east port
                assign dest_port_out[S_NORTH]= dest_port_in[S_NORTH]; 
                assign dest_port_out[S_WEST]= 1'b0; // mask west port                                
            end else begin : non_vertical
                assign  dest_port_out[3:0] = dest_port_in[3:0];             
            end
        /* verilator lint_off WIDTH */ 
        end else  if ( ROUTE_NAME == "WEST_FIRST" || ROUTE_NAME == "TRANC_WEST_FIRST") begin :west_first
        /* verilator lint_on WIDTH */ 
        // SW &  NW are forbidden 
            if (SW_LOC == NORTH  ) begin : nort_p // north port does not send packets to the west port. 
                assign dest_port_out[N_LOCAL]= dest_port_in[N_LOCAL]; 
                assign dest_port_out[N_EAST]= dest_port_in[N_EAST]; 
                assign dest_port_out[N_WEST]= 1'b0; // mask west port   
                assign dest_port_out[N_SOUTH]= dest_port_in[N_SOUTH];                       
            end else if ( SW_LOC == SOUTH) begin : south_p // south port does not sends packet to west
                assign dest_port_out[S_LOCAL]= dest_port_in[S_LOCAL]; 
                assign dest_port_out[S_EAST]= dest_port_in[S_EAST]; 
                assign dest_port_out[S_NORTH]= dest_port_in[S_NORTH]; 
                assign dest_port_out[S_WEST]= 1'b0; // mask west port                                  
            end else begin : non_vertical
                assign  dest_port_out[3:0] = dest_port_in[3:0];             
            end        
        /* verilator lint_off WIDTH */ 
        end else  if ( ROUTE_NAME == "NORTH_LAST" || ROUTE_NAME == "TRANC_NORTH_LAST") begin :north_last
        /* verilator lint_on WIDTH */ 
            //NE & NW are forbidden
            if (SW_LOC == SOUTH  ) begin : south_p // north port does not send packets to the east nor to the west port. 
                assign dest_port_out[S_LOCAL]= dest_port_in[S_LOCAL]; 
                assign dest_port_out[S_EAST]= 1'b0; // mask east port
                assign dest_port_out[S_WEST]= 1'b0; // mask west port   
                assign dest_port_out[S_NORTH]= dest_port_in[S_NORTH];                       
            end else begin : other_p
                assign  dest_port_out[3:0] = dest_port_in[3:0];             
            end        
        /* verilator lint_off WIDTH */     
        end else  if ( ROUTE_NAME == "NEGETIVE_FIRST" || ROUTE_NAME == "TRANC_NEGETIVE_FIRST") begin :negetive_first
        /* verilator lint_on WIDTH */ 
            //ES & NW is forbiden
            if (SW_LOC == SOUTH  ) begin : south_p // south port does not send packets to the west port. NW is forbiden
                assign dest_port_out[S_LOCAL]= dest_port_in[S_LOCAL]; 
                assign dest_port_out[S_EAST]= dest_port_in[S_EAST]; 
                assign dest_port_out[S_WEST]= 1'b0; // mask west port   
                assign dest_port_out[S_NORTH]= dest_port_in[S_NORTH];                                       
            end else if ( SW_LOC == WEST) begin : west_p // west port does not sends packet to south. ES is forbiden
                assign dest_port_out[W_LOCAL]= dest_port_in[W_LOCAL]; 
                assign dest_port_out[W_NORTH]= dest_port_in[W_NORTH]; 
                assign dest_port_out[W_EAST] = dest_port_in[W_EAST]; 
                assign dest_port_out[W_SOUTH]= 1'b0; //mask south port
            end else begin : other_p
                assign  dest_port_out[3:0] = dest_port_in[3:0];             
            end  
        /* verilator lint_off WIDTH */ 
        end else  if ( ROUTE_NAME == "ODD_EVEN" ) begin : odd_even   
        /* verilator lint_on WIDTH */ 
        //Odd column : NW and SW turns are not allowed
        //Even column: EN and ES turns are not allowed
           if (SW_LOC == NORTH  ) begin : nort_p // north port does not send packets to the west port in odd columns. SW is forbiden
                assign dest_port_out[N_LOCAL]= dest_port_in[N_LOCAL]; 
                assign dest_port_out[N_EAST]= dest_port_in[N_EAST]; 
                assign dest_port_out[N_WEST]= (odd_column)? 1'b0: dest_port_in[N_WEST];  // mask west port in odd columns 
                assign dest_port_out[N_SOUTH]= dest_port_in[N_SOUTH];          
             end else if (SW_LOC == SOUTH) begin : south_p // south port does not sends packet to west in odd columns. NW is forbiden
                assign dest_port_out[S_LOCAL]= dest_port_in[S_LOCAL]; 
                assign dest_port_out[S_EAST]= dest_port_in[S_EAST]; 
                assign dest_port_out[S_NORTH]= dest_port_in[S_NORTH]; 
                assign dest_port_out[S_WEST]= (odd_column)? 1'b0: dest_port_in[S_WEST];  // mask west port   in odd columns 
           end else if (SW_LOC == WEST) begin : west_p // WEST port does not sends packet to north and south ports in even columns
            //ES & EN forbiden 
                assign dest_port_out[W_LOCAL]= dest_port_in[W_LOCAL]; 
                assign dest_port_out[W_NORTH]= (odd_column)?   dest_port_in[W_NORTH] : 1'b0; //mask north in even columns
                assign dest_port_out[W_EAST] = dest_port_in[W_EAST]; 
                assign dest_port_out[W_SOUTH]= (odd_column)? dest_port_in[W_SOUTH] : 1'b0; //mask south in even columns
            end else begin: other_p
                assign  dest_port_out[3:0] = dest_port_in[3:0]; 
            end
        end else begin : f_adptv
                assign  dest_port_out[3:0] = dest_port_in[3:0];               
        end
    end
    endgenerate
endmodule


module  mesh_torus_swap_port_presel_gen #(
    parameter V = 4,
    parameter [V-1 : 0] ESCAP_VC_MASK = 4'b1000,   // mask scape vc, valid only for full adaptive       
    parameter VC_NUM=0
)(
    avc_unavailable,
    swap_port_presel,
    y_evc_forbiden,
    x_evc_forbiden,
    non_assigned_ovc_request,
    sel,
    clk,
    reset
);
    
    localparam LOCAL_VC_NUM= VC_NUM % V;    
    input avc_unavailable;
    input y_evc_forbiden,x_evc_forbiden;
    input non_assigned_ovc_request,sel;
    input clk,reset;
    output swap_port_presel;
    
    wire swap_reg;
    wire swap_port_presel_next;
    wire  evc_forbiden; 
    /************************
    *            
    *    destination-port_in
    *        x: 1 EAST, 0 WEST  
    *        y: 1 NORTH, 0 SOUTH
    *        ab: 00 : LOCAL, 10: xdir, 01: ydir, 11 x&y dir 
    *    sel:
    *         0: xdir
    *         1: ydir
    *    port_pre_sel
    *         0: xdir
    *         1: ydir  
    ************************/
    //For an EVC sender, if the use of EVC in destination port is restricted while the destination port has no available AVC,
    //the port pre selection must swap 
    assign  evc_forbiden = (sel)? y_evc_forbiden : x_evc_forbiden;
    assign  swap_port_presel_next= non_assigned_ovc_request & evc_forbiden & avc_unavailable;
    assign swap_port_presel = swap_reg;
    pronoc_register #(.W(1)) reg2 (.D_in(swap_port_presel_next ), .Q_out(swap_reg), .reset(reset), .clk(clk));
endmodule


module  mesh_torus_adaptive_avb_ovc_mux #(
    parameter V= 4
)(
    ovc_avalable,
    sel,
    candidate_ovc_x, 
    candidate_ovc_y,
    non_assigned_ovc_request,
    xydir,
    masked_ovc_request
);
    localparam
        P = 5,
        P_1 = P-1,
        VP_1 = V  *  P_1;
        
    input   [VP_1-1 :  0] ovc_avalable;
    input   sel;
    input   [V-1 :  0] candidate_ovc_x;
    input   [V-1 :  0] candidate_ovc_y;
    input   non_assigned_ovc_request;
    input   [1 :  0] xydir;
    output  [V-1 : 0] masked_ovc_request;
    wire    x,y;
    wire    [V-1 : 0] ovc_avb_x_plus,ovc_avb_x_minus,ovc_avb_y_plus,ovc_avb_y_minus;
    wire    [V-1 : 0] mux_out_x,mux_out_y;
    wire    [V-1 : 0] ovc_request_x,ovc_request_y,masked_ovc_request_x,masked_ovc_request_y;
    
    assign {x,y}= xydir;
    assign {ovc_avb_x_plus,ovc_avb_x_minus,ovc_avb_y_plus,ovc_avb_y_minus}=ovc_avalable;
    //first level mux
    //assign mux_out_x = (x)?  ovc_avb_x_plus : ovc_avb_x_minus;
    //assign mux_out_y = (y)?  ovc_avb_y_plus : ovc_avb_y_minus;
    assign mux_out_x = (ovc_avb_x_plus &{V{x}}) |  (ovc_avb_x_minus &{V{~x}});
    assign mux_out_y = (ovc_avb_y_plus &{V{y}}) |  (ovc_avb_y_minus &{V{~y}});
    //assign ovc_request_x = (non_assigned_ovc_request)? candidate_ovc_x : {V{1'b0}};
    //assign ovc_request_y = (non_assigned_ovc_request)? candidate_ovc_y : {V{1'b0}};
    assign ovc_request_x = candidate_ovc_x & {V{non_assigned_ovc_request}};
    assign ovc_request_y = candidate_ovc_y & {V{non_assigned_ovc_request}};
    //mask unavailble ovc
    assign masked_ovc_request_x = mux_out_x & ovc_request_x;
    assign masked_ovc_request_y = mux_out_y & ovc_request_y;
    //second mux 
    // assign masked_ovc_request = (sel)?  masked_ovc_request_y: masked_ovc_request_x;
    assign masked_ovc_request = (masked_ovc_request_y & {V{sel}})| (masked_ovc_request_x & {V{~sel}});
endmodule


module mesh_torus_port_selector #(
    parameter SW_LOC = 0,
    parameter PPSw=4
)(
    port_pre_sel,
    dest_port_in,
    swap_port_presel,
    sel,
    y_evc_forbiden,
    x_evc_forbiden
);

    /************************
    *
    *        destination-port_in
    *            x: 1 EAST, 0 WEST  
    *            y: 1 NORTH, 0 SOUTH
    *            ab: 00 : LOCAL, 10: xdir, 01: ydir, 11 x&y dir 
    *        sel:
    *             0: xdir
    *             1: ydir
    *        port_pre_sel
    *             0: xdir
    *             1: ydir  
    ************************/
    //input           reset,clk;
    input   [PPSw-1:0]   port_pre_sel;
    // input           port_pre_sel_ld;
    output          sel;
    input   [3:0]   dest_port_in;
    input           swap_port_presel;
    // output          route_subfunc_violated;
    output          y_evc_forbiden, x_evc_forbiden;
    
    wire  x,y,a,b;
    wire [PPSw-1:0] port_pre_sel_final;
    //reg  [3:0] port_pre_sel_delayed , port_pre_sel_latched;
    //  wire o1,o2;
    localparam 
        LOCAL = 0,  
        EAST = 1, 
        NORTH = 2,  
        WEST = 3,  
        SOUTH = 4;  
    localparam 
        LOCAL_SEL = (SW_LOC == NORTH || SW_LOC == SOUTH )? 1'b1 : 1'b0; 
    assign port_pre_sel_final= (swap_port_presel)? ~port_pre_sel: port_pre_sel;   
    assign {x,y,a,b} = dest_port_in;
    wire sel_in,sel_pre, overwrite;
    wire [1:0] xy;
    assign xy={x,y};
    assign sel_pre= port_pre_sel_final[xy];
    assign overwrite= a&b;
    generate 
    if(LOCAL_SEL)begin :local_p
        assign sel_in= b | ~a; 
    end else begin :nonlocal_p
        assign sel_in= b ;    
    end
    endgenerate
    assign sel= (overwrite)? sel_pre : sel_in;
    // check if EVC is allowed to be used     
    // Using of all EVCs located in y dimension are restricted when the packet can be sent into both x&y direction 
    assign y_evc_forbiden = a&b;
    //there is no restriction in using EVCs located in x dimension
    assign x_evc_forbiden = 1'b0; 
    //assign route_subfunc_violated = a&b;
endmodule


/*******************
*    mesh_torus_adaptive_lk_dest_encoder
********************/    
module  mesh_torus_adaptive_lk_dest_encoder #(
    parameter V=4,
    parameter P=5,
    parameter DSTPw=P-1,
    parameter Fw=37,
    parameter DST_P_MSB=11, 
    parameter DST_P_LSB=8
)(
    sel,
    flit_in,
    dest_coded_out,
    vc_num_delayed,
    lk_dest
);
    
    input [V-1 : 0]  sel;
    output [DSTPw-1 : 0]dest_coded_out;
    input [V-1 : 0]  vc_num_delayed;
    input [DSTPw-1 : 0]  lk_dest;
    input [Fw-1 : 0]  flit_in;
    
    wire [1 : 0]  ab,xy;
    wire sel_muxed;
    
    onehot_mux_1D #(
        .W(1),
        .N(V) 
    ) sel_mux (
        .D_in(sel),
        .Q_out(sel_muxed),
        .sel(vc_num_delayed)
    );
    
    //lkdestport = {lkdestport_x[1:0],lkdestport_y[1:0]};
    // sel: 0: xdir     1: ydir
    assign ab = (sel_muxed)? lk_dest[1:0] : lk_dest[3:2];
    //if ab==00 change x and y direction
    assign xy = (ab>0)? flit_in[DST_P_MSB : DST_P_LSB+2] : ~flit_in[DST_P_MSB : DST_P_LSB+2] ;
    assign dest_coded_out={xy,ab};
endmodule


module  mesh_torus_dtrmn_dest_encoder #(
    parameter P=5,
    parameter DSTPw=P-1,
    parameter Fw=37,
    parameter DST_P_MSB=11, 
    parameter DST_P_LSB=8
)(
    flit_in,
    dest_coded_out,
    lk_dest
);
    output [DSTPw-1 : 0]dest_coded_out;
    input [DSTPw-1 : 0]  lk_dest;
    input [Fw-1 : 0]  flit_in;
    wire [1 : 0]  ab,xy;
    //lkdestport = {lkdestport_x[1:0],lkdestport_y[1:0]};
    // sel: 0: xdir     1: ydir
    assign ab = lk_dest[1:0];
    //if ab==00 change x and y direction
    assign xy = (ab>0)? flit_in[DST_P_MSB : DST_P_LSB+2] : ~flit_in[DST_P_MSB : DST_P_LSB+2] ;
    assign dest_coded_out={xy,ab};
endmodule

/********************
*    distance_gen 
********************/
module mesh_torus_distance_gen (
    src_e_addr,
    dest_e_addr,
    distance
);
    `NOC_CONF
    
    localparam 
        NYY =(IS_RING | IS_LINE )? 1 : T2,
        Xw = log2(T1),   // number of node in x axis
        Yw = log2(NYY);    // number of node in y axis 
    localparam [Xw : 0] NX = T1;
    localparam [Yw : 0] NY = NYY [Yw : 0];
    
    input [EAw-1 : 0] src_e_addr;
    input [EAw-1 : 0] dest_e_addr;               
    output[DISTw-1: 0]distance;                     
    wire [Xw-1 : 0]src_x,dest_x;
    wire [Yw-1 : 0]src_y,dest_y;
    mesh_tori_endp_addr_decode #(
        .TOPOLOGY(TOPOLOGY),
        .T1(T1),
        .T2(NYY),
        .T3(T3),
        .EAw(EAw)
    ) src_addr_decode (
        .e_addr(src_e_addr),
        .ex(src_x),
        .ey(src_y),
        .el(),
        .valid()
    );
    
    mesh_tori_endp_addr_decode #(
        .TOPOLOGY(TOPOLOGY),
        .T1(T1),
        .T2(NYY),
        .T3(T3),
        .EAw(EAw)
    ) dest_addr_decode (
        .e_addr(dest_e_addr),
        .ex(dest_x),
        .ey(dest_y),
        .el(),
        .valid()
    );
    
    reg [Xw-1 : 0] x_offset;
    reg [Yw-1 : 0] y_offset;
    generate 
    if( IS_MESH | IS_LINE) begin : oneD
        always_comb begin 
            x_offset = (src_x> dest_x)? src_x - dest_x : dest_x - src_x;
            y_offset = (src_y> dest_y)? src_y - dest_y : dest_y - src_y;
        end
    end else begin : twoD //torus ring
        wire tranc_x_plus,tranc_x_min,tranc_y_plus,tranc_y_min,same_x,same_y;
        /* verilator lint_off WIDTH */
        always_comb begin 
            x_offset= {Xw{1'b0}};
            y_offset= {Yw{1'b0}};
            //x_offset
            if(same_x) x_offset= {Xw{1'b0}};
            else if(tranc_x_plus) begin 
                if(dest_x   > src_x)    x_offset= dest_x-src_x; 
                else                    x_offset= (NX-src_x)+dest_x;
            end
            else if(tranc_x_min)  begin 
                if(dest_x   <  src_x)    x_offset= src_x-dest_x; 
                else                     x_offset= src_x+(NX-dest_x);
            end
            //y_offset
            if(same_y) y_offset= {Yw{1'b0}};
            else if(tranc_y_plus) begin 
                if(dest_y   > src_y)    y_offset= dest_y-src_y; 
                else                    y_offset= (NY-src_y)+dest_y;
            end
            else if(tranc_y_min)  begin 
                if(dest_y   <  src_y)    y_offset= src_y-dest_y; 
                else                     y_offset= src_y+(NY-dest_y);
            end
        end      
        /* verilator lint_on WIDTH */
        
        tranc_dir #(
            .NX(NX),
            .NY(NY)
        ) tranc_dir (
            .tranc_x_plus(tranc_x_plus),
            .tranc_x_min(tranc_x_min),
            .tranc_y_plus(tranc_y_plus),
            .tranc_y_min(tranc_y_min),
            .same_x(same_x),
            .same_y(same_y),
            .current_x(src_x),
            .current_y(src_y),
            .dest_x(dest_x),
            .dest_y(dest_y)
        );
    end    
    endgenerate
    /* verilator lint_off WIDTH */ 
    assign distance = x_offset+y_offset+1'b1;
    /* verilator lint_on WIDTH */ 
endmodule


module mesh_torus_ssa_check_destport #(
    parameter ROUTE_TYPE="DETERMINISTIC",
    parameter SW_LOC = 0,
    parameter P=5,
    parameter DEBUG_EN = 0,
    parameter DSTPw = P-1,
    parameter SS_PORT=0
)(
    destport_encoded, //exsited packet dest port
    destport_in_encoded, // incomming packet dest port
    ss_port_hdr_flit,
    ss_port_nonhdr_flit     
    `ifdef SIMULATION 
    ,clk,
    ivc_num_getting_sw_grant,
    hdr_flg
    `endif
);

    input [DSTPw-1 : 0] destport_encoded, destport_in_encoded; 
    output ss_port_hdr_flit, ss_port_nonhdr_flit;
    `ifdef SIMULATION 
    input clk, ivc_num_getting_sw_grant,hdr_flg;
    `endif
    //MESH, TORUS Topology p=5           
    localparam   
        LOCAL = 0,  
        EAST = 1,
        WEST = 3;

/*************************
*        destination port is coded        
*        destination-port_in
*            x: 1 EAST, 0 WEST  
*            y: 1 NORTH, 0 SOUTH
*            ab: 00 : LOCAL, 10: xdir, 01: ydir, 11 x&y dir 
*        sel:
*             0: xdir
*             1: ydir
*        port_pre_sel
*             0: xdir
*             1: ydir  
*
************************/
    wire  a,b,aa,bb;
    assign {a,b} = destport_in_encoded[1:0];
    assign {aa,bb} = destport_encoded[1:0];
    generate
    if( SS_PORT == LOCAL) begin :local_p
        assign ss_port_hdr_flit = 1'b0;
        assign ss_port_nonhdr_flit = 1'b0;
    end else if ((SS_PORT == EAST) || SS_PORT == WEST )begin :xdir
        assign ss_port_hdr_flit = a;
        assign ss_port_nonhdr_flit = aa;
    end else begin :ydir
        assign ss_port_hdr_flit = b;
        assign ss_port_nonhdr_flit = bb;
    end
    `ifdef SIMULATION 
    if(DEBUG_EN) begin :dbg
        always @(posedge clk) begin
           //if(!reset)begin 
                if(ivc_num_getting_sw_grant & aa & bb & ~hdr_flg) begin 
                    $display("%t: SSA ERROR: There are two output ports that a non-header flit can be sent to. %m",$time);
                    $finish;
                end
           //end
        end 
    end //dbg
    `endif
endgenerate
endmodule


module line_ring_ssa_check_destport #(
    parameter ROUTE_TYPE="DETERMINISTIC",
    parameter SW_LOC = 0,
    parameter P=3,
    parameter DEBUG_EN = 0,
    parameter DSTPw = P-1,
    parameter SS_PORT=0
)(
    destport_encoded, //exsited packet dest port
    destport_in_encoded, // incomming packet dest port
    ss_port_hdr_flit,
    ss_port_nonhdr_flit 
);
    input [DSTPw-1 : 0] destport_encoded, destport_in_encoded; 
    output ss_port_hdr_flit, ss_port_nonhdr_flit;
    wire [P-1 : 0] dest_port_num,assigned_dest_port_num;
    
    line_ring_decode_dstport cnv1(
        .dstport_one_hot(dest_port_num),
        .dstport_encoded(destport_in_encoded)
    );
    line_ring_decode_dstport cnv2(
        .dstport_one_hot(assigned_dest_port_num),
        .dstport_encoded(destport_encoded)
    );
    
    assign ss_port_hdr_flit = dest_port_num [SS_PORT];
    assign ss_port_nonhdr_flit = assigned_dest_port_num[SS_PORT];
endmodule


module mesh_tori_router_addr_decode #(
    parameter TOPOLOGY = "MESH",
    parameter T1=4,
    parameter T2=4,
    parameter T3=4,
    parameter RAw=6
)(
    r_addr,
    rx,
    ry,
    valid
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
        NX = T1,
        NY = T2,
        RXw = log2(NX),    // number of node in x axis
        RYw = (TOPOLOGY=="RING" || TOPOLOGY == "LINE") ? 1 : log2(NY);    // number of node in y axis
    /* verilator lint_off WIDTH */ 
    localparam [RXw-1 : 0]    MAXX = (NX-1); 
    localparam [RYw-1 : 0]    MAXY = (NY-1); 
    /* verilator lint_on WIDTH */ 
    
    input  [RAw-1 : 0] r_addr;
    output [RXw-1 : 0] rx;
    output [RYw-1 : 0] ry;
    output valid;
    
    generate 
    if ((TOPOLOGY == "RING") || (TOPOLOGY == "LINE")) begin :oneD 
        assign rx = r_addr;   
        assign ry = 1'b0;
    end else begin : twoD
        assign {ry,rx} = r_addr;    
    end
    endgenerate
    /* verilator lint_off CMPCONST */
    assign valid = (rx<= MAXX ) & (ry <= MAXY);
    /* verilator lint_on CMPCONST */
endmodule


module mesh_tori_endp_addr_decode #(
    parameter TOPOLOGY = "MESH",
    parameter T1=4,
    parameter T2=4,
    parameter T3=4,
    parameter EAw=9
)(
    e_addr,
    ex,
    ey,
    el,
    valid
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
        NX = T1,
        NY = T2,
        NL = T3, 
        EXw = log2(NX),    // number of node in x axis
        EYw = (TOPOLOGY=="RING" || TOPOLOGY == "LINE")? 1 : log2(NY),
        ELw = log2(NL);    // number of node in y axis
    /* verilator lint_off WIDTH */ 
    localparam [EXw-1 : 0]    MAXX = (NX-1); 
    localparam [EYw-1 : 0]    MAXY = (NY-1); 
    localparam [ELw-1 : 0]    MAXL = (NL-1); 
    /* verilator lint_on WIDTH */ 
    
    input  [EAw-1 : 0] e_addr;
    output [EXw-1 : 0] ex;
    output [EYw-1 : 0] ey;
    output [ELw-1 : 0] el;
    output valid;
    
    generate 
    if ((TOPOLOGY == "RING") || (TOPOLOGY == "LINE")) begin :oneD 
        if(NL==1)begin:one_local 
            assign ex = e_addr;   
            assign ey = 1'b0;
            assign el = 1'b0;
            /* verilator lint_off CMPCONST */
            assign valid = ex<= MAXX;
            /* verilator lint_on CMPCONST */
        end else begin: multi_local 
            assign {el,ex} = e_addr;   
            assign ey = 1'b0;
            /* verilator lint_off CMPCONST */
            assign valid = ((ex<= MAXX) & (el<=MAXL));
            /* verilator lint_on CMPCONST */
        end
    end else begin : twoD
        if(NL==1)begin:one_local 
            assign {ey,ex} = e_addr; 
            assign el = 1'b0;  
            /* verilator lint_off CMPCONST */
            assign valid = (ex<= MAXX) & (ey <= MAXY);
            /* verilator lint_on CMPCONST */
        end else begin :multi_l
            assign {el,ey,ex} = e_addr; 
            /* verilator lint_off CMPCONST */
            assign valid = ( (ex<= MAXX) & (ey <= MAXY) & (el<=MAXL) );
            /* verilator lint_on CMPCONST */
        end
    end
    endgenerate   
endmodule


/**************
*    mesh_tori_addr_encoder
*    most probably it is only needed for simulation purposes
***************/  

module  mesh_tori_addr_encoder #(
    parameter   NX=2,
    parameter   NY=2,
    parameter   NL=2,
    parameter   NE=16,
    parameter   EAw=4,
    parameter   TOPOLOGY="MESH"
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
    
    function integer addrencode;
        input integer addr,nx,nxw,nl,nyw;
        integer  y, x, l;begin
            addrencode=0;
            y = ((addr/nl) / nx ); 
            x = ((addr/nl) % nx ); 
            l = (addr % nl);  
            addrencode =(nl==1)?   (y<<nxw | x) : (l<<(nxw+nyw)|  (y<<nxw) | x);      
        end   
    endfunction // addrencode
    
    localparam 
        NXw= log2(NX),
        NYw= (TOPOLOGY=="RING" || TOPOLOGY=="LINE")? 0 : log2(NY),
        NEw = log2(NE);    
    input [NEw-1 :0] id;
    output [EAw-1 : 0] code;
    wire [EAw-1 : 0 ] codes [NE-1 : 0];
    genvar i;
    generate 
    for(i=0; i< NE; i=i+1) begin : endpoints
        //Endpoint decoded address
        /* verilator lint_off WIDTH */
        localparam [EAw-1 : 0] ENDP= addrencode(i,NX,NXw,NL,NYw);
        /* verilator lint_on WIDTH */
        assign codes[i] = ENDP;            
    end
    endgenerate
    assign code = codes[id];
endmodule


module  mesh_tori_addr_coder #(
    parameter   TOPOLOGY = "MESH",
    parameter   NX=2,
    parameter   NY=2,
    parameter   NL=2,
    parameter   NE=16,
    parameter   EAw=4
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
    
    function integer addrencode;
        input integer addr,nx,nxw,nl,nyw;
        integer  y, x, l;begin
            addrencode=0;
            y = ((addr/nl) / nx ); 
            x = ((addr/nl) % nx ); 
            l = (addr % nl);  
            addrencode =(nl==1)?   (y<<nxw | x) : (l<<(nxw+nyw)|  (y<<nxw) | x);      
        end   
    endfunction // addrencode
        
    localparam 
        NXw= log2(NX),
        NYw= (TOPOLOGY=="RING" || TOPOLOGY=="LINE")? 0 : log2(NY),
        NEw = log2(NE);    
    output [NEw-1 :0] id;
    input [EAw-1 : 0] code;
    wire   [NEw-1 : 0]  codes   [(2**EAw)-1 : 0 ];
    genvar i;
    generate 
    for(i=0; i< NE; i=i+1) begin : endpoints
        //Endpoint decoded address
        /* verilator lint_off WIDTH */
        localparam [EAw-1 : 0] ENDP= addrencode(i,NX,NXw,NL,NYw);
        /* verilator lint_on WIDTH */
        assign codes[ENDP] = i;            
    end
    endgenerate
    assign id = codes[code];
endmodule

module mesh_torus_destp_generator #(
    parameter TOPOLOGY = "MESH",
    parameter ROUTE_NAME = "XY",  
    parameter ROUTE_TYPE = "DETERMINISTIC",
    parameter P=5,
    parameter DSTPw=4,
    parameter NL=1,
    parameter PLw=1,
    parameter PPSw=4,
    parameter SW_LOC=0,
    parameter SELF_LOOP_EN=0 
)(
    dest_port_out,
    dest_port_coded,
    endp_localp_num,
    swap_port_presel,
    port_pre_sel,
    odd_column
);
    localparam P_1 = (SELF_LOOP_EN )?  P : P-1;
    
    input  [DSTPw-1 : 0] dest_port_coded;
    input  [PLw-1 : 0] endp_localp_num;
    output [P_1-1 : 0] dest_port_out;
    input           swap_port_presel;
    input  [PPSw-1 : 0] port_pre_sel;
    input odd_column;
    
    wire [P_1-1 : 0] dest_port_in;
    
    generate 
    /* verilator lint_off WIDTH */
    if (TOPOLOGY == "RING" || TOPOLOGY == "LINE" ) begin : one_D
    /* verilator lint_on WIDTH */
        line_ring_destp_decoder #(
            .ROUTE_TYPE(ROUTE_TYPE),
            .P(P),
            .DSTPw(DSTPw),
            .NL(NL),
            .ELw(PLw),
            .PPSw(PPSw),
            .SW_LOC(SW_LOC),
            .SELF_LOOP_EN(SELF_LOOP_EN)
        ) decoder (
            .dest_port_coded(dest_port_coded),             
            .dest_port_out(dest_port_in),
            .endp_localp_num(endp_localp_num)               
        );
        
    end else begin :two_D
        mesh_torus_destp_decoder #(
            .ROUTE_TYPE(ROUTE_TYPE),
            .P(P),
            .DSTPw(DSTPw),
            .NL(NL),
            .ELw(PLw),
            .PPSw(PPSw),
            .SW_LOC(SW_LOC),
            .SELF_LOOP_EN(SELF_LOOP_EN)
        ) decoder (
            .dest_port_coded(dest_port_coded),             
            .dest_port_out(dest_port_in),
            .endp_localp_num(endp_localp_num),
            .swap_port_presel(swap_port_presel),
            .port_pre_sel(port_pre_sel)
        );
    end
    endgenerate     
    
    mesh_torus_mask_non_assignable_destport #(
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),
        .SW_LOC(SW_LOC),
        .P(P),
        .SELF_LOOP_EN(SELF_LOOP_EN)
    ) mask_destport (
        .dest_port_in(dest_port_in),
        .dest_port_out(dest_port_out),
        .odd_column(odd_column)
    ); 
endmodule

module mesh_torus_destp_decoder #(
    parameter ROUTE_TYPE="DETERMINISTIC",
    parameter P=6,
    parameter DSTPw=4,
    parameter NL=2,
    parameter ELw=1,
    parameter PPSw=4,
    parameter SW_LOC=0,
    parameter SELF_LOOP_EN=0
)(
    dest_port_coded,
    endp_localp_num,
    dest_port_out,
    swap_port_presel,
    port_pre_sel
);
    localparam P_1 = (SELF_LOOP_EN )?  P : P-1;
    input  [DSTPw-1 : 0] dest_port_coded;
    input  [ELw-1 : 0] endp_localp_num;
    output [P_1-1 : 0] dest_port_out;
    input           swap_port_presel;
    input  [PPSw-1 : 0] port_pre_sel;
    
    wire [NL-1 : 0] endp_localp_onehot;
    reg [4:0] portout;
    generate 
    if( ROUTE_TYPE == "DETERMINISTIC") begin :dtrmn
        wire x,y,a,b;
        assign {x,y,a,b} = dest_port_coded;
        always_combbegin 
            case({a,b})
                2'b10 : portout = {1'b0,~x,1'b0,x,1'b0};
                2'b01 : portout = {~y,1'b0,y,1'b0,1'b0};
                2'b00 : portout = 5'b00001;
                2'b11 : portout = {~y,1'b0,y,1'b0,1'b0}; //invalid condition in determinstic routing
            endcase
        end //always
    end else begin : adpv
        wire x,y,a,b;
        assign {x,y,a,b} = dest_port_coded;        
        wire [PPSw-1:0] port_pre_sel_final;
        assign port_pre_sel_final= (swap_port_presel)? ~port_pre_sel: port_pre_sel;
        always_combbegin 
            case({a,b})
                2'b10 : portout = {1'b0,~x,1'b0,x,1'b0};
                2'b01 : portout = {~y,1'b0,y,1'b0,1'b0};
                2'b11 : portout = (port_pre_sel_final[{x,y}])?  {~y,1'b0,y,1'b0,1'b0} : {1'b0,~x,1'b0,x,1'b0};
                2'b00 : portout = 5'b00001;
            endcase
        end //always
    end 
    if(NL==1) begin :slp
        if(SELF_LOOP_EN == 0) begin :nslp
            remove_sw_loc_one_hot #(
                .P(5),
                .SW_LOC(SW_LOC)
            ) conv (
                .destport_in(portout),
                .destport_out(dest_port_out)
            ); 
        end else begin : slp
            assign dest_port_out = portout;  
        end
    end else begin :mlp
        wire [P-1 : 0] destport_onehot;
        bin_to_one_hot #(
            .BIN_WIDTH(ELw),
            .ONE_HOT_WIDTH(NL)
        ) conv (
            .bin_code(endp_localp_num),
            .one_hot_code(endp_localp_onehot)
        );
        
        assign destport_onehot =(portout[0])? 
            { endp_localp_onehot[NL-1 : 1] ,{(P-NL){1'b0}},endp_localp_onehot[0]}: /*select local destination*/ 
            { {(NL-1){1'b0}} ,portout};
        if(SELF_LOOP_EN == 0) begin :nslp
            remove_sw_loc_one_hot #(
                .P(P),
                .SW_LOC(SW_LOC)
            ) remove_sw_loc (
                .destport_in(destport_onehot),
                .destport_out(dest_port_out)
            );
        end else begin: slp
            assign dest_port_out = destport_onehot;            
        end
    end
    endgenerate
endmodule


/**************************
* line_ring_destp_decoder 
**************************/
module line_ring_destp_decoder #(
    parameter ROUTE_TYPE="DETERMINISTIC",
    parameter P=4,
    parameter DSTPw=2,
    parameter NL=2,
    parameter ELw=1,
    parameter PPSw=4,
    parameter SW_LOC=0,
    parameter SELF_LOOP_EN= 0
)(
    dest_port_coded,
    endp_localp_num,
    dest_port_out   
);
    localparam P_1 = (SELF_LOOP_EN )?  P : P-1;
    input  [DSTPw-1 : 0] dest_port_coded;
    input  [ELw-1 : 0] endp_localp_num;
    output [P_1-1 : 0] dest_port_out;
    wire [NL-1 : 0] endp_localp_onehot;
    wire [2:0] portout;
    
    line_ring_decode_dstport decoder(
        .dstport_one_hot(portout),
        .dstport_encoded(dest_port_coded)
    );
    
    
    generate
    if(NL==1) begin :_se
        if(SELF_LOOP_EN == 0) begin :nslp
            remove_sw_loc_one_hot #(
                .P(3),
                .SW_LOC(SW_LOC)
            ) conv (
                .destport_in(portout),
                .destport_out(dest_port_out)
            ); 
        end else begin : slp 
            assign dest_port_out = portout;
        end
    end else begin :_me
        wire [P-1 : 0] destport_onehot;
    
        bin_to_one_hot #(
            .BIN_WIDTH(ELw),
            .ONE_HOT_WIDTH(NL)
        ) conv (
            .bin_code(endp_localp_num),
            .one_hot_code(endp_localp_onehot)
        );
        
        assign destport_onehot =(portout[0])? 
            { endp_localp_onehot[NL-1 : 1] ,{(P-NL){1'b0}},endp_localp_onehot[0]}: /*select local destination*/ 
            { {(NL-1){1'b0}} ,portout};
        if(SELF_LOOP_EN == 0) begin :nslp
            remove_sw_loc_one_hot #(
                .P(P),
                .SW_LOC(SW_LOC)
            ) remove_sw_loc (
                .destport_in(destport_onehot),
                .destport_out(dest_port_out)
            ); 
        end else begin :slp
            assign dest_port_out = destport_onehot;
        end
    end
    endgenerate
endmodule

/*****************
*   mesh_torus_dynamic_portsel_control
*****************/
module  mesh_torus_dynamic_portsel_control #(
    parameter  P = 5,
    parameter ROUTE_TYPE = "FULL_ADAPTIVE",    // "FULL_ADAPTIVE", "PAR_ADAPTIVE"  
    parameter V = 4,
    parameter DSTPw=4,
    parameter SSA_EN = 0, // 1: SSA enabled, 0: SSA disabled
    parameter PPSw=4,
    parameter [V-1 : 0] ESCAP_VC_MASK = 4'b1000   // mask scape vc, valid only for full adaptive       
)(   
    dest_port_coded_all,
    ivc_request_all,
    ovc_is_assigned_all,
    port_pre_sel,
    swap_port_presel,
    destport_clear_all,
    ivc_num_getting_ovc_grant, 
    ssa_ivc_num_getting_ovc_grant_all,
    masked_ovc_request_all,
    sel,
    reset,
    clk    
);
    localparam
        PV = V * P,
        PVV= PV * V,    
        PVDSTPw = PV * DSTPw;
    localparam LOCAL = 0,  
        EAST = 1, 
        NORTH = 2,  
        WEST = 3,  
            SOUTH = 4;  
    input   [PVDSTPw-1 : 0]  dest_port_coded_all;
    input   [PV-1 : 0]  ivc_request_all;
    input   [PV-1 : 0]  ovc_is_assigned_all;  
    input   [PVV-1 : 0]  masked_ovc_request_all;
    input   [PPSw-1 : 0]  port_pre_sel;
    output  [PV-1 : 0]  swap_port_presel;   
    output  [PV-1 : 0]  sel;
    output  [PVDSTPw-1 : 0] destport_clear_all;
    input   [PV-1 : 0] ivc_num_getting_ovc_grant; 
    input   [PV-1 : 0] ssa_ivc_num_getting_ovc_grant_all;       
    input                       reset,clk;  
    
    wire    [PV-1 : 0]  non_assigned_ovc_request_all; 
    wire    [PV-1 : 0]  y_evc_forbiden,x_evc_forbiden;  
    wire    [PPSw-1 : 0]  port_pre_sel_perport            [P-1 : 0];
    assign non_assigned_ovc_request_all = ivc_request_all & ~ovc_is_assigned_all;  
    assign port_pre_sel_perport[LOCAL] = port_pre_sel;
    assign port_pre_sel_perport[EAST] = {2'b00,port_pre_sel[1:0]};
    assign port_pre_sel_perport[NORTH] = {1'b0,port_pre_sel[2],1'b0,port_pre_sel[0]};
    assign port_pre_sel_perport[WEST] = {port_pre_sel[3:2],2'b0};
    assign port_pre_sel_perport[SOUTH] = {port_pre_sel[3],1'b0,port_pre_sel[1],1'b0};
    wire    [PV-1 : 0]  avc_unavailable; 
    genvar i;
    generate   
    for(i=0;i< PV;i=i+1) begin : PV_
        localparam SW_LOC = ((i/V)<5)? i/V : LOCAL;
        mesh_torus_port_selector #(
            .SW_LOC     (SW_LOC),
            .PPSw(PPSw)
        ) the_portsel (
            .port_pre_sel       (port_pre_sel_perport[SW_LOC]),
            .swap_port_presel   (swap_port_presel[i]),
            .sel                (sel[i]),
            .dest_port_in       (dest_port_coded_all[((i+1)*DSTPw)-1 : i*DSTPw]),
            .y_evc_forbiden     (y_evc_forbiden[i]),
            .x_evc_forbiden     (x_evc_forbiden[i])
        );
        mesh_tori_dspt_clear_gen #(
            .SSA_EN(SSA_EN),
            .DSTPw(DSTPw),
            .SW_LOC(SW_LOC)
        ) dspt_clear_gen(
            .destport_clear(destport_clear_all[((i+1)*DSTPw)-1 : i*DSTPw]),
            .ivc_num_getting_ovc_grant(ivc_num_getting_ovc_grant[i]),
            .sel(sel[i]),
            .ssa_ivc_num_getting_ovc_grant(ssa_ivc_num_getting_ovc_grant_all[i])
        );                           
        /* verilator lint_off WIDTH */   
        if(ROUTE_TYPE == "FULL_ADAPTIVE") begin: full_adpt
        /* verilator lint_on WIDTH */ 
            assign avc_unavailable[i] = (masked_ovc_request_all [((i+1)*V)-1 : i*V] & ~ESCAP_VC_MASK) == {V{1'b0}};
            mesh_torus_swap_port_presel_gen #(
                .V(V),
                .ESCAP_VC_MASK(ESCAP_VC_MASK),       
                .VC_NUM(i)
            ) the_swap_port_presel (
                .avc_unavailable(avc_unavailable[i]),
                .y_evc_forbiden(y_evc_forbiden[i]),
                .x_evc_forbiden(x_evc_forbiden[i]),
                .non_assigned_ovc_request(non_assigned_ovc_request_all[i]),
                .sel(sel[i]),
                .clk(clk),
                .reset(reset),
                .swap_port_presel(swap_port_presel[i])
            );
        end else begin : partial_adpt
            assign swap_port_presel[i]=1'b0;
            assign avc_unavailable[i]=1'b0;
        end// ROUTE_TYPE
    end//for    
endgenerate
endmodule
