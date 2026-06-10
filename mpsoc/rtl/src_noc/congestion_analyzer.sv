`include "pronoc_def.v"
/**********************************************************************
** File: congestion_analyzer.v
** 
** Copyright (C) 2014-2017  Alireza Monemi
** 
** This file is part of ProNoC 
**
** ProNoC ( stands for Prototype Network-on-chip)  is free software: 
** you can redistribute it and/or modify it under the terms of the GNU
** Lesser General Public License as published by the Free Software Foundation,
** either version 2 of the License, or (at your option) any later version.
**
**  ProNoC is distributed in the hope that it will be useful, but WITHOUT
**  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
**  or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General
**  Public License for more details.
**
**  You should have received a copy of the GNU Lesser General Public
**  License along with ProNoC. If not, see <http:**www.gnu.org/licenses/>.
**
**
** Description: 
** This file includes all files for getting congestion information and
** Port selection modules for supporting adaptive routing 
**
**************************************************************/

/***************************************
*     
*  port_presel_based_dst_ports_vc
*       CONGESTION_INDEX==0
***************************************/
//congestion analyzer based on number of occupied VCs
module   port_presel_based_dst_ports_vc #(
    parameter P = 5
    )(
        ovc_status,
        port_pre_sel
    );
    import pronoc_pkg::*;
    localparam  
        P_1 = P-1,
        P_1V = P_1*V,
        CNTw = log2(V+1);
    
    input [P_1V-1 : 0] ovc_status; 
    output [PPSw-1 : 0] port_pre_sel;
    wire [P_1-1 : 0] conjestion_cmp;
    //VC counter on all ports exept the local    
    wire [V-1 : 0] ovc_status_per_port [P-1-1 : 0];
    wire [CNTw -1 : 0] vc_counter [P_1-1 : 0];
    
    genvar i;
    generate
    for( i= 0;i<P_1;i=i+1) begin : P_
    //seperate all credit counters 
        assign ovc_status_per_port[i] = ovc_status[(i+1)*V-1 : i*V];
        //count number of busy OVCs
        accumulator #(
            .INw(V),
            .OUTw(CNTw),
            .NUM(V)
        ) counter (
            .in_all(ovc_status_per_port[i]),
            .sum_o(vc_counter[i])
        );
    end//for
    endgenerate
    /******************* 
    * pre-sel[xy]
    *  y
    * 1   |   3
    *  |
    * ---------- x
    * 0   |   2
    *  |    
    * 
    * pre_sel
    *  0: xdir is preferable
    *  1: ydir is preferable
    *******************/
    //location in counter  
    localparam 
        X_PLUS = 0,//EAST
        Y_PLUS = 1,//NORTH
        X_MINUS = 2,//WEST
        Y_MINUS = 3;//SOUTH
    //location in port-pre-select           
    localparam 
        X_PLUS_Y_PLUS = 3,
        X_MINUS_Y_PLUS = 1,
        X_PLUS_Y_MINUS = 2,
        X_MINUS_Y_MINUS= 0;
    
    assign conjestion_cmp[X_PLUS_Y_PLUS] = (vc_counter[X_PLUS] >  vc_counter[Y_PLUS]);
    assign conjestion_cmp[X_MINUS_Y_PLUS] = (vc_counter[X_MINUS] >  vc_counter[Y_PLUS]);
    assign conjestion_cmp[X_PLUS_Y_MINUS] = (vc_counter[X_PLUS] >  vc_counter[Y_MINUS]);
    assign conjestion_cmp[X_MINUS_Y_MINUS]= (vc_counter[X_MINUS] >  vc_counter[Y_MINUS]);
    //assign port_pre_sel = conjestion_cmp;
    assign port_pre_sel = conjestion_cmp;
endmodule

/*************************************
* port_presel_based_dst_ports_credit
*        CONGESTION_INDEX==1
*************************************/
//congestion analyzer based on number of total available credit of a port
module  port_presel_based_dst_ports_credit #(
    parameter P = 5
)(
    credit_decreased_all,
    credit_increased_all,
    port_pre_sel,
    clk,
    reset
);
    import pronoc_pkg::*; 
    localparam  
        P_1 = P-1,
        P_1V = (P_1)*V,
        BV = B*V,
        BV_1 = BV-1,
        BVw = log2(BV);
    localparam [BVw-1 : 0] C_INT = BV_1 [BVw-1 : 0]; 
    
    input [P_1V-1 : 0] credit_decreased_all;  
    input [P_1V-1 : 0] credit_increased_all; 
    input             reset,clk;
    output [PPSw-1 : 0] port_pre_sel;
    
    logic [BVw-1 : 0] credit_per_port_next [P_1-1 : 0];
    logic [BVw-1 : 0] credit_per_port [P_1-1 : 0];
    wire [P_1-1 : 0] credit_increased_per_port;
    wire [P_1-1 : 0] credit_decreased_per_port;
    wire [P_1-1 : 0] conjestion_cmp;
    
    genvar i;
    generate   
    for(i=0;   i<P_1; i=i+1) begin : P_           
        assign  credit_increased_per_port[i]=|credit_increased_all[((i+1)*V)-1 : i*V];
        assign  credit_decreased_per_port[i]=|credit_decreased_all[((i+1)*V)-1 : i*V];
        always_ff @ (`pronoc_clk_reset_edge )begin 
            if(`pronoc_reset) begin     
                credit_per_port[i] <= BVw'(C_INT);
            end else begin
                credit_per_port[i] <= credit_per_port_next[i];
            end
        end
    end//for
    
    for(i=0; i<P; i=i+1) begin :blk1
        always @(*) begin
            credit_per_port_next[i] = credit_per_port[i];
            if(credit_increased_per_port[i] & ~credit_decreased_per_port[i]) begin 
                credit_per_port_next[i] = credit_per_port[i]+1'b1;
            end else if (~credit_increased_per_port[i] & credit_decreased_per_port[i])begin 
                credit_per_port_next[i] = credit_per_port[i]-1'b1;
            end
        end//for
    end//always
    endgenerate
    //location in counter  
    localparam 
        X_PLUS = 0,//EAST
        Y_PLUS = 1,//NORTH
        X_MINUS = 2,//WEST
        Y_MINUS = 3;//SOUTH
    //location in port-pre-select           
    localparam 
        X_PLUS_Y_PLUS = 3,
        X_MINUS_Y_PLUS = 1,
        X_PLUS_Y_MINUS = 2,
        X_MINUS_Y_MINUS= 0;
    
    assign conjestion_cmp[X_PLUS_Y_PLUS] = (credit_per_port[X_PLUS] <  credit_per_port[Y_PLUS]);
    assign conjestion_cmp[X_MINUS_Y_PLUS] = (credit_per_port[X_MINUS] <  credit_per_port[Y_PLUS]);
    assign conjestion_cmp[X_PLUS_Y_MINUS] = (credit_per_port[X_PLUS] <  credit_per_port[Y_MINUS]);
    assign conjestion_cmp[X_MINUS_Y_MINUS]= (credit_per_port[X_MINUS] <  credit_per_port[Y_MINUS]);
    // assign port_pre_sel = conjestion_cmp;
    assign port_pre_sel = conjestion_cmp;
endmodule  


/*********************************
* port_presel_based_dst_routers_ovc
* CONGESTION_INDEX==2,3,4,5,6,7,9
********************************/ 
module regular_topo_port_presel_based_dst_routers_vc #(
    parameter P=5
)(
    port_pre_sel,    
    congestion_in_all,
    reset,clk
);
    import pronoc_pkg::*;
    localparam  CONG_ALw = CONGw* P;   //  congestion width per router;
    localparam XDIR =1'b0;
    localparam YDIR =1'b1;
    //location in port-pre-select           
    localparam 
        X_PLUS_Y_PLUS = 3,
        X_MINUS_Y_PLUS = 1,
        X_PLUS_Y_MINUS = 2,
        X_MINUS_Y_MINUS= 0;            
    input [CONG_ALw-1 : 0] congestion_in_all;
    output reg [PPSw-1 : 0] port_pre_sel;
    input reset,clk;
    wire [CONGw-1 : 0] congestion_x_plus,congestion_y_plus,congestion_x_min,congestion_y_min;
    wire [PPSw-1 : 0] conjestion_cmp;
    
    assign {congestion_y_min,congestion_x_min,congestion_y_plus,congestion_x_plus} = congestion_in_all[(CONGw*5)-1 : CONGw];
    /****************
    * congestion: 
    *      0: list congested
    *      3: most congested
    * pre_sel
    *      0: xdir
    *      1: ydir
    *******************/
    assign conjestion_cmp[X_PLUS_Y_PLUS] = (congestion_x_plus  >  congestion_y_plus)? YDIR : XDIR;
    assign conjestion_cmp[X_MINUS_Y_PLUS] = (congestion_x_min   >  congestion_y_plus)? YDIR : XDIR;
    assign conjestion_cmp[X_PLUS_Y_MINUS] = (congestion_x_plus  >  congestion_y_min)?  YDIR : XDIR;
    assign conjestion_cmp[X_MINUS_Y_MINUS]= (congestion_x_min   >  congestion_y_min)?  YDIR : XDIR;
    // assign port_pre_sel = conjestion_cmp;
    always_ff @ (`pronoc_clk_reset_edge )begin 
        if(`pronoc_reset) begin
            port_pre_sel <= {PPSw{1'b0}};
        end else begin
            port_pre_sel <= conjestion_cmp;
        end
    end
endmodule


/*********************************
* port_presel_based_dst_routers_ovc
* CONGESTION_INDEX==8,10
********************************/ 
module port_presel_based_dst_routers_ovc #(
    parameter P=5
)(
    port_pre_sel,    
    congestion_in_all   
);
    import pronoc_pkg::*;
    localparam  
        P_1 = P-1,
        CONG_ALw = CONGw* P;   //  congestion width per router;
    
    input [CONG_ALw-1 : 0] congestion_in_all;
    output [PPSw-1 : 0] port_pre_sel;    
    /*************
    *  N
    * Q1 | Q3
    * w--------E
    * Q0 | Q2
    *  S
    ***************/
    localparam 
        Q3 = 3,
        Q1 = 1,
        Q2 = 2,
        Q0 = 0;  
        
    localparam 
        XDIR =1'b0,
        YDIR =1'b1;
    wire [CONGw-1 : 0] congestion_in [P-1 : 0];   
    genvar i;
    generate
        for(i=0;i<P;i=i+1) begin :P_
            assign congestion_in[i] = congestion_in_all[CONGw*(i+1)-1 : CONGw*i];
        end         
    endgenerate
    
    wire [(CONGw/2)-1 : 0]cong_from_west_Q1   , cong_from_west_Q0;
    wire [(CONGw/2)-1 : 0]cong_from_south_Q0  , cong_from_south_Q2;
    wire [(CONGw/2)-1 : 0]cong_from_east_Q2   , cong_from_east_Q3; 
    wire [(CONGw/2)-1 : 0]cong_from_north_Q3  , cong_from_north_Q1;
    
    assign {cong_from_west_Q1   ,cong_from_west_Q0  }=congestion_in[WEST];
    assign {cong_from_south_Q0  ,cong_from_south_Q2 }=congestion_in[SOUTH];
    assign {cong_from_east_Q2   ,cong_from_east_Q3  }=congestion_in[EAST];
    assign {cong_from_north_Q3  ,cong_from_north_Q1 }=congestion_in[NORTH];
    /****************
    *congestion: 
    *      0: list congested
    *      3: most congested
    *pre_sel
    *      0: xdir
    *      1: ydir
    ********************/
    wire [P_1-1 : 0] conjestion_cmp;
    assign conjestion_cmp[Q3] = (cong_from_east_Q3  >  cong_from_north_Q3)? YDIR :XDIR;
    assign conjestion_cmp[Q2] = (cong_from_east_Q2  >  cong_from_south_Q2)? YDIR :XDIR;
    assign conjestion_cmp[Q1] = (cong_from_west_Q1  >  cong_from_north_Q1)? YDIR :XDIR;
    assign conjestion_cmp[Q0] = (cong_from_west_Q0  >  cong_from_south_Q0)? YDIR :XDIR;
    assign port_pre_sel = conjestion_cmp;
endmodule

/***********************
* port_pre_sel_gen
************************/
module port_pre_sel_gen #(
    parameter P=5
)(
    port_pre_sel,
    ovc_status,
    congestion_in_all,
    credit_decreased_all,
    credit_increased_all,
    reset,
    clk
);
    import pronoc_pkg::*;
    localparam 
        PV = P * V,
        CONG_ALw = CONGw * P;
    output [PPSw-1 : 0] port_pre_sel;
    input [PV-1 : 0] ovc_status;
    input [PV-1 : 0] credit_decreased_all;
    input [PV-1 : 0] credit_increased_all;
    input [CONG_ALw-1 : 0] congestion_in_all;  
    input reset,clk;
    
    generate
    if( IS_DETERMINISTIC ) begin : detrministic
        assign port_pre_sel = {PPSw{1'b0}};
    end else begin : adaptive
        if(CONGESTION_INDEX==0) begin:indx0
            port_presel_based_dst_ports_vc #(
                .P(P)
            ) port_presel_gen (
                .ovc_status (ovc_status [PV-1 : V]),
                .port_pre_sel(port_pre_sel)
            );
        end else if(CONGESTION_INDEX==1) begin :indx1
            port_presel_based_dst_ports_credit #(
                .P(P)
            ) port_presel_gen (
                .credit_decreased_all (credit_decreased_all [PV-1 : V]),//remove local port signals
                .credit_increased_all(credit_increased_all [PV-1 : V]),
                .port_pre_sel(port_pre_sel),
                .clk(clk),
                .reset(reset)
            );
        end else if (
            (CONGESTION_INDEX==2) || (CONGESTION_INDEX==3) ||
            (CONGESTION_INDEX==4) || (CONGESTION_INDEX==5) ||
            (CONGESTION_INDEX==6) || (CONGESTION_INDEX==7) || 
            (CONGESTION_INDEX==9) ||
            (CONGESTION_INDEX==11)|| (CONGESTION_INDEX==12))      begin :dst_vc
            regular_topo_port_presel_based_dst_routers_vc #(
                .P(P)
            ) port_presel_gen (
                .congestion_in_all(congestion_in_all),
                .port_pre_sel(port_pre_sel),
                .reset(reset),
                .clk(clk)
            );
        end else if((CONGESTION_INDEX==8) || (CONGESTION_INDEX==10) )begin :dst_ovc
            port_presel_based_dst_routers_ovc #(
                .P(P)
            ) port_presel_gen (
                .port_pre_sel(port_pre_sel),
                .congestion_in_all(congestion_in_all)
            );
        end 
    end 
    endgenerate
endmodule

/*******************************
*   congestion based on number of active ivc 
*       CONGESTION_INDEX==2  CONGw = 2
*       CONGESTION_INDEX==3  CONGw = 3
* ********************************/
module congestion_out_based_ivc_req #(
    parameter P=5
)(
    ivc_request_all,
    congestion_out_all  
);
    import pronoc_pkg::*;
    localparam  
        PV = (V*P),
        CONG_ALw = (CONGw* P);   //  congestion width per router;
    
    input [PV-1 : 0] ivc_request_all;
    output [CONG_ALw-1 : 0] congestion_out_all;
    wire [CONGw-1 : 0] congestion_out ;
    
    parallel_count_normalize #(
        .INw (PV),
        .OUTw (CONGw) 
    ) ivc_req_counter  (
        .D_in(ivc_request_all),
        .Q_out(congestion_out)
    );
    
    assign  congestion_out_all = {P{congestion_out}};     
endmodule

/*******************************
*    congestion based on number of
* active ivc requests that are not granted    
*     CONGESTION_INDEX==4  CONGw = 2
*     CONGESTION_INDEX==5  CONGw = 3
 ********************************/
module congestion_out_based_ivc_notgrant #(
    parameter P=5
)(
    ivc_request_all,
    congestion_out_all,
    ivc_num_getting_sw_grant,
    clk,
    reset  
);
    import pronoc_pkg::*;
    localparam  
        PV = (V * P),
        CONG_ALw = CONGw* P,   //  congestion width per router;
        IVC_CNTw = log2(PV+1);
    
    input [PV-1 : 0] ivc_request_all,ivc_num_getting_sw_grant; 
    output [CONG_ALw-1 : 0] congestion_out_all;                 
    input clk,reset;
    
    wire [IVC_CNTw-1 : 0] ivc_req_num;
    reg [CONGw-1 : 0] congestion_out ; 
    logic [PV-1 : 0] ivc_request_not_granted; 
    always_ff @ (`pronoc_clk_reset_edge )begin 
        if(`pronoc_reset) begin 
            ivc_request_not_granted <= {PV{1'b0}};
        end else begin
            ivc_request_not_granted <= ivc_request_all & ~ivc_num_getting_sw_grant;
        end
    end
    
    accumulator #(
        .INw(PV),
        .OUTw(IVC_CNTw),
        .NUM(PV)
    ) ivc_req_counter (
        .in_all(ivc_request_not_granted),
        .sum_o(ivc_req_num)
    );
    
    generate 
    if(CONGw==2)begin :w2
        always @(*)begin
            if      (ivc_req_num <= (PV/10) )   congestion_out=2'd0;    //0~10
            else if (ivc_req_num <= (PV/5)  )   congestion_out=2'd1;    //10~20
            else if (ivc_req_num <= (PV/2)  )   congestion_out=2'd2;    //20~50
            else                                congestion_out=2'd3;    //50~100
        end
    end else begin :w3 // CONGw==3
        always @(*)begin
            if      (ivc_req_num < ((PV*1)/8) )   congestion_out=3'd0;    
            else if (ivc_req_num < ((PV*2)/8) )   congestion_out=3'd1;    
            else if (ivc_req_num < ((PV*3)/8) )   congestion_out=3'd2;    
            else if (ivc_req_num < ((PV*4)/8) )   congestion_out=3'd3;    
            else if (ivc_req_num < ((PV*5)/8) )   congestion_out=3'd4;      
            else if (ivc_req_num < ((PV*6)/8) )   congestion_out=3'd5;   
            else if (ivc_req_num < ((PV*7)/8) )   congestion_out=3'd6;    
            else                                  congestion_out=3'd7;     
        end  
    end
    endgenerate       
    assign  congestion_out_all = {P{congestion_out}};     
endmodule

/*******************************
*     congestion based on number of
* availabe ovc in all 3ports of next router   
*     CONGESTION_INDEX==6 CONGw=2
*     CONGESTION_INDEX==7 CONGw=3
*********************************/
module congestion_out_based_other_port_avb_ovc #(
    parameter P=5
)(
    ovc_avalable_all,
    congestion_out_all   
);
    import pronoc_pkg::*;
    localparam
        PV = (V * P),
        CONG_ALw = CONGw* P;
        
    input [PV-1 : 0] ovc_avalable_all; 
    output [CONG_ALw-1 : 0] congestion_out_all;                 
    
    wire [PV-1 : 0] ovc_not_avb_all;
    wire [PV-1 : 0] counter_in [P-1 : 0];
    wire [CONGw-1 : 0] congestion_out[P-1 : 0];
    assign  ovc_not_avb_all = ~ovc_avalable_all;
    genvar i;
    generate 
    for (i=0;i<P;i=i+1) begin : P_
        localparam [PV-1:0] MASK = 
            (i==LOCAL) ? '0 : 
            {PV{1'b1}} & ~({V{1'b1}}) & ~({V{1'b1}} << (i));//mask local and cuurent port
            assign counter_in[i] = ovc_not_avb_all & MASK;
        parallel_count_normalize #(
            .INw(PV),
            .MAX_IN(PV - 2*V),
            .OUTw(CONGw)
        )  ovc_avb_east  (
            .D_in(counter_in[i]),
            .Q_out(congestion_out_all[CONGw*i +: CONGw])
        );   
    end
    endgenerate
endmodule

/*******************************
*     congestion based on number of
* availabe ovc in destination router   
*     CONGESTION_INDEX==8  CONGw=2
********************************/
module congestion_out_based_avb_ovc_w2 #(
    parameter P=5
)(
    ovc_avalable_all,
    congestion_out_all   
);
    import pronoc_pkg::*;
    localparam 
        CONGw=2, //congestion width per port
        P_1 = P-1,
        PV = (V * P),
        CONG_ALw = CONGw* P,
        CNT_Iw = 2*V;    
    input [PV-1 : 0] ovc_avalable_all; 
    output [CONG_ALw-1 : 0] congestion_out_all;                 
    
    localparam 
        Q3 = 3,
        Q1 = 1,
        Q2 = 2,
        Q0 = 0;  
    
    wire [V-1 : 0] ovc_not_avb [P-1 : 0];
    wire [CNT_Iw-1 : 0] counter_in [P_1-1 : 0];
    wire [CONGw-1 : 0] congestion_out [P-1 : 0];
    wire [P_1-1 : 0] threshold;
    assign  {ovc_not_avb[SOUTH], ovc_not_avb[WEST], ovc_not_avb[NORTH],  ovc_not_avb[EAST],ovc_not_avb[LOCAL]}= ~ovc_avalable_all;  
    assign  counter_in[Q3] ={ovc_not_avb[EAST ],ovc_not_avb[NORTH]};
    assign  counter_in[Q1] ={ovc_not_avb[NORTH],ovc_not_avb[WEST ]};
    assign  counter_in[Q2] ={ovc_not_avb[SOUTH],ovc_not_avb[EAST ]};
    assign  counter_in[Q0] ={ovc_not_avb[WEST ],ovc_not_avb[SOUTH]};
    genvar i;
    generate
    for (i=0;i<4;i=i+1) begin :lp
        parallel_count_normalize #(
            .INw(CNT_Iw),
            .OUTw(1)
        ) ovc_not_avb_cnt (
            .D_in(counter_in[i]),
            .Q_out(threshold[i])
        );   
    end
    endgenerate
    assign congestion_out[LOCAL] = '0;
    assign congestion_out[EAST]  = {threshold[Q1],threshold[Q0]};
    assign congestion_out[NORTH] = {threshold[Q0],threshold[Q2]};
    assign congestion_out[WEST]  = {threshold[Q2],threshold[Q3]};
    assign congestion_out[SOUTH] = {threshold[Q3],threshold[Q1]};
    assign congestion_out_all    = {congestion_out[SOUTH],congestion_out[WEST],congestion_out[NORTH],congestion_out[EAST],congestion_out[LOCAL]};   
endmodule

/*******************************
* 
*     congestion based on number of
* availabe ovc in destination router   
*     CONGESTION_INDEX==9  CONGw=3
*********************************/
module congestion_out_based_avb_ovc_w3 #(
    parameter P=5
)(
    ovc_avalable_all,
    congestion_out_all   
);
    import pronoc_pkg::*;
    localparam 
        CONGw=3, //congestion width per port
        P_1 = P-1,
        PV = (V * P),
        CONG_ALw = CONGw* P;
        
    input [PV-1 : 0] ovc_avalable_all; 
    output [CONG_ALw-1 : 0] congestion_out_all;                 
    
    wire [V-1 : 0] ovc_not_avb [P-1 : 0];
    wire [CONGw-1 : 0] congestion_out[P-1 : 0];
    wire [P_1-1 : 0] threshold;
    assign  {ovc_not_avb[SOUTH],  ovc_not_avb[WEST], ovc_not_avb[NORTH],   ovc_not_avb[EAST]}=~ovc_avalable_all[PV-1 : V];
    genvar i;
    generate 
    for (i=0;i<4;i=i+1) begin :lp
        parallel_count_normalize #(
            .INw(V),
            .OUTw(1)
        ) ovc_avb_east(
            .D_in(ovc_not_avb[i]),
            .Q_out(threshold[i])
        );   
    end
    endgenerate
    
    assign congestion_out[EAST] = {threshold[NORTH],threshold[WEST ],threshold[SOUTH]};
    assign congestion_out[NORTH] = {threshold[WEST ],threshold[SOUTH],threshold[EAST ]};
    assign congestion_out[WEST] = {threshold[SOUTH],threshold[EAST ],threshold[NORTH]};
    assign congestion_out[SOUTH] = {threshold[EAST ],threshold[NORTH],threshold[WEST ]};
    assign  congestion_out_all = {congestion_out[SOUTH],congestion_out[WEST],congestion_out[NORTH],congestion_out[EAST],{CONGw{1'b0}}};   
endmodule

/*******************************
*     congestion based on number of
* availabe ovc in destination router   
*     CONGESTION_INDEX==10  CONGw=4
*********************************/
module congestion_out_based_avb_ovc_w4 #(
    parameter P=5
)(
    ovc_avalable_all,
    congestion_out_all   
);
    import pronoc_pkg::*;
    localparam 
        CONGw=4, //congestion width per port
        P_1 = P-1,
        PV = (V * P),
        CONG_ALw = CONGw* P,
        CNT_Iw = 2*V;    
    input [PV-1 : 0] ovc_avalable_all; 
    output [CONG_ALw-1 : 0] congestion_out_all;                 
    
    localparam
        Q3 = 3,
        Q1 = 1,
        Q2 = 2,
        Q0 = 0;  
    
    wire [V-1 : 0] ovc_not_avb [P-1 : 0];
    wire [CNT_Iw-1 : 0] counter_in [P_1-1 : 0];
    wire [CONGw-1 : 0] congestion_out [P-1 : 0];
    wire [1 : 0] threshold [P_1-1 : 0];
    assign  {ovc_not_avb[SOUTH], ovc_not_avb[WEST], ovc_not_avb[NORTH],  ovc_not_avb[EAST],ovc_not_avb[LOCAL]}= ~ovc_avalable_all;  
    assign  counter_in[Q3] ={ovc_not_avb[EAST ],ovc_not_avb[NORTH]};
    assign  counter_in[Q1] ={ovc_not_avb[NORTH],ovc_not_avb[WEST ]};
    assign  counter_in[Q2] ={ovc_not_avb[SOUTH],ovc_not_avb[EAST ]};
    assign  counter_in[Q0] ={ovc_not_avb[WEST ],ovc_not_avb[SOUTH]};
    genvar i;
    generate
    for (i=0;i<4;i=i+1) begin :lp
        parallel_count_normalize #(
            .INw(CNT_Iw),
            .OUTw(2)
        ) ovc_not_avb_cnt (
            .D_in(counter_in[i]),
            .Q_out(threshold[i])
        );   
    end
    endgenerate
    assign congestion_out[LOCAL] = '0;
    assign congestion_out[EAST] = {threshold[Q1],threshold[Q0]};
    assign congestion_out[NORTH] = {threshold[Q0],threshold[Q2]};
    assign congestion_out[WEST] = {threshold[Q2],threshold[Q3]};
    assign congestion_out[SOUTH] = {threshold[Q3],threshold[Q1]};
    assign congestion_out_all = {congestion_out[SOUTH],congestion_out[WEST],congestion_out[NORTH],congestion_out[EAST],congestion_out[LOCAL]};   
endmodule


/*******************************
*    congestion based on number of 
*    availabe ovc and not granted
*        ivc in next router  
*    CONGESTION_INDEX==11 CONGw=2
*    CONGESTION_INDEX==12 CONGw=3
*********************************/
module congestion_out_based_avb_ovc_not_granted_ivc #(
    parameter P=5
)(
    ovc_avalable_all,
    ivc_request_all,
    ivc_num_getting_sw_grant,
    clk,
    reset,    
    congestion_out_all   
);
    import pronoc_pkg::*;
    localparam
        P_1 = P-1,
        PV = (V * P),
        CONG_ALw = CONGw* P,
        CNT_Iw = 3*V,
        CNT_Ow = log2((3*V)+1),
        CNG_w = log2((6*V)+1),
        CNT_Vw = log2(V+1);
        
    input [PV-1 : 0] ovc_avalable_all; 
    output [CONG_ALw-1 : 0] congestion_out_all;                 
    input [PV-1 : 0] ivc_request_all,ivc_num_getting_sw_grant; 
    input                    reset,clk;
    // counting not available ovc            
    wire [V-1 : 0] ovc_not_avb [P-1 : 0];
    wire [CNT_Iw-1 : 0] counter_in [P-1 : 0];
    wire [CNT_Ow-1 : 0] counter_o [P-1 : 0];
    wire [CONGw-1 : 0] congestion_out[P-1 : 0];
    assign  {ovc_not_avb[SOUTH], ovc_not_avb[WEST], ovc_not_avb[NORTH],  ovc_not_avb[EAST],ovc_not_avb[LOCAL]}= ~ovc_avalable_all;  
    assign  counter_in[LOCAL] ='0;
    assign  counter_in[EAST] ={ovc_not_avb[NORTH],ovc_not_avb[WEST] ,ovc_not_avb[SOUTH]};
    assign  counter_in[NORTH] ={ovc_not_avb[EAST] ,ovc_not_avb[WEST] ,ovc_not_avb[SOUTH]};
    assign  counter_in[WEST] ={ovc_not_avb[EAST] ,ovc_not_avb[NORTH] ,ovc_not_avb[SOUTH]};
    assign  counter_in[SOUTH] ={ovc_not_avb[EAST] ,ovc_not_avb[NORTH] ,ovc_not_avb[WEST]};
    
    // counting not granted requests
    logic [PV-1 : 0] ivc_request_not_granted; 
    wire [V-1 : 0] ivc_not_grnt [P-1 : 0];
    wire [CNT_Vw-1 : 0] ivc_not_grnt_num [P-1 : 0];
    
    always_ff @ (`pronoc_clk_reset_edge )begin 
        if(`pronoc_reset) begin 
            ivc_request_not_granted <= {PV{1'b0}};
        end else begin
            ivc_request_not_granted <= ivc_request_all & ~ivc_num_getting_sw_grant;
        end
    end
    
    assign  {ivc_not_grnt[SOUTH], ivc_not_grnt[WEST], ivc_not_grnt[NORTH],ivc_not_grnt[EAST],ivc_not_grnt[LOCAL]}= ivc_request_not_granted;  
    genvar i;
    generate 
    for (i=0;i<P;i=i+1) begin :P_
        accumulator #(
            .INw(CNT_Iw),
            .OUTw(CNT_Ow),
            .NUM(CNT_Iw)
        ) ovc_counter (
            .in_all(counter_in[i]),
            .sum_o(counter_o[i])
        );
        accumulator #(
            .INw(V),
            .OUTw(CNT_Vw),
            .NUM(V)
        ) ivc_counter (
            .in_all(ivc_not_grnt[i]),
            .sum_o(ivc_not_grnt_num[i])
        );
        wire [CNG_w-1 : 0] congestion_num [P-1 : 0];
        assign congestion_num [i] = counter_o[i] + ivc_not_grnt_num[i] + {ivc_not_grnt_num[i],1'b0};
        normalizer #(
            .MAX_IN(6*V),
            .INw(CNG_w),
            .OUTw(CONGw)
        )norm (
            .D_in(congestion_num [i]),
            .Q_out(congestion_out[i])
        );
    end//for
    endgenerate
    assign  congestion_out_all = {congestion_out[SOUTH],congestion_out[WEST],congestion_out[NORTH],congestion_out[EAST],{CONGw{1'b0}}};   
endmodule

/**********************
*    parallel_count_normalize
**********************/
module parallel_count_normalize #(
    parameter INw = 12,
    parameter MAX_IN=INw,
    parameter OUTw= 2
)(
    D_in,
    Q_out
);
    function integer log2;
    input integer number; begin   
        log2=(number <=1) ? 1: 0;    
        while(2**log2<number) begin    
            log2=log2+1;    
        end        
    end   
    endfunction // log2 
    
    input [INw-1 : 0] D_in;
    output [OUTw-1 : 0] Q_out;
    localparam CNTw = log2(INw+1);
    wire [CNTw-1 : 0] counter;
    accumulator #(
        .INw(INw),
        .OUTw(CNTw),
        .NUM(INw)
    ) ovc_avb_cnt (
        .in_all(D_in),
        .sum_o(counter)
    );
    
    normalizer #(
        .MAX_IN(MAX_IN),
        .INw(CNTw),
        .OUTw(OUTw)
    )norm (
        .D_in(counter),
        .Q_out(Q_out)
    );
endmodule    

/**************
*   normalizer
***************/
module normalizer #(
    parameter INw   = 5,
    parameter MAX_IN = 10,
    parameter OUTw  = 2
)(
    input  logic [INw-1:0] D_in,
    output logic [OUTw-1:0] Q_out
);
    localparam OUT_ON_HOT_NUM = 2 ** OUTw;
    localparam [INw-1 : 0] MAX = (MAX_IN > (2**INw)-1) ? {INw{1'b1}} : INw'(MAX_IN);
    // One-hot output
    logic [OUT_ON_HOT_NUM-1:0] one_hot_out;
    // Saturate input
    logic [INw-1:0] D_clamped;
    assign D_clamped = (D_in > MAX) ? MAX : D_in;
    // Generate one-hot bins
    genvar i;
    generate
    for (i = 0; i < OUT_ON_HOT_NUM; i++) begin : BIN_GEN
        localparam LOW  = (MAX_IN * i)     / OUT_ON_HOT_NUM;
        localparam HIGH = (MAX_IN * (i+1)) / OUT_ON_HOT_NUM;
        assign one_hot_out[i] =
            (i == 0) ?  (D_clamped < INw'(HIGH)) :   // first bin: include MIN_IN
            (i == OUT_ON_HOT_NUM-1) ?  (D_clamped >= INw'(LOW)) :   // last bin: include MAX_IN
            (D_clamped >= INw'(LOW)) && (D_clamped < INw'(HIGH));
    end
    endgenerate
    // Convert one-hot to binary
    one_hot_to_bin #(
        .ONE_HOT_WIDTH(OUT_ON_HOT_NUM)
    ) cnv (
        .one_hot_code(one_hot_out),
        .bin_code(Q_out)
    );
endmodule



/**************************
*    congestion_out_gen
*************************/
module congestion_out_gen #(
    parameter P=5
)(
    ivc_request_all, 
    ivc_num_getting_sw_grant,
    ovc_avalable_all,
    congestion_out_all,
    clk,
    reset
);
    import pronoc_pkg::*;
    localparam 
        PV = P*V,
        CONG_ALw = CONGw* P;   //  congestion width per router;;
    
    input [PV-1 : 0] ovc_avalable_all; 
    input [PV-1 : 0] ivc_request_all;    
    input [PV-1 : 0] ivc_num_getting_sw_grant; 
    output reg [CONG_ALw-1 : 0] congestion_out_all;                 
    input clk,reset;
    
    wire [CONG_ALw-1 : 0] congestion_out_all_next;  
    wire [V-1 : 0] ovc_avalable [P-1 : 0];
    genvar i;
    generate
    for (i=0;i<P;i=i+1) begin :lp
        assign ovc_avalable[i]= ovc_avalable_all[(i*V)+:V];
    end
    if(ROUTE_TYPE != "DETERMINISTIC") begin :adpt
        if((CONGESTION_INDEX==2) || (CONGESTION_INDEX==3)) begin :based_ivc
            congestion_out_based_ivc_req #(
                .P(P)
            ) the_congestion_out_gen (
                .ivc_request_all(ivc_request_all),
                .congestion_out_all(congestion_out_all_next)
            );
        end else if((CONGESTION_INDEX==4) || (CONGESTION_INDEX==5)) begin :based_ng_ivc
            congestion_out_based_ivc_notgrant #(
                .P(P)
            )  the_congestion_out_gen (
                .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant),
                .ivc_request_all(ivc_request_all),
                .congestion_out_all(congestion_out_all_next),
                .clk(clk),
                .reset(reset)
            );
        end else if  ((CONGESTION_INDEX==6) || (CONGESTION_INDEX==7)) begin :avb_ovc1
            congestion_out_based_other_port_avb_ovc#(
                .P(P)
            ) the_congestion_out_gen (      
                .ovc_avalable_all(ovc_avalable_all),
                .congestion_out_all(congestion_out_all_next)
            );
        end  else if  (CONGESTION_INDEX==8) begin :indx8
            congestion_out_based_avb_ovc_w2 #(
                .P(P)
            ) the_congestion_out_gen (
                .ovc_avalable_all(ovc_avalable_all),
                .congestion_out_all(congestion_out_all_next)   
            );
        end  else if  (CONGESTION_INDEX==9) begin :indx9
            congestion_out_based_avb_ovc_w3 #(
                .P(P)
            ) the_congestion_out_gen (
                .ovc_avalable_all(ovc_avalable_all),
                .congestion_out_all(congestion_out_all_next)   
            );
        end  else if  (CONGESTION_INDEX==10) begin :indx10
            congestion_out_based_avb_ovc_w4 #(
                .P(P)
            ) the_congestion_out_gen (
                .ovc_avalable_all(ovc_avalable_all),
                .congestion_out_all(congestion_out_all_next)
            );
        end  else if  (CONGESTION_INDEX==11 || CONGESTION_INDEX==12) begin :indx11
            congestion_out_based_avb_ovc_not_granted_ivc #(
                .P(P)
            ) the_congestion_out_gen (
                .ovc_avalable_all(ovc_avalable_all),
                .ivc_request_all(ivc_request_all),
                .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant),
                .clk(clk),
                .reset(reset),    
                .congestion_out_all(congestion_out_all_next)
            );
        end  else begin :nocong assign  congestion_out_all_next = {CONG_ALw{1'b0}};   end
    end else begin :dtrmn
        assign  congestion_out_all_next = {CONG_ALw{1'b0}};
    end
    endgenerate
    always_ff @ (`pronoc_clk_reset_edge )begin 
        if(`pronoc_reset) begin 
            congestion_out_all <= {CONG_ALw{1'b0}};
        end else begin
            congestion_out_all <= congestion_out_all_next;
        end
    end
endmodule


/*************************
*    deadlock_detector
**************************/
module  deadlock_detector #(
    parameter P=5,
    parameter MAX_CLK = 16
)(
    ivc_num_getting_sw_grant,
    ivc_request_all,
    reset,
    clk,
    detect
);
    import pronoc_pkg::*;
    localparam  
        PV = P*V,
        CNTw = log2(MAX_CLK);
    input [PV-1 : 0] ivc_num_getting_sw_grant, ivc_request_all;
    input      reset,clk;
    output       detect;
    
    logic [CNTw-1 : 0] counter [V-1 : 0];
    reg [CNTw-1 : 0] counter_next [V-1 : 0];
    wire [P-1 : 0] counter_rst_gen [V-1 : 0];
    wire [P-1 : 0] counter_en_gen [V-1 : 0];
    wire [V-1 : 0] counter_rst,counter_en,detect_gen;
    logic [PV-1 : 0] ivc_num_getting_sw_grant_reg;
    always_ff @ (`pronoc_clk_reset_edge )begin 
        if(`pronoc_reset) begin 
            ivc_num_getting_sw_grant_reg <= {PV{1'b0}};
        end else begin
            ivc_num_getting_sw_grant_reg <= ivc_num_getting_sw_grant;
        end
    end
    
    //seperate all same virtual chanels requests
    genvar i,j;
    generate 
    for (i=0;i<V;i=i+1)begin:V_
        for (j=0;j<P;j=j+1)begin :P_
            assign counter_rst_gen[i][j]=ivc_num_getting_sw_grant_reg[j*V+i];
            assign counter_en_gen [i][j]=ivc_request_all[j*V+i];
        end//j
        //sum all signals belong to the same VC
        assign counter_rst[i] =|counter_rst_gen[i];
        assign counter_en[i] =|counter_en_gen [i]; 
        // generate the counter
        always @ (*) begin 
            counter_next[i] = counter[i];
            if(counter_rst[i])      counter_next[i] = {CNTw{1'b0}};
            else if(counter_en[i])  counter_next[i] = counter[i]+1'b1;
        end//always
        
        always_ff @ (`pronoc_clk_reset_edge )begin 
            if(`pronoc_reset) begin 
                counter[i] <= {CNTw{1'b0}};
            end else begin
                counter[i] <= counter_next[i];
            end
        end
        // check counters value to detect deadlock
        assign detect_gen[i] = (counter[i]== MAX_CLK-1);
    end//i 
    endgenerate
    assign detect=|detect_gen;
endmodule
