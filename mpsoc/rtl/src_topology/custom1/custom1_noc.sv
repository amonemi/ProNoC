
/**************************************************************************
**    WARNING: THIS IS AN AUTO-GENERATED FILE. CHANGES TO IT ARE LIKELY TO BE
**    OVERWRITTEN AND LOST. Rename this file if you wish to do any modification.
****************************************************************************/


/**********************************************************************
**    File: /home/alireza/work/git/ProNoC-repos/github-pronoc/mpsoc/rtl/src_topology/custom1/custom1_noc.sv
**    
**    Copyright (C) 2014-2022  Alireza Monemi
**    
**    This file is part of ProNoC 2.2.0 
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
******************************************************************************/ 

`include "pronoc_def.v"

module   custom1_noc
#(
    parameter NOC_ID=0
)(
        reset,
    clk,
    //T0,
    T0_chan_in,
    T0_chan_out,
    T0_router_event,
    //T1,
    T1_chan_in,
    T1_chan_out,
    T1_router_event,
    //T2,
    T2_chan_in,
    T2_chan_out,
    T2_router_event,
    //T3,
    T3_chan_in,
    T3_chan_out,
    T3_router_event,
    //T4,
    T4_chan_in,
    T4_chan_out,
    T4_router_event,
    //T5,
    T5_chan_in,
    T5_chan_out,
    T5_router_event,
    //T6,
    T6_chan_in,
    T6_chan_out,
    T6_router_event,
    //T7,
    T7_chan_in,
    T7_chan_out,
    T7_router_event,
    //T8,
    T8_chan_in,
    T8_chan_out,
    T8_router_event,
    //T9,
    T9_chan_in,
    T9_chan_out,
    T9_router_event,
    //T10,
    T10_chan_in,
    T10_chan_out,
    T10_router_event,
    //T11,
    T11_chan_in,
    T11_chan_out,
    T11_router_event,
    //T12,
    T12_chan_in,
    T12_chan_out,
    T12_router_event,
    //T13,
    T13_chan_in,
    T13_chan_out,
    T13_router_event,
    //T14,
    T14_chan_in,
    T14_chan_out,
    T14_router_event,
    //T15,
    T15_chan_in,
    T15_chan_out,
    T15_router_event
);
    `NOC_CONF
    
    input reset,clk;    
    
    
    /*******************
    *        T0
    *******************/
    input  smartflit_chanel_t T0_chan_in;
    output smartflit_chanel_t T0_chan_out;
    output router_event_t T0_router_event;

    /*******************
    *        T1
    *******************/
    input  smartflit_chanel_t T1_chan_in;
    output smartflit_chanel_t T1_chan_out;
    output router_event_t T1_router_event;

    /*******************
    *        T2
    *******************/
    input  smartflit_chanel_t T2_chan_in;
    output smartflit_chanel_t T2_chan_out;
    output router_event_t T2_router_event;

    /*******************
    *        T3
    *******************/
    input  smartflit_chanel_t T3_chan_in;
    output smartflit_chanel_t T3_chan_out;
    output router_event_t T3_router_event;

    /*******************
    *        T4
    *******************/
    input  smartflit_chanel_t T4_chan_in;
    output smartflit_chanel_t T4_chan_out;
    output router_event_t T4_router_event;

    /*******************
    *        T5
    *******************/
    input  smartflit_chanel_t T5_chan_in;
    output smartflit_chanel_t T5_chan_out;
    output router_event_t T5_router_event;

    /*******************
    *        T6
    *******************/
    input  smartflit_chanel_t T6_chan_in;
    output smartflit_chanel_t T6_chan_out;
    output router_event_t T6_router_event;

    /*******************
    *        T7
    *******************/
    input  smartflit_chanel_t T7_chan_in;
    output smartflit_chanel_t T7_chan_out;
    output router_event_t T7_router_event;

    /*******************
    *        T8
    *******************/
    input  smartflit_chanel_t T8_chan_in;
    output smartflit_chanel_t T8_chan_out;
    output router_event_t T8_router_event;

    /*******************
    *        T9
    *******************/
    input  smartflit_chanel_t T9_chan_in;
    output smartflit_chanel_t T9_chan_out;
    output router_event_t T9_router_event;

    /*******************
    *        T10
    *******************/
    input  smartflit_chanel_t T10_chan_in;
    output smartflit_chanel_t T10_chan_out;
    output router_event_t T10_router_event;

    /*******************
    *        T11
    *******************/
    input  smartflit_chanel_t T11_chan_in;
    output smartflit_chanel_t T11_chan_out;
    output router_event_t T11_router_event;

    /*******************
    *        T12
    *******************/
    input  smartflit_chanel_t T12_chan_in;
    output smartflit_chanel_t T12_chan_out;
    output router_event_t T12_router_event;

    /*******************
    *        T13
    *******************/
    input  smartflit_chanel_t T13_chan_in;
    output smartflit_chanel_t T13_chan_out;
    output router_event_t T13_router_event;

    /*******************
    *        T14
    *******************/
    input  smartflit_chanel_t T14_chan_in;
    output smartflit_chanel_t T14_chan_out;
    output router_event_t T14_router_event;

    /*******************
    *        T15
    *******************/
    input  smartflit_chanel_t T15_chan_in;
    output smartflit_chanel_t T15_chan_out;
    output router_event_t T15_router_event;

    /*******************
    *        R0
    *******************/
    wire R0_clk;
    wire R0_reset;
    wire [RAw-1 :  0] R0_current_r_addr;
    smartflit_chanel_t    R0_chan_in   [3-1 : 0];
    smartflit_chanel_t    R0_chan_out  [3-1 : 0]; 
    router_event_t R0_router_event [3-1 : 0]; 

    /*******************
    *        R1
    *******************/
    wire R1_clk;
    wire R1_reset;
    wire [RAw-1 :  0] R1_current_r_addr;
    smartflit_chanel_t    R1_chan_in   [3-1 : 0];
    smartflit_chanel_t    R1_chan_out  [3-1 : 0]; 
    router_event_t R1_router_event [3-1 : 0]; 

    /*******************
    *        R2
    *******************/
    wire R2_clk;
    wire R2_reset;
    wire [RAw-1 :  0] R2_current_r_addr;
    smartflit_chanel_t    R2_chan_in   [3-1 : 0];
    smartflit_chanel_t    R2_chan_out  [3-1 : 0]; 
    router_event_t R2_router_event [3-1 : 0]; 

    /*******************
    *        R3
    *******************/
    wire R3_clk;
    wire R3_reset;
    wire [RAw-1 :  0] R3_current_r_addr;
    smartflit_chanel_t    R3_chan_in   [3-1 : 0];
    smartflit_chanel_t    R3_chan_out  [3-1 : 0]; 
    router_event_t R3_router_event [3-1 : 0]; 

    /*******************
    *        R4
    *******************/
    wire R4_clk;
    wire R4_reset;
    wire [RAw-1 :  0] R4_current_r_addr;
    smartflit_chanel_t    R4_chan_in   [4-1 : 0];
    smartflit_chanel_t    R4_chan_out  [4-1 : 0]; 
    router_event_t R4_router_event [4-1 : 0]; 

    /*******************
    *        R5
    *******************/
    wire R5_clk;
    wire R5_reset;
    wire [RAw-1 :  0] R5_current_r_addr;
    smartflit_chanel_t    R5_chan_in   [4-1 : 0];
    smartflit_chanel_t    R5_chan_out  [4-1 : 0]; 
    router_event_t R5_router_event [4-1 : 0]; 

    /*******************
    *        R6
    *******************/
    wire R6_clk;
    wire R6_reset;
    wire [RAw-1 :  0] R6_current_r_addr;
    smartflit_chanel_t    R6_chan_in   [4-1 : 0];
    smartflit_chanel_t    R6_chan_out  [4-1 : 0]; 
    router_event_t R6_router_event [4-1 : 0]; 

    /*******************
    *        R7
    *******************/
    wire R7_clk;
    wire R7_reset;
    wire [RAw-1 :  0] R7_current_r_addr;
    smartflit_chanel_t    R7_chan_in   [4-1 : 0];
    smartflit_chanel_t    R7_chan_out  [4-1 : 0]; 
    router_event_t R7_router_event [4-1 : 0]; 

    /*******************
    *        R12
    *******************/
    wire R12_clk;
    wire R12_reset;
    wire [RAw-1 :  0] R12_current_r_addr;
    smartflit_chanel_t    R12_chan_in   [4-1 : 0];
    smartflit_chanel_t    R12_chan_out  [4-1 : 0]; 
    router_event_t R12_router_event [4-1 : 0]; 

    /*******************
    *        R13
    *******************/
    wire R13_clk;
    wire R13_reset;
    wire [RAw-1 :  0] R13_current_r_addr;
    smartflit_chanel_t    R13_chan_in   [4-1 : 0];
    smartflit_chanel_t    R13_chan_out  [4-1 : 0]; 
    router_event_t R13_router_event [4-1 : 0]; 

    /*******************
    *        R14
    *******************/
    wire R14_clk;
    wire R14_reset;
    wire [RAw-1 :  0] R14_current_r_addr;
    smartflit_chanel_t    R14_chan_in   [4-1 : 0];
    smartflit_chanel_t    R14_chan_out  [4-1 : 0]; 
    router_event_t R14_router_event [4-1 : 0]; 

    /*******************
    *        R15
    *******************/
    wire R15_clk;
    wire R15_reset;
    wire [RAw-1 :  0] R15_current_r_addr;
    smartflit_chanel_t    R15_chan_in   [4-1 : 0];
    smartflit_chanel_t    R15_chan_out  [4-1 : 0]; 
    router_event_t R15_router_event [4-1 : 0]; 

    /*******************
    *        R8
    *******************/
    wire R8_clk;
    wire R8_reset;
    wire [RAw-1 :  0] R8_current_r_addr;
    smartflit_chanel_t    R8_chan_in   [5-1 : 0];
    smartflit_chanel_t    R8_chan_out  [5-1 : 0]; 
    router_event_t R8_router_event [5-1 : 0]; 

    /*******************
    *        R9
    *******************/
    wire R9_clk;
    wire R9_reset;
    wire [RAw-1 :  0] R9_current_r_addr;
    smartflit_chanel_t    R9_chan_in   [5-1 : 0];
    smartflit_chanel_t    R9_chan_out  [5-1 : 0]; 
    router_event_t R9_router_event [5-1 : 0]; 

    /*******************
    *        R10
    *******************/
    wire R10_clk;
    wire R10_reset;
    wire [RAw-1 :  0] R10_current_r_addr;
    smartflit_chanel_t    R10_chan_in   [5-1 : 0];
    smartflit_chanel_t    R10_chan_out  [5-1 : 0]; 
    router_event_t R10_router_event [5-1 : 0]; 

    /*******************
    *        R11
    *******************/
    wire R11_clk;
    wire R11_reset;
    wire [RAw-1 :  0] R11_current_r_addr;
    smartflit_chanel_t    R11_chan_in   [5-1 : 0];
    smartflit_chanel_t    R11_chan_out  [5-1 : 0]; 
    router_event_t R11_router_event [5-1 : 0]; 

    
        
    /*******************
    *        R0
    *******************/
    router_top #(
        .NOC_ID(NOC_ID),
        .ROUTER_ID(0),
        .P(3)
    ) R0 (
        .clk(R0_clk), 
        .reset(R0_reset),
        .current_r_id(0),
        .current_r_addr  (R0_current_r_addr), 
        .chan_in   (R0_chan_in), 
        .chan_out  (R0_chan_out),
        .router_event (R0_router_event)
    );

        assign R0_clk = clk;
        assign R0_reset = reset;
        assign R0_current_r_addr = 0;
    //Connect R0 port 0 to  T0 port 0
    assign R0_chan_in [0]  = T0_chan_in;
    assign T0_chan_out = R0_chan_out [0];
    assign T0_router_event = R0_router_event [0];
    //Connect R0 port 1 to  R14 port 3
    assign R0_chan_in [1]   = R14_chan_out [3];
    //Connect R0 port 2 to  R13 port 3
    assign R0_chan_in [2]   = R13_chan_out [3];
    
    /*******************
    *        R1
    *******************/
    router_top #(
        .NOC_ID(NOC_ID),
        .ROUTER_ID(1),
        .P(3)
    ) R1 (
        .clk(R1_clk), 
        .reset(R1_reset),
        .current_r_id(1),
        .current_r_addr  (R1_current_r_addr), 
        .chan_in   (R1_chan_in), 
        .chan_out  (R1_chan_out),
        .router_event (R1_router_event)
    );

        assign R1_clk = clk;
        assign R1_reset = reset;
        assign R1_current_r_addr = 1;
    //Connect R1 port 0 to  T1 port 0
    assign R1_chan_in [0]  = T1_chan_in;
    assign T1_chan_out = R1_chan_out [0];
    assign T1_router_event = R1_router_event [0];
    //Connect R1 port 1 to  R7 port 3
    assign R1_chan_in [1]   = R7_chan_out [3];
    //Connect R1 port 2 to  R2 port 2
    assign R1_chan_in [2]   = R2_chan_out [2];
    
    /*******************
    *        R2
    *******************/
    router_top #(
        .NOC_ID(NOC_ID),
        .ROUTER_ID(2),
        .P(3)
    ) R2 (
        .clk(R2_clk), 
        .reset(R2_reset),
        .current_r_id(2),
        .current_r_addr  (R2_current_r_addr), 
        .chan_in   (R2_chan_in), 
        .chan_out  (R2_chan_out),
        .router_event (R2_router_event)
    );

        assign R2_clk = clk;
        assign R2_reset = reset;
        assign R2_current_r_addr = 2;
    //Connect R2 port 0 to  T2 port 0
    assign R2_chan_in [0]  = T2_chan_in;
    assign T2_chan_out = R2_chan_out [0];
    assign T2_router_event = R2_router_event [0];
    //Connect R2 port 1 to  R15 port 2
    assign R2_chan_in [1]   = R15_chan_out [2];
    //Connect R2 port 2 to  R1 port 2
    assign R2_chan_in [2]   = R1_chan_out [2];
    
    /*******************
    *        R3
    *******************/
    router_top #(
        .NOC_ID(NOC_ID),
        .ROUTER_ID(3),
        .P(3)
    ) R3 (
        .clk(R3_clk), 
        .reset(R3_reset),
        .current_r_id(3),
        .current_r_addr  (R3_current_r_addr), 
        .chan_in   (R3_chan_in), 
        .chan_out  (R3_chan_out),
        .router_event (R3_router_event)
    );

        assign R3_clk = clk;
        assign R3_reset = reset;
        assign R3_current_r_addr = 3;
    //Connect R3 port 0 to  T3 port 0
    assign R3_chan_in [0]  = T3_chan_in;
    assign T3_chan_out = R3_chan_out [0];
    assign T3_router_event = R3_router_event [0];
    //Connect R3 port 1 to  R15 port 3
    assign R3_chan_in [1]   = R15_chan_out [3];
    //Connect R3 port 2 to  R4 port 2
    assign R3_chan_in [2]   = R4_chan_out [2];
    
    /*******************
    *        R4
    *******************/
    router_top #(
        .NOC_ID(NOC_ID),
        .ROUTER_ID(4),
        .P(4)
    ) R4 (
        .clk(R4_clk), 
        .reset(R4_reset),
        .current_r_id(4),
        .current_r_addr  (R4_current_r_addr), 
        .chan_in   (R4_chan_in), 
        .chan_out  (R4_chan_out),
        .router_event (R4_router_event)
    );

        assign R4_clk = clk;
        assign R4_reset = reset;
        assign R4_current_r_addr = 4;
    //Connect R4 port 0 to  T4 port 0
    assign R4_chan_in [0]  = T4_chan_in;
    assign T4_chan_out = R4_chan_out [0];
    assign T4_router_event = R4_router_event [0];
    //Connect R4 port 1 to  R9 port 2
    assign R4_chan_in [1]   = R9_chan_out [2];
    //Connect R4 port 2 to  R3 port 2
    assign R4_chan_in [2]   = R3_chan_out [2];
    //Connect R4 port 3 to  R6 port 3
    assign R4_chan_in [3]   = R6_chan_out [3];
    
    /*******************
    *        R5
    *******************/
    router_top #(
        .NOC_ID(NOC_ID),
        .ROUTER_ID(5),
        .P(4)
    ) R5 (
        .clk(R5_clk), 
        .reset(R5_reset),
        .current_r_id(5),
        .current_r_addr  (R5_current_r_addr), 
        .chan_in   (R5_chan_in), 
        .chan_out  (R5_chan_out),
        .router_event (R5_router_event)
    );

        assign R5_clk = clk;
        assign R5_reset = reset;
        assign R5_current_r_addr = 5;
    //Connect R5 port 0 to  T5 port 0
    assign R5_chan_in [0]  = T5_chan_in;
    assign T5_chan_out = R5_chan_out [0];
    assign T5_router_event = R5_router_event [0];
    //Connect R5 port 1 to  R11 port 4
    assign R5_chan_in [1]   = R11_chan_out [4];
    //Connect R5 port 2 to  R6 port 2
    assign R5_chan_in [2]   = R6_chan_out [2];
    //Connect R5 port 3 to  R13 port 2
    assign R5_chan_in [3]   = R13_chan_out [2];
    
    /*******************
    *        R6
    *******************/
    router_top #(
        .NOC_ID(NOC_ID),
        .ROUTER_ID(6),
        .P(4)
    ) R6 (
        .clk(R6_clk), 
        .reset(R6_reset),
        .current_r_id(6),
        .current_r_addr  (R6_current_r_addr), 
        .chan_in   (R6_chan_in), 
        .chan_out  (R6_chan_out),
        .router_event (R6_router_event)
    );

        assign R6_clk = clk;
        assign R6_reset = reset;
        assign R6_current_r_addr = 6;
    //Connect R6 port 0 to  T6 port 0
    assign R6_chan_in [0]  = T6_chan_in;
    assign T6_chan_out = R6_chan_out [0];
    assign T6_router_event = R6_router_event [0];
    //Connect R6 port 1 to  R9 port 3
    assign R6_chan_in [1]   = R9_chan_out [3];
    //Connect R6 port 2 to  R5 port 2
    assign R6_chan_in [2]   = R5_chan_out [2];
    //Connect R6 port 3 to  R4 port 3
    assign R6_chan_in [3]   = R4_chan_out [3];
    
    /*******************
    *        R7
    *******************/
    router_top #(
        .NOC_ID(NOC_ID),
        .ROUTER_ID(7),
        .P(4)
    ) R7 (
        .clk(R7_clk), 
        .reset(R7_reset),
        .current_r_id(7),
        .current_r_addr  (R7_current_r_addr), 
        .chan_in   (R7_chan_in), 
        .chan_out  (R7_chan_out),
        .router_event (R7_router_event)
    );

        assign R7_clk = clk;
        assign R7_reset = reset;
        assign R7_current_r_addr = 7;
    //Connect R7 port 0 to  T7 port 0
    assign R7_chan_in [0]  = T7_chan_in;
    assign T7_chan_out = R7_chan_out [0];
    assign T7_router_event = R7_router_event [0];
    //Connect R7 port 1 to  R12 port 3
    assign R7_chan_in [1]   = R12_chan_out [3];
    //Connect R7 port 2 to  R14 port 2
    assign R7_chan_in [2]   = R14_chan_out [2];
    //Connect R7 port 3 to  R1 port 1
    assign R7_chan_in [3]   = R1_chan_out [1];
    
    /*******************
    *        R12
    *******************/
    router_top #(
        .NOC_ID(NOC_ID),
        .ROUTER_ID(8),
        .P(4)
    ) R12 (
        .clk(R12_clk), 
        .reset(R12_reset),
        .current_r_id(8),
        .current_r_addr  (R12_current_r_addr), 
        .chan_in   (R12_chan_in), 
        .chan_out  (R12_chan_out),
        .router_event (R12_router_event)
    );

        assign R12_clk = clk;
        assign R12_reset = reset;
        assign R12_current_r_addr = 8;
    //Connect R12 port 0 to  T8 port 0
    assign R12_chan_in [0]  = T8_chan_in;
    assign T8_chan_out = R12_chan_out [0];
    assign T8_router_event = R12_router_event [0];
    //Connect R12 port 1 to  R8 port 4
    assign R12_chan_in [1]   = R8_chan_out [4];
    //Connect R12 port 2 to  R10 port 3
    assign R12_chan_in [2]   = R10_chan_out [3];
    //Connect R12 port 3 to  R7 port 1
    assign R12_chan_in [3]   = R7_chan_out [1];
    
    /*******************
    *        R13
    *******************/
    router_top #(
        .NOC_ID(NOC_ID),
        .ROUTER_ID(9),
        .P(4)
    ) R13 (
        .clk(R13_clk), 
        .reset(R13_reset),
        .current_r_id(9),
        .current_r_addr  (R13_current_r_addr), 
        .chan_in   (R13_chan_in), 
        .chan_out  (R13_chan_out),
        .router_event (R13_router_event)
    );

        assign R13_clk = clk;
        assign R13_reset = reset;
        assign R13_current_r_addr = 9;
    //Connect R13 port 0 to  T9 port 0
    assign R13_chan_in [0]  = T9_chan_in;
    assign T9_chan_out = R13_chan_out [0];
    assign T9_router_event = R13_router_event [0];
    //Connect R13 port 1 to  R8 port 2
    assign R13_chan_in [1]   = R8_chan_out [2];
    //Connect R13 port 2 to  R5 port 3
    assign R13_chan_in [2]   = R5_chan_out [3];
    //Connect R13 port 3 to  R0 port 2
    assign R13_chan_in [3]   = R0_chan_out [2];
    
    /*******************
    *        R14
    *******************/
    router_top #(
        .NOC_ID(NOC_ID),
        .ROUTER_ID(10),
        .P(4)
    ) R14 (
        .clk(R14_clk), 
        .reset(R14_reset),
        .current_r_id(10),
        .current_r_addr  (R14_current_r_addr), 
        .chan_in   (R14_chan_in), 
        .chan_out  (R14_chan_out),
        .router_event (R14_router_event)
    );

        assign R14_clk = clk;
        assign R14_reset = reset;
        assign R14_current_r_addr = 10;
    //Connect R14 port 0 to  T10 port 0
    assign R14_chan_in [0]  = T10_chan_in;
    assign T10_chan_out = R14_chan_out [0];
    assign T10_router_event = R14_router_event [0];
    //Connect R14 port 1 to  R8 port 3
    assign R14_chan_in [1]   = R8_chan_out [3];
    //Connect R14 port 2 to  R7 port 2
    assign R14_chan_in [2]   = R7_chan_out [2];
    //Connect R14 port 3 to  R0 port 1
    assign R14_chan_in [3]   = R0_chan_out [1];
    
    /*******************
    *        R15
    *******************/
    router_top #(
        .NOC_ID(NOC_ID),
        .ROUTER_ID(11),
        .P(4)
    ) R15 (
        .clk(R15_clk), 
        .reset(R15_reset),
        .current_r_id(11),
        .current_r_addr  (R15_current_r_addr), 
        .chan_in   (R15_chan_in), 
        .chan_out  (R15_chan_out),
        .router_event (R15_router_event)
    );

        assign R15_clk = clk;
        assign R15_reset = reset;
        assign R15_current_r_addr = 11;
    //Connect R15 port 0 to  T11 port 0
    assign R15_chan_in [0]  = T11_chan_in;
    assign T11_chan_out = R15_chan_out [0];
    assign T11_router_event = R15_router_event [0];
    //Connect R15 port 1 to  R10 port 4
    assign R15_chan_in [1]   = R10_chan_out [4];
    //Connect R15 port 2 to  R2 port 1
    assign R15_chan_in [2]   = R2_chan_out [1];
    //Connect R15 port 3 to  R3 port 1
    assign R15_chan_in [3]   = R3_chan_out [1];
    
    /*******************
    *        R8
    *******************/
    router_top #(
        .NOC_ID(NOC_ID),
        .ROUTER_ID(12),
        .P(5)
    ) R8 (
        .clk(R8_clk), 
        .reset(R8_reset),
        .current_r_id(12),
        .current_r_addr  (R8_current_r_addr), 
        .chan_in   (R8_chan_in), 
        .chan_out  (R8_chan_out),
        .router_event (R8_router_event)
    );

        assign R8_clk = clk;
        assign R8_reset = reset;
        assign R8_current_r_addr = 12;
    //Connect R8 port 0 to  T12 port 0
    assign R8_chan_in [0]  = T12_chan_in;
    assign T12_chan_out = R8_chan_out [0];
    assign T12_router_event = R8_router_event [0];
    //Connect R8 port 1 to  R11 port 1
    assign R8_chan_in [1]   = R11_chan_out [1];
    //Connect R8 port 2 to  R13 port 1
    assign R8_chan_in [2]   = R13_chan_out [1];
    //Connect R8 port 3 to  R14 port 1
    assign R8_chan_in [3]   = R14_chan_out [1];
    //Connect R8 port 4 to  R12 port 1
    assign R8_chan_in [4]   = R12_chan_out [1];
    
    /*******************
    *        R9
    *******************/
    router_top #(
        .NOC_ID(NOC_ID),
        .ROUTER_ID(13),
        .P(5)
    ) R9 (
        .clk(R9_clk), 
        .reset(R9_reset),
        .current_r_id(13),
        .current_r_addr  (R9_current_r_addr), 
        .chan_in   (R9_chan_in), 
        .chan_out  (R9_chan_out),
        .router_event (R9_router_event)
    );

        assign R9_clk = clk;
        assign R9_reset = reset;
        assign R9_current_r_addr = 13;
    //Connect R9 port 0 to  T13 port 0
    assign R9_chan_in [0]  = T13_chan_in;
    assign T13_chan_out = R9_chan_out [0];
    assign T13_router_event = R9_router_event [0];
    //Connect R9 port 1 to  R11 port 3
    assign R9_chan_in [1]   = R11_chan_out [3];
    //Connect R9 port 2 to  R4 port 1
    assign R9_chan_in [2]   = R4_chan_out [1];
    //Connect R9 port 3 to  R6 port 1
    assign R9_chan_in [3]   = R6_chan_out [1];
    //Connect R9 port 4 to  R10 port 2
    assign R9_chan_in [4]   = R10_chan_out [2];
    
    /*******************
    *        R10
    *******************/
    router_top #(
        .NOC_ID(NOC_ID),
        .ROUTER_ID(14),
        .P(5)
    ) R10 (
        .clk(R10_clk), 
        .reset(R10_reset),
        .current_r_id(14),
        .current_r_addr  (R10_current_r_addr), 
        .chan_in   (R10_chan_in), 
        .chan_out  (R10_chan_out),
        .router_event (R10_router_event)
    );

        assign R10_clk = clk;
        assign R10_reset = reset;
        assign R10_current_r_addr = 14;
    //Connect R10 port 0 to  T14 port 0
    assign R10_chan_in [0]  = T14_chan_in;
    assign T14_chan_out = R10_chan_out [0];
    assign T14_router_event = R10_router_event [0];
    //Connect R10 port 1 to  R11 port 2
    assign R10_chan_in [1]   = R11_chan_out [2];
    //Connect R10 port 2 to  R9 port 4
    assign R10_chan_in [2]   = R9_chan_out [4];
    //Connect R10 port 3 to  R12 port 2
    assign R10_chan_in [3]   = R12_chan_out [2];
    //Connect R10 port 4 to  R15 port 1
    assign R10_chan_in [4]   = R15_chan_out [1];
    
    /*******************
    *        R11
    *******************/
    router_top #(
        .NOC_ID(NOC_ID),
        .ROUTER_ID(15),
        .P(5)
    ) R11 (
        .clk(R11_clk), 
        .reset(R11_reset),
        .current_r_id(15),
        .current_r_addr  (R11_current_r_addr), 
        .chan_in   (R11_chan_in), 
        .chan_out  (R11_chan_out),
        .router_event (R11_router_event)
    );

        assign R11_clk = clk;
        assign R11_reset = reset;
        assign R11_current_r_addr = 15;
    //Connect R11 port 0 to  T15 port 0
    assign R11_chan_in [0]  = T15_chan_in;
    assign T15_chan_out = R11_chan_out [0];
    assign T15_router_event = R11_router_event [0];
    //Connect R11 port 1 to  R8 port 1
    assign R11_chan_in [1]   = R8_chan_out [1];
    //Connect R11 port 2 to  R10 port 1
    assign R11_chan_in [2]   = R10_chan_out [1];
    //Connect R11 port 3 to  R9 port 1
    assign R11_chan_in [3]   = R9_chan_out [1];
    //Connect R11 port 4 to  R5 port 1
    assign R11_chan_in [4]   = R5_chan_out [1];

    
    
    
endmodule
