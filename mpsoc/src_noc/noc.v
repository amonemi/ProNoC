// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on


/**********************************************************************
**    File:  noc.v
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
**    the NoC top module. 
**
**************************************************************/
module  noc #(
    parameter V = 4,     // vc_num_per_port
    parameter B = 4,     // buffer space :flit per VC 
    parameter TOPOLOGY= "MESH",     
    /*TOPOLOGY RELATED PARAMETER*/
    // a topology can be defined using at most four parameter 
    //    e.g: in mesh:
    //    T1: NX, number of node in x dimention T2: NY: number of node in y dimention, T2,T3 not used 
    //     e.g: in fattree:
    //    T1: K, umber of last level individual router`s endpoints. T2: L layer number, T2,T3 not used    
    parameter T1= 8,
    parameter T2= 8,
    parameter T3= 8,
    parameter T4= 8,  
    parameter ROUTE_NAME = "DUATO",        
    parameter C = 2,    //    number of flit class 
    parameter Fpay = 32,
    parameter MUX_TYPE= "ONE_HOT",    //"ONE_HOT" or "BINARY"
    parameter VC_REALLOCATION_TYPE = "NONATOMIC",// "ATOMIC" , "NONATOMIC"
    parameter COMBINATION_TYPE= "COMB_NONSPEC",// "COMB_SPEC1", "COMB_SPEC2", "COMB_NONSPEC"
    parameter FIRST_ARBITER_EXT_P_EN = 0,    
    parameter CONGESTION_INDEX = 7,
    parameter DEBUG_EN=0,
    parameter AVC_ATOMIC_EN= 0,   
    parameter ADD_PIPREG_AFTER_CROSSBAR=0,
    parameter CVw=(C==0)? V : C * V,
    parameter [CVw-1:  0] CLASS_SETTING = {CVw{1'b1}}, // shows how each class can use VCs   
    parameter [V-1 :  0] ESCAP_VC_MASK = 4'b1000,  // mask scape vc, valid only for full adaptive
    parameter SSA_EN="YES", // "YES" , "NO"
    parameter SWA_ARBITER_TYPE = "RRA",//"RRA","WRRA". RRA: Round Robin Arbiter WRRA weighted Round Robin Arbiter 
    parameter WEIGHTw = 4, // WRRA width
    parameter MIN_PCK_SIZE = 2 //minimum packet size in flits. The minimum value is 1. 
)(
    flit_out_all,
    flit_out_wr_all,
    credit_in_all,
    flit_in_all,
    flit_in_wr_all,  
    credit_out_all,
    reset,
    clk
 );
 
    `define INCLUDE_TOPOLOGY_LOCALPARAM
    `include "topology_localparam.v"


    localparam 
        Fw = 2+V+Fpay, //flit width;    
        NEFw = NE * Fw,
        NEV = NE * V;

    input reset,clk;    
    
    output [NEFw-1 : 0] flit_out_all;
    output [NE-1 : 0] flit_out_wr_all;
    input  [NEV-1 : 0] credit_in_all;
    input  [NEFw-1 : 0] flit_in_all;
    input  [NE-1 : 0] flit_in_wr_all;  
    output [NEV-1 : 0] credit_out_all;


generate 
if (TOPOLOGY ==    "MESH" || TOPOLOGY ==  "TORUS" || TOPOLOGY == "RING" || TOPOLOGY == "LINE")begin : tori_noc 

    mesh_torus_noc #(
    	.V(V),
    	.B(B),
    	.T1(T1),
    	.T2(T2),
    	.T3(T3),
    	.C(C),
    	.Fpay(Fpay),
    	.MUX_TYPE(MUX_TYPE),
    	.VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
    	.COMBINATION_TYPE(COMBINATION_TYPE),
    	.FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
    	.TOPOLOGY(TOPOLOGY),
    	.ROUTE_NAME(ROUTE_NAME),
    	.CONGESTION_INDEX(CONGESTION_INDEX),
    	.DEBUG_EN(DEBUG_EN),
    	.AVC_ATOMIC_EN(AVC_ATOMIC_EN),
    	.ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
    	.CVw(CVw),
    	.CLASS_SETTING(CLASS_SETTING),
    	.ESCAP_VC_MASK(ESCAP_VC_MASK),
    	.SSA_EN(SSA_EN),
    	.SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
    	.WEIGHTw(WEIGHTw),
    	.MIN_PCK_SIZE(MIN_PCK_SIZE)
    )
    mesh_torus_noc
    (
    	.reset(reset),
    	.clk(clk),
    	.flit_out_all(flit_out_all),
    	.flit_out_wr_all(flit_out_wr_all),
    	.credit_in_all(credit_in_all),
    	.flit_in_all(flit_in_all),
    	.flit_in_wr_all(flit_in_wr_all),
    	.credit_out_all(credit_out_all)
    );
    
    end else if (TOPOLOGY == "FATTREE") begin : fat
    
        fattree_noc #(
        	.V(V),
        	.B(B),
        	.T1(T1),
        	.T2(T2),
        	.T3(T3),
        	.C(C),
        	.Fpay(Fpay),
        	.MUX_TYPE(MUX_TYPE),
        	.VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        	.COMBINATION_TYPE(COMBINATION_TYPE),
        	.FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
        	.TOPOLOGY(TOPOLOGY),
        	.ROUTE_NAME(ROUTE_NAME),
        	.CONGESTION_INDEX(CONGESTION_INDEX),
        	.DEBUG_EN(DEBUG_EN),
        	.AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        	.ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        	.CVw(CVw),
        	.CLASS_SETTING(CLASS_SETTING),
        	.ESCAP_VC_MASK(ESCAP_VC_MASK),
        	.SSA_EN(SSA_EN),
        	.SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        	.WEIGHTw(WEIGHTw),
        	.MIN_PCK_SIZE(MIN_PCK_SIZE)
        )
        fattree
        (
        	.reset(reset),
        	.clk(clk),
        	.flit_out_all(flit_out_all),
        	.flit_out_wr_all(flit_out_wr_all),
        	.credit_in_all(credit_in_all),
        	.flit_in_all(flit_in_all),
        	.flit_in_wr_all(flit_in_wr_all),
        	.credit_out_all(credit_out_all)
        );

    end else if (TOPOLOGY == "TREE") begin : tree
        tree_noc #(
            .V(V),
            .B(B),
            .T1(T1),
            .T2(T2),
            .T3(T3),
            .C(C),
            .Fpay(Fpay),
            .MUX_TYPE(MUX_TYPE),
            .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
            .COMBINATION_TYPE(COMBINATION_TYPE),
            .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
            .TOPOLOGY(TOPOLOGY),
            .ROUTE_NAME(ROUTE_NAME),
            .CONGESTION_INDEX(CONGESTION_INDEX),
            .DEBUG_EN(DEBUG_EN),
            .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
            .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
            .CVw(CVw),
            .CLASS_SETTING(CLASS_SETTING),
            .ESCAP_VC_MASK(ESCAP_VC_MASK),
            .SSA_EN(SSA_EN),
            .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
            .WEIGHTw(WEIGHTw),
            .MIN_PCK_SIZE(MIN_PCK_SIZE)
            )
            tree
            (
            	.reset(reset),
            	.clk(clk),
            	.flit_out_all(flit_out_all),
            	.flit_out_wr_all(flit_out_wr_all),
            	.credit_in_all(credit_in_all),
            	.flit_in_all(flit_in_all),
            	.flit_in_wr_all(flit_in_wr_all),
            	.credit_out_all(credit_out_all)
            );    
    
    end     
    endgenerate
endmodule

