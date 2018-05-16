`timescale	1ns/1ps
/**********************************************************************
**	File:  congestion_analyzer.v
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
**	This file includes all files for getting congestion information and
**	Port selection modules for supporting adaptive routing 
**
**************************************************************/




                                    /*****************************
                                    
                                                port_presel
                                    
                                    *****************************/



/***************************************
        
     port_presel_based_dst_ports_vc
          CONGESTION_INDEX==0
***************************************/


//congestion analyzer based on number of occupied VCs
module   port_presel_based_dst_ports_vc #(
    parameter P   =   5,
    parameter V   =   4
    )
    (
        ovc_status,
        port_pre_sel
     );
     
    
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
         
    localparam  P_1     =       P-1,
                P_1V    =       P_1*V,
                CNTw    =       log2(V+1);
     
    input   [P_1V-1     :   0]  ovc_status; 
    output  [P_1-1      :   0]  port_pre_sel;
    wire    [P_1-1      :   0]  conjestion_cmp;
    //VC counter on all ports exept the local    
    wire    [V-1        :   0]  ovc_status_per_port [P-1-1  :   0];
    wire    [CNTw -1    :   0]  vc_counter          [P_1-1  :   0];
    
    genvar i;
    generate
        for( i= 0;i<P_1;i=i+1) begin : p_loop
                //seperate all credit counters 
               
                assign ovc_status_per_port[i]   = ovc_status[(i+1)*V-1       :   i*V];
                //count number of busy OVCs
                parallel_counter #(
                    .IN_WIDTH(V)
                )counter
                (
                    .in    (ovc_status_per_port[i]),
                    .out   (vc_counter[i])
                );
                
               
                
       end//for
    endgenerate
/*******************    
pre-sel[xy]
    y
1   |   3
    |
 -------x
0   |   2
    |    
    
    
pre_sel
             0: xdir is preferable
             1: ydir is preferable
*******************/

   
  
    //location in counter  
    localparam X_PLUS   =   0,//EAST
               Y_PLUS   =   1,//NORTH
               X_MINUS  =   2,//WEST
               Y_MINUS  =   3;//SOUTH
               
    //location in port-pre-select           
    localparam X_PLUS_Y_PLUS  = 3,
               X_MINUS_Y_PLUS = 1,
               X_PLUS_Y_MINUS = 2,
               X_MINUS_Y_MINUS= 0;
               
    assign conjestion_cmp[X_PLUS_Y_PLUS]  = (vc_counter[X_PLUS]   >  vc_counter[Y_PLUS]);
    assign conjestion_cmp[X_MINUS_Y_PLUS] = (vc_counter[X_MINUS]  >  vc_counter[Y_PLUS]);
    assign conjestion_cmp[X_PLUS_Y_MINUS] = (vc_counter[X_PLUS]   >  vc_counter[Y_MINUS]);
    assign conjestion_cmp[X_MINUS_Y_MINUS]= (vc_counter[X_MINUS]  >  vc_counter[Y_MINUS]);
    
    //assign port_pre_sel = conjestion_cmp;
    
   
    assign port_pre_sel = conjestion_cmp;
   
     
         
     
   
 endmodule
         
/*************************************
*
*    port_presel_based_dst_ports_credit
*           CONGESTION_INDEX==1
*************************************/


//congestion analyzer based on number of total available credit of a port
module  port_presel_based_dst_ports_credit #(
    parameter P =   5,
    parameter V =   4,
    parameter B =   4
) 
(
    credit_decreased_all,
    credit_increased_all,
    port_pre_sel,
    clk,
    reset
);


    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
    
    localparam  P_1     =       P-1,
                P_1V    =       (P_1)*V,
                BV      =       B*V,
                BV_1    =       BV-1,
                BVw     =       log2(BV);
                
   localparam [BVw-1    :   0] C_INT    =  BV_1 [BVw-1    :   0]; 
   
   
   input    [P_1V-1 :   0]  credit_decreased_all;  
   input    [P_1V-1 :   0]  credit_increased_all; 
   input                    reset,clk;
   output   [P_1-1  :   0]  port_pre_sel;
   
   
   
    reg     [BVw-1  :   0]  credit_per_port_next    [P_1-1    :   0];
    reg     [BVw-1  :   0]  credit_per_port         [P_1-1    :   0];
    wire    [P_1-1  :   0]  credit_increased_per_port;
    wire    [P_1-1  :   0]  credit_decreased_per_port;
    wire    [P_1-1  :   0]  conjestion_cmp;
  
     
    genvar i;
    generate   
        for(i=0;   i<P_1; i=i+1) begin :sep
           
           assign  credit_increased_per_port[i]=|credit_increased_all[((i+1)*V)-1   : i*V];
           assign  credit_decreased_per_port[i]=|credit_decreased_all[((i+1)*V)-1   : i*V];
        end//for
    endgenerate//always
    
    integer k; 
            
    always @(*) begin
        for(k=0;    k<P; k=k+1'b1) begin 
            credit_per_port_next[k]  =   credit_per_port[k];
            if(credit_increased_per_port[k]  & ~credit_decreased_per_port[k]) begin 
                credit_per_port_next[k]  = credit_per_port[k]+1'b1;
            end else if (~credit_increased_per_port[k]   & credit_decreased_per_port[k])begin 
                credit_per_port_next[k]  = credit_per_port[k]-1'b1;
            end
        end//for
    end//always
    
    always @(posedge clk or posedge reset) begin
        for(k=0;    k<P_1; k=k+1'b1) begin 
            if(reset) begin 
                credit_per_port[k]   <=  C_INT;
            end else begin 
                credit_per_port[k]   <=  credit_per_port_next[k];
            end
        end//for
    end
    
    /*******************    
pre-sel[xy]
    y
1   |   3
    |
 -------x
0   |   2
    |    
    
    
pre_sel
             0: xdir
             1: ydir
*******************/
    
    //location in counter  
    localparam X_PLUS   =   0,//EAST
               Y_PLUS   =   1,//NORTH
               X_MINUS  =   2,//WEST
               Y_MINUS  =   3;//SOUTH
               
    //location in port-pre-select           
    localparam X_PLUS_Y_PLUS  = 3,
               X_MINUS_Y_PLUS = 1,
               X_PLUS_Y_MINUS = 2,
               X_MINUS_Y_MINUS= 0;
               
    assign conjestion_cmp[X_PLUS_Y_PLUS]  = (credit_per_port[X_PLUS]   <  credit_per_port[Y_PLUS]);
    assign conjestion_cmp[X_MINUS_Y_PLUS] = (credit_per_port[X_MINUS]  <  credit_per_port[Y_PLUS]);
    assign conjestion_cmp[X_PLUS_Y_MINUS] = (credit_per_port[X_PLUS]   <  credit_per_port[Y_MINUS]);
    assign conjestion_cmp[X_MINUS_Y_MINUS]= (credit_per_port[X_MINUS]  <  credit_per_port[Y_MINUS]);
          
  // assign port_pre_sel = conjestion_cmp;
   
     
    
     assign port_pre_sel = conjestion_cmp;
    
     
    
 endmodule  
 
 
/*********************************

port_presel_based_dst_routers_ovc
    CONGESTION_INDEX==2,3,4,5,6,7,9
********************************/ 
 
 
module port_presel_based_dst_routers_vc #(
    parameter P=5,
    parameter CONGw=2 //congestion width per port
)
(
    port_pre_sel,    
    congestion_in_all   
);
  
         
    localparam  P_1     =       P-1,
                CONG_ALw=       CONGw* P;   //  congestion width per router;
                
    localparam XDIR =1'b0;
    localparam YDIR =1'b1;
                               
//location in port-pre-select           
    localparam X_PLUS_Y_PLUS  = 3,
               X_MINUS_Y_PLUS = 1,
               X_PLUS_Y_MINUS = 2,
               X_MINUS_Y_MINUS= 0;            
                   
     
    
    input   [CONG_ALw-1 :   0]  congestion_in_all;
    output  [P_1-1      :   0]  port_pre_sel;
    
    wire    [CONGw-1    :   0]  congestion_x_plus,congestion_y_plus,congestion_x_min,congestion_y_min;
    wire    [P_1-1      :   0]  conjestion_cmp;
   
    
    assign {congestion_y_min,congestion_x_min,congestion_y_plus,congestion_x_plus} = congestion_in_all[CONG_ALw-1   : CONGw];
    
/****************
    congestion:  
             0: list congested
             3: most congested
    pre_sel
             0: xdir
             1: ydir
*******************/
    assign conjestion_cmp[X_PLUS_Y_PLUS]  = (congestion_x_plus  >  congestion_y_plus)? YDIR : XDIR;
    assign conjestion_cmp[X_MINUS_Y_PLUS] = (congestion_x_min   >  congestion_y_plus)? YDIR : XDIR;
    assign conjestion_cmp[X_PLUS_Y_MINUS] = (congestion_x_plus  >  congestion_y_min)?  YDIR : XDIR;
    assign conjestion_cmp[X_MINUS_Y_MINUS]= (congestion_x_min   >  congestion_y_min)?  YDIR : XDIR;

 
 
   
    assign port_pre_sel = conjestion_cmp;
       
 
 
endmodule


/*********************************

port_presel_based_dst_routers_ovc
    CONGESTION_INDEX==8,10
********************************/ 
 
 
module port_presel_based_dst_routers_ovc #(
    parameter P=5,
    parameter V=4,
    parameter CONGw=2 //congestion width per port
)
(
    port_pre_sel,    
    congestion_in_all   
);
  
         
    localparam  P_1     =       P-1,
                CONG_ALw=       CONGw* P;   //  congestion width per router;
       
    
    input   [CONG_ALw-1 :   0]  congestion_in_all;
    output  [P_1-1      :   0]  port_pre_sel;    
       
     
    
  
   /*************
        N
     Q1 | Q3
   w--------E
     Q0 | Q2
        S
   ***************/
   
    localparam Q3   = 3,
               Q1   = 1,
               Q2   = 2,
               Q0   = 0;  

    localparam EAST =   0,
               NORTH=   1,
               WEST =   2,
               SOUTH=   3;                         
                   
    localparam XDIR =1'b0,
               YDIR =1'b1;
    
    wire [CONGw-1   :   0] congestion_in [P_1-1 :   0];           
    assign {congestion_in[SOUTH],congestion_in[WEST],congestion_in[NORTH],congestion_in[EAST]} = congestion_in_all[CONG_ALw-1   : CONGw];               
   
    wire [(CONGw/2)-1   :   0]cong_from_west_Q1   , cong_from_west_Q0;
    wire [(CONGw/2)-1   :   0]cong_from_south_Q0  , cong_from_south_Q2;
    wire [(CONGw/2)-1   :   0]cong_from_east_Q2   , cong_from_east_Q3; 
    wire [(CONGw/2)-1   :   0]cong_from_north_Q3  , cong_from_north_Q1;
    

                
    assign {cong_from_west_Q1   ,cong_from_west_Q0  }=congestion_in[WEST];
    assign {cong_from_south_Q0  ,cong_from_south_Q2 }=congestion_in[SOUTH];
    assign {cong_from_east_Q2   ,cong_from_east_Q3  }=congestion_in[EAST];
    assign {cong_from_north_Q3  ,cong_from_north_Q1 }=congestion_in[NORTH];
    
    /****************
    congestion:  
             0: list congested
             3: most congested
    pre_sel
             0: xdir
             1: ydir
    *******************/            
     wire    [P_1-1      :   0]  conjestion_cmp;
     
     
 
    assign conjestion_cmp[Q3]  =  (cong_from_east_Q3  >  cong_from_north_Q3)? YDIR :XDIR;
    assign conjestion_cmp[Q2]  =  (cong_from_east_Q2  >  cong_from_south_Q2)? YDIR :XDIR;
    assign conjestion_cmp[Q1]  =  (cong_from_west_Q1  >  cong_from_north_Q1)? YDIR :XDIR;
    assign conjestion_cmp[Q0]  =  (cong_from_west_Q0  >  cong_from_south_Q0)? YDIR :XDIR;
  
                            

    
    
    
        assign port_pre_sel = conjestion_cmp;
   
       
     
 
 
endmodule

/***********************

    port_pre_sel_gen


************************/



module port_pre_sel_gen #(
    parameter P=5,
    parameter V=4,
    parameter B=4,
    parameter CONGESTION_INDEX=2,
    parameter CONGw=2,
    parameter ROUTE_TYPE="ADAPTIVE",
    parameter [V-1  :   0] ESCAP_VC_MASK= 4'b0001

)(
    port_pre_sel,
    ovc_status,
    ovc_avalable_all,
    congestion_in_all,
    credit_decreased_all,
    credit_increased_all,
    reset,
    clk

);

    localparam P_1      =   P-1,
               PV       =   P   *   V,
               CONG_ALw =   CONGw * P;

    output [P_1-1       :   0]  port_pre_sel;
    input  [PV-1        :   0]  ovc_status;
    input  [PV-1        :   0]  ovc_avalable_all;
    input  [PV-1        :   0]  credit_decreased_all;
    input  [PV-1        :   0]  credit_increased_all;
    input  [CONG_ALw-1 :    0]  congestion_in_all;  
    input  reset,clk;
    
    
generate
    /* verilator lint_off WIDTH */
    if(ROUTE_TYPE    ==   "DETERMINISTIC") begin : detrministic
    /* verilator lint_on WIDTH */
       assign port_pre_sel = {P_1{1'bx}};
    
    end else begin : adaptive
        if(CONGESTION_INDEX==0) begin:indx0
             
                port_presel_based_dst_ports_vc #(
                    .P(P),
                    .V(V)
                
                )
                port_presel_gen
                (
                    .ovc_status (ovc_status [PV-1   :   V]),
                    .port_pre_sel(port_pre_sel)
                    
        
                );
                
        end else if(CONGESTION_INDEX==1) begin :indx1
                      
                port_presel_based_dst_ports_credit #(
                    .P(P),
                    .V(V),
                    .B(B)
                ) 
                port_presel_gen
                (
                    .credit_decreased_all   (credit_decreased_all   [PV-1  :   V]),//remove local port signals
                    .credit_increased_all   (credit_increased_all   [PV-1  :   V]),
                    .port_pre_sel           (port_pre_sel),
                    .clk                    (clk),
                    .reset                  (reset)
                );
        end else if (   (CONGESTION_INDEX==2) || (CONGESTION_INDEX==3) ||
                        (CONGESTION_INDEX==4) || (CONGESTION_INDEX==5) ||
                        (CONGESTION_INDEX==6) || (CONGESTION_INDEX==7) || 
                        (CONGESTION_INDEX==9) ||
                        (CONGESTION_INDEX==11)|| (CONGESTION_INDEX==12))      begin :dst_vc
              
                port_presel_based_dst_routers_vc #(
                    .P(P),
                    .CONGw(CONGw)
                )
                port_presel_gen
                (                    
                    .congestion_in_all(congestion_in_all),
                    .port_pre_sel(port_pre_sel)
                );
          end else if((CONGESTION_INDEX==8) || (CONGESTION_INDEX==10) )begin :dst_ovc
            
            port_presel_based_dst_routers_ovc #(
                .P(P),
                .V(V),
                .CONGw(CONGw)
            )
             port_presel_gen
            (
                .port_pre_sel(port_pre_sel),    
                .congestion_in_all(congestion_in_all)   
            );
        
        
        end 
    end 
    endgenerate
endmodule

 
 
                                                    /*********************************
 
                                                            congestion_out_gen
 
                                                    ********************************/
                                                    
                                                    
                                                    
                                                    
 
 /*******************************
 
       congestion based on number of active ivc 
            CONGESTION_INDEX==2  CONGw   =   2
            CONGESTION_INDEX==3  CONGw   =   3
 ********************************/
 module congestion_out_based_ivc_req #(
    parameter P=5,
    parameter V=4,
    parameter CONGw   =   2 //congestion width per port
 
 )
 (
    ivc_request_all,
    congestion_out_all  
 
 );
    
 
    localparam  PV      =   (V     *  P),
                CONG_ALw=   (CONGw* P);   //  congestion width per router;
         
   
   
   
    input       [PV-1       :   0]  ivc_request_all; 
    output      [CONG_ALw-1 :   0]  congestion_out_all;                 
                
  
    wire    [CONGw-1    :   0]  congestion_out ;  
    
    parallel_count_normalize #(
        .INw    (PV),
        .OUTw   (CONGw) 
    )
    ivc_req_counter
    (
        .in     (ivc_request_all),
        .out    (congestion_out)

    );
    
    
           
    assign  congestion_out_all = {P{congestion_out}};     
 
endmodule




/*******************************
 
       congestion based on number of
 active ivc requests that are not granted    
            CONGESTION_INDEX==4  CONGw   =   2
            CONGESTION_INDEX==5  CONGw   =   3
 ********************************/
 module congestion_out_based_ivc_notgrant #(
    parameter P=5,
    parameter V=4,
    parameter CONGw=2 //congestion width per port
 
 )
 (
    ivc_request_all,
    congestion_out_all,
    ivc_num_getting_sw_grant,
    clk,
    reset  
 
 );

    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
 
    localparam  PV      =   (V     *  P),
                CONG_ALw=   CONGw* P,   //  congestion width per router;
                IVC_CNTw=   log2(PV+1);
    
   
   
   
    input       [PV-1       :   0]  ivc_request_all,ivc_num_getting_sw_grant; 
    output      [CONG_ALw-1 :   0]  congestion_out_all;                 
    input                           clk,reset;
                
    wire    [IVC_CNTw-1 :   0]  ivc_req_num;
    reg     [CONGw-1    :   0]  congestion_out ; 
    reg     [PV-1       :   0]  ivc_request_not_granted; 
    
    always @(posedge clk or posedge reset) begin 
        if(reset) begin 
            ivc_request_not_granted <= 0;
        end else begin 
            ivc_request_not_granted <= ivc_request_all & ~(ivc_num_getting_sw_grant);
        end//reset
    end //always
    
    
  
    
    parallel_counter #(
        .IN_WIDTH(PV)
    )
    ivc_req_counter
    (
        .in(ivc_request_not_granted),
        .out(ivc_req_num)
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
 
     congestion based on number of
 availabe ovc in all 3ports of next router   
            CONGESTION_INDEX==6 CONGw=2
            CONGESTION_INDEX==7 CONGw=3
 ********************************/
 module congestion_out_based_3port_avb_ovc #(
    parameter P=5,
    parameter V=4,
    parameter CONGw=2 //congestion width per port
 
 )
 (
    ovc_avalable_all,
    congestion_out_all   
 
 );
    
 
    localparam  P_1     =   P-1,
                PV      =   (V     *  P),
                CONG_ALw=   CONGw* P;
    
   
   localparam EAST      =0,
              NORTH     =1,
              WEST      =2,
              SOUTH     =3;
              
    localparam  CNT_Iw = 3*V;            
   
    input       [PV-1       :   0]  ovc_avalable_all; 
    output      [CONG_ALw-1 :   0]  congestion_out_all;                 
  
               
                
    wire    [V-1        :   0] ovc_not_avb [P_1-1  :   0];
    wire    [CNT_Iw-1   :   0] counter_in   [P_1-1  :   0];
    wire    [CONGw-1    :   0] congestion_out[P_1-1  :   0];
  
    assign  {ovc_not_avb[SOUTH], ovc_not_avb[WEST], ovc_not_avb[NORTH],  ovc_not_avb[EAST]}= ~ovc_avalable_all[PV-1     :   V];  
    assign  counter_in[EAST]    ={ovc_not_avb[NORTH],ovc_not_avb[WEST]  ,ovc_not_avb[SOUTH]};
    assign  counter_in[NORTH]   ={ovc_not_avb[EAST] ,ovc_not_avb[WEST]  ,ovc_not_avb[SOUTH]};
    assign  counter_in[WEST]    ={ovc_not_avb[EAST] ,ovc_not_avb[NORTH] ,ovc_not_avb[SOUTH]};
    assign  counter_in[SOUTH]   ={ovc_not_avb[EAST] ,ovc_not_avb[NORTH] ,ovc_not_avb[WEST]};
       
  
  
    genvar i;
    generate 
    for (i=0;i<4;i=i+1) begin :lp
       
        parallel_count_normalize #(
            .INw(CNT_Iw),
            .OUTw(CONGw)
        )
        ovc_avb_east
        (
            .in(counter_in[i]),
            .out(congestion_out[i])
        );   
    
    
    end
    endgenerate
    
    
   
    assign  congestion_out_all = {congestion_out[SOUTH],congestion_out[WEST],congestion_out[NORTH],congestion_out[EAST],{CONGw{1'b0}}};   

endmodule







/*******************************
 
     congestion based on number of
 availabe ovc in destination router   
            CONGESTION_INDEX==8  CONGw=2
 ********************************/
 
 
 module congestion_out_based_avb_ovc_w2 #(
    parameter P=5,
    parameter V=4
   
 
 )
 (
    ovc_avalable_all,
    congestion_out_all   
 
 );
   localparam CONGw=2; //congestion width per port
 
    localparam  P_1     =   P-1,
                PV      =   (V     *  P),
                CONG_ALw=   CONGw* P,
                CNT_Iw = 2*V;    
    
   
 
  
   
    input       [PV-1       :   0]  ovc_avalable_all; 
    output      [CONG_ALw-1 :   0]  congestion_out_all;                 
  
   /*************
        N
     Q1 | Q3
   w--------E
     Q0 | Q2
        S
   ***************/
   
    localparam Q3   = 3,
               Q1   = 1,
               Q2   = 2,
               Q0   = 0;  

    localparam EAST =   0,
               NORTH=   1,
               WEST =   2,
               SOUTH=   3;         
     
   
          
  
               
                
    wire    [V-1        :   0] ovc_not_avb      [P_1-1  :   0];
    wire    [CNT_Iw-1   :   0] counter_in       [P_1-1  :   0];
    wire    [CONGw-1    :   0] congestion_out   [P_1-1  :   0];
    wire    [P_1-1      :   0] threshold;
    
    
    assign  {ovc_not_avb[SOUTH], ovc_not_avb[WEST], ovc_not_avb[NORTH],  ovc_not_avb[EAST]}= ~ovc_avalable_all[PV-1     :   V];  
    
    assign  counter_in[Q3]    ={ovc_not_avb[EAST ],ovc_not_avb[NORTH]};
    assign  counter_in[Q1]    ={ovc_not_avb[NORTH],ovc_not_avb[WEST ]};
    assign  counter_in[Q2]    ={ovc_not_avb[SOUTH],ovc_not_avb[EAST ]};
    assign  counter_in[Q0]    ={ovc_not_avb[WEST ],ovc_not_avb[SOUTH]};
    
    genvar i;
    generate
    for (i=0;i<4;i=i+1) begin :lp
      
        parallel_count_normalize #(
            .INw(CNT_Iw),
            .OUTw(1)
        )
        ovc_not_avb_cnt
        (
            .in(counter_in[i]),
            .out(threshold[i])
        );   
    
    
    end
    endgenerate
       
       
               
                
   
    
    assign congestion_out[EAST]     = {threshold[Q1],threshold[Q0]};
    assign congestion_out[NORTH]    = {threshold[Q0],threshold[Q2]};
    assign congestion_out[WEST]     = {threshold[Q2],threshold[Q3]};
    assign congestion_out[SOUTH]    = {threshold[Q3],threshold[Q1]};
   
    assign  congestion_out_all = {congestion_out[SOUTH],congestion_out[WEST],congestion_out[NORTH],congestion_out[EAST],{CONGw{1'b0}}};   

endmodule






/*******************************
 
     congestion based on number of
 availabe ovc in destination router   
            CONGESTION_INDEX==9  CONGw=3
 ********************************/
 
 module congestion_out_based_avb_ovc_w3 #(
    parameter P=5,
    parameter V=4
   
 
 )
 (
    ovc_avalable_all,
    congestion_out_all   
 
 );
   localparam CONGw=3; //congestion width per port
 
    localparam  P_1     =   P-1,
                PV      =   (V     *  P),
                CONG_ALw=   CONGw* P;
    
   
   localparam EAST      =0,
              NORTH     =1,
              WEST      =2,
              SOUTH     =3;
              
  
   
    input       [PV-1       :   0]  ovc_avalable_all; 
    output      [CONG_ALw-1 :   0]  congestion_out_all;                 
  
               
                
    wire    [V-1        :   0] ovc_not_avb [P_1-1  :   0];
    wire    [CONGw-1    :   0] congestion_out[P_1-1  :   0];
    
    wire [P_1-1  :   0] threshold;
  
    assign  {ovc_not_avb[SOUTH],  ovc_not_avb[WEST], ovc_not_avb[NORTH],   ovc_not_avb[EAST]}=~ovc_avalable_all[PV-1     :   V];

 
   
  
    genvar i;
    generate 
    
    
    for (i=0;i<4;i=i+1) begin :lp
      
        parallel_count_normalize #(
            .INw(V),
            .OUTw(1)
        )
        ovc_avb_east
        (
            .in(ovc_not_avb[i]),
            .out(threshold[i])
        );   
    
    
    end
    endgenerate
    
    assign congestion_out[EAST]     = {threshold[NORTH],threshold[WEST ],threshold[SOUTH]};
    assign congestion_out[NORTH]    = {threshold[WEST ],threshold[SOUTH],threshold[EAST ]};
    assign congestion_out[WEST]     = {threshold[SOUTH],threshold[EAST ],threshold[NORTH]};
    assign congestion_out[SOUTH]    = {threshold[EAST ],threshold[NORTH],threshold[WEST ]};
   
    assign  congestion_out_all = {congestion_out[SOUTH],congestion_out[WEST],congestion_out[NORTH],congestion_out[EAST],{CONGw{1'b0}}};   

endmodule


/*******************************
 
     congestion based on number of
 availabe ovc in destination router   
            CONGESTION_INDEX==10  CONGw=4
 ********************************/
 module congestion_out_based_avb_ovc_w4 #(
    parameter P=5,
    parameter V=4
   
 
 )
 (
    ovc_avalable_all,
    congestion_out_all   
 
 );
   localparam CONGw=4; //congestion width per port
 
    localparam  P_1     =   P-1,
                PV      =   (V     *  P),
                CONG_ALw=   CONGw* P,
                CNT_Iw = 2*V;    
    
   
  
   
    input       [PV-1       :   0]  ovc_avalable_all; 
    output      [CONG_ALw-1 :   0]  congestion_out_all;                 
  
  
     
   
    /*************
        N
     Q1 | Q3
   w--------E
     Q0 | Q2
        S
   ***************/
   
    localparam Q3   = 3,
               Q1   = 1,
               Q2   = 2,
               Q0   = 0;  

    localparam EAST =   0,
               NORTH=   1,
               WEST =   2,
               SOUTH=   3;         
     
             
  
               
                
    wire    [V-1        :   0] ovc_not_avb      [P_1-1  :   0];
    wire    [CNT_Iw-1   :   0] counter_in       [P_1-1  :   0];
    wire    [CONGw-1    :   0] congestion_out   [P_1-1  :   0];
    wire    [1          :   0] threshold        [P_1-1  :   0];
    
    
    assign  {ovc_not_avb[SOUTH], ovc_not_avb[WEST], ovc_not_avb[NORTH],  ovc_not_avb[EAST]}= ~ovc_avalable_all[PV-1     :   V];  
    
    assign  counter_in[Q3]    ={ovc_not_avb[EAST ],ovc_not_avb[NORTH]};
    assign  counter_in[Q1]    ={ovc_not_avb[NORTH],ovc_not_avb[WEST ]};
    assign  counter_in[Q2]    ={ovc_not_avb[SOUTH],ovc_not_avb[EAST ]};
    assign  counter_in[Q0]    ={ovc_not_avb[WEST ],ovc_not_avb[SOUTH]};
  
    
    genvar i;
    generate
    for (i=0;i<4;i=i+1) begin :lp
      
        parallel_count_normalize #(
            .INw(CNT_Iw),
            .OUTw(2)
        )
        ovc_not_avb_cnt
        (
            .in(counter_in[i]),
            .out(threshold[i])
        );   
    
    
    end
    endgenerate
       
       
               
                
   
    
    assign congestion_out[EAST]     = {threshold[Q1],threshold[Q0]};
    assign congestion_out[NORTH]    = {threshold[Q0],threshold[Q2]};
    assign congestion_out[WEST]     = {threshold[Q2],threshold[Q3]};
    assign congestion_out[SOUTH]    = {threshold[Q3],threshold[Q1]};
   
    assign  congestion_out_all = {congestion_out[SOUTH],congestion_out[WEST],congestion_out[NORTH],congestion_out[EAST],{CONGw{1'b0}}};   

endmodule


 

/*******************************
 
    congestion based on number of 
    availabe ovc and not granted
        ivc in next router  
    CONGESTION_INDEX==11 CONGw=2
    CONGESTION_INDEX==12 CONGw=3
    
            
 ********************************/
 module congestion_out_based_avb_ovc_not_granted_ivc #(
    parameter P=5,
    parameter V=4,
    parameter CONGw=3 //congestion width per port
 
 )
 (
    ovc_avalable_all,
    ivc_request_all,
    ivc_num_getting_sw_grant,
    clk,
    reset,    
    congestion_out_all   
 
 );
    

    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
    
   
     
 
    localparam  P_1         =   P-1,
                PV          =   (V     *  P),
                CONG_ALw    =   CONGw* P,
                CNT_Iw      =   3*V,
                CNT_Ow      =   log2((3*V)+1),
                CNG_w       =   log2((6*V)+1),
                CNT_Vw      =   log2(V+1),
                EAST        =   0,
                NORTH       =   1,
                WEST        =   2,
                SOUTH       =   3;
              
                 
   
    input       [PV-1       :   0]  ovc_avalable_all; 
    output      [CONG_ALw-1 :   0]  congestion_out_all;                 
    input       [PV-1       :   0]  ivc_request_all,ivc_num_getting_sw_grant; 
    
    input                           reset,clk;
               
    // counting not available ovc            
    wire    [V-1        :   0] ovc_not_avb  [P_1-1  :   0];
    wire    [CNT_Iw-1   :   0] counter_in   [P_1-1  :   0];
    wire    [CNT_Ow-1   :   0] counter_o    [P_1-1  :   0];
    wire    [CONGw-1    :   0] congestion_out[P_1-1  :   0];
  
    assign  {ovc_not_avb[SOUTH], ovc_not_avb[WEST], ovc_not_avb[NORTH],  ovc_not_avb[EAST]}= ~ovc_avalable_all[PV-1     :   V];  
    assign  counter_in[EAST]    ={ovc_not_avb[NORTH],ovc_not_avb[WEST]  ,ovc_not_avb[SOUTH]};
    assign  counter_in[NORTH]   ={ovc_not_avb[EAST] ,ovc_not_avb[WEST]  ,ovc_not_avb[SOUTH]};
    assign  counter_in[WEST]    ={ovc_not_avb[EAST] ,ovc_not_avb[NORTH] ,ovc_not_avb[SOUTH]};
    assign  counter_in[SOUTH]   ={ovc_not_avb[EAST] ,ovc_not_avb[NORTH] ,ovc_not_avb[WEST]};
    
    // counting not granted requests
    reg     [PV-1       :   0]  ivc_request_not_granted; 
    wire    [V-1        :   0]  ivc_not_grnt  [P_1-1  :   0];
    wire    [CNT_Vw-1   :   0]  ivc_not_grnt_num [P_1-1  :   0];
    
    always @(posedge clk or posedge reset) begin 
        if(reset) begin 
            ivc_request_not_granted <= 0;
        end else begin 
            ivc_request_not_granted <= ivc_request_all & ~(ivc_num_getting_sw_grant);
        end//reset
    end //always
    
    
     assign  {ivc_not_grnt[SOUTH], ivc_not_grnt[WEST], ivc_not_grnt[NORTH],ivc_not_grnt[EAST]}= ivc_request_not_granted[PV-1     :   V];  
    
     
   
    genvar i;
    generate 
    for (i=0;i<4;i=i+1) begin :lp
   
        parallel_counter #(
            .IN_WIDTH(CNT_Iw)
        )
        ovc_counter
        (
            .in(counter_in[i]),
            .out(counter_o[i])
        );
   
        parallel_counter #(
            .IN_WIDTH(V)
            
        )
        ivc_counter
        (
            .in(ivc_not_grnt[i]),
            .out(ivc_not_grnt_num[i])
        );
       wire [CNG_w-1 :   0] congestion_num  [P_1-1  :   0];


       assign congestion_num [i]=  counter_o[i]+ ivc_not_grnt_num[i]+ {ivc_not_grnt_num[i],1'b0};
   
       normalizer #(
            .MAX_IN(6*V),
            .OUTw(CONGw)
  
        )norm
        (
            .in(congestion_num [i]),
            .out(congestion_out[i])
        
         );
       
           
    end//for
    endgenerate
    
 
   
   
    assign  congestion_out_all = {congestion_out[SOUTH],congestion_out[WEST],congestion_out[NORTH],congestion_out[EAST],{CONGw{1'b0}}};   

endmodule



/**********************

    parallel_count_normalize

**********************/
module parallel_count_normalize #(
    parameter INw = 12,
    parameter OUTw= 2

)(
    in,
    out

);

    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
    
    input   [INw-1      :   0]  in;
    output  [OUTw-1     :   0]  out;

    localparam CNTw = log2(INw+1);
    wire    [CNTw-1     :    0] counter;

    parallel_counter #(
        .IN_WIDTH(INw)
    )
    ovc_avb_cnt
    (
        .in(in),
        .out(counter)
    );  
    
       
    normalizer #(
        .MAX_IN(INw),
        .OUTw(OUTw)
  
    )norm
    (
        .in(counter),
        .out(out)
     );
    
           
 endmodule    
   
   /**************
   
   normalizer
   
   ***************/
   
 module normalizer #(
    parameter MAX_IN= 10,
    parameter OUTw= 2
  
 )(
    in,
    out
 
 );
 
 
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
    
    localparam INw= log2(MAX_IN+1),
               OUT_ON_HOT_NUM = 2**OUTw;
    
 
    input   [INw-1   :   0]  in;
    output  [OUTw-1  :   0]  out; 
    
    wire [OUT_ON_HOT_NUM-1   :   0]  one_hot_out;
 
 
 
    genvar i;
    generate 
    for(i=0;i< OUT_ON_HOT_NUM;i=i+1)begin :lp
	/* verilator lint_off WIDTH */
       if(i==0) begin : i0 assign one_hot_out[i]= (in<= (MAX_IN /OUT_ON_HOT_NUM)); end
       else begin :ib0   assign one_hot_out[i]= ((in> ((MAX_IN *i)/OUT_ON_HOT_NUM)) &&  (in<= ((MAX_IN *(i+1))/OUT_ON_HOT_NUM))); end
    	/* verilator lint_on WIDTH */
    end//for
    endgenerate
    
 
    
    one_hot_to_bin#( 
        .ONE_HOT_WIDTH(OUT_ON_HOT_NUM)
    )
    conv
    (
        .one_hot_code(one_hot_out),
        .bin_code(out)
    );
 
 
 endmodule
 
   
   
   
   

   
   
   
   
   
   
   

/**************************


        congestion_out_gen
        

**************************/




module congestion_out_gen #(
    parameter P=5,
    parameter V=4,
    parameter ROUTE_TYPE ="ADAPTIVE", 
    parameter CONGESTION_INDEX=2,
    parameter CONGw=2

)
(
   ivc_request_all, 
   ivc_num_getting_sw_grant,
   ovc_avalable_all,
   congestion_out_all,
   clk,
   reset
);

localparam PV       = P*V,
           CONG_ALw = CONGw* P;   //  congestion width per router;;

 input    [PV-1       :   0]  ovc_avalable_all; 
 input    [PV-1       :   0]  ivc_request_all;    
 input    [PV-1       :   0]  ivc_num_getting_sw_grant; 
 output  reg [CONG_ALw-1 :   0]  congestion_out_all;                 
 input                        clk,reset;

  wire [CONG_ALw-1 :   0]  congestion_out_all_next;  
generate
if(ROUTE_TYPE  !=  "DETERMINISTIC") begin :adpt
        if((CONGESTION_INDEX==2) || (CONGESTION_INDEX==3)) begin :based_ivc
           congestion_out_based_ivc_req #(
               .P(P),
               .V(V),
               .CONGw(CONGw)
           )
           the_congestion_out_gen
           (
               .ivc_request_all(ivc_request_all),
               .congestion_out_all(congestion_out_all_next)
           );
        end else if((CONGESTION_INDEX==4) || (CONGESTION_INDEX==5)) begin :based_ng_ivc
      
           congestion_out_based_ivc_notgrant #(
               .P(P),
               .V(V),
               .CONGw(CONGw)
           )
           the_congestion_out_gen
           (
               .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant),
               .ivc_request_all(ivc_request_all),
               .congestion_out_all(congestion_out_all_next),
               .clk(clk),
               .reset(reset)
           );
           
        end else if  ((CONGESTION_INDEX==6) || (CONGESTION_INDEX==7)) begin :avb_ovc1
       
            congestion_out_based_3port_avb_ovc#(
               .P(P),
               .V(V),
               .CONGw(CONGw)
             )
             the_congestion_out_gen
             (      
            	.ovc_avalable_all(ovc_avalable_all),
                .congestion_out_all(congestion_out_all_next)
              );
       
       
       end  else if  (CONGESTION_INDEX==8) begin :indx8
              
       
            congestion_out_based_avb_ovc_w2 #(
                .P(P),
                .V(V)
            )
            the_congestion_out_gen
            (
                .ovc_avalable_all(ovc_avalable_all),
                .congestion_out_all(congestion_out_all_next)   
 
            );
         end  else if  (CONGESTION_INDEX==9) begin :indx9
 
            congestion_out_based_avb_ovc_w3 #(
                .P(P),
                .V(V)
            )
            the_congestion_out_gen
            (
                .ovc_avalable_all(ovc_avalable_all),
                .congestion_out_all(congestion_out_all_next)   
 
            );
         end  else if  (CONGESTION_INDEX==10) begin :indx10
            
            congestion_out_based_avb_ovc_w4 #(
                .P(P),
                .V(V)
            )
            the_congestion_out_gen
            (
                .ovc_avalable_all(ovc_avalable_all),
                .congestion_out_all(congestion_out_all_next)   
 
            );
            
          end  else if  (CONGESTION_INDEX==11 || CONGESTION_INDEX==12) begin :indx11
            
            congestion_out_based_avb_ovc_not_granted_ivc #(
                .P(P),
                .V(V),
                .CONGw(CONGw) //congestion width per port
            )
            the_congestion_out_gen
            (
                .ovc_avalable_all(ovc_avalable_all),
                .ivc_request_all(ivc_request_all),
                .ivc_num_getting_sw_grant(ivc_num_getting_sw_grant),
                .clk(clk),
                .reset(reset),    
                .congestion_out_all(congestion_out_all_next)   
            );
             
       
        end  else begin :nocong assign  congestion_out_all_next = {CONG_ALw{1'bx}};   end
    
    
    end else begin :dtrmn
           assign  congestion_out_all_next = {CONG_ALw{1'bx}};   
    
    end

endgenerate

	always @(posedge clk or posedge reset)begin
		if(reset)begin
			congestion_out_all <= {CONG_ALw{1'b0}};  
		end else begin 
			congestion_out_all <= congestion_out_all_next;
		
		end	
	end


endmodule


/*************************

    deadlock_detector

**************************/

module  deadlock_detector #(
    parameter P=5,
    parameter V=4,
    parameter MAX_CLK = 16

)(
    ivc_num_getting_sw_grant,
    ivc_request_all,
    reset,
    clk,
    detect

);
    
 
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
    
    
    
    
    localparam  PV      =  P*V,
                CNTw    = log2(MAX_CLK);

    
  input [PV-1   :   0]  ivc_num_getting_sw_grant, ivc_request_all;
  input             reset,clk;
  output            detect;

  reg   [CNTw-1 :   0]  counter         [V-1   :   0];
  wire  [P-1    :   0]  counter_rst_gen [V-1   :   0];
  wire  [P-1    :   0]  counter_en_gen  [V-1   :   0];
  wire  [V-1    :   0]  counter_rst,counter_en,detect_gen;
  reg   [PV-1   :   0]  ivc_num_getting_sw_grant_reg;
 
  always @(posedge clk or posedge reset)begin 
    if(reset) begin 
          ivc_num_getting_sw_grant_reg  <= {PV{1'b0}};
    end else begin 
          ivc_num_getting_sw_grant_reg  <= ivc_num_getting_sw_grant;
    end  
  end
 
 //seperate all same virtual channels requests
 genvar i,j;
 generate 
 for (i=0;i<V;i=i+1)begin:v_loop
     for (j=0;j<P;j=j+1)begin :p_loop
        assign counter_rst_gen[i][j]=ivc_num_getting_sw_grant_reg[j*V+i];
        assign counter_en_gen [i][j]=ivc_request_all[j*V+i];
    end//j
    //sum all signals belong to the same VC
    assign counter_rst[i]   =|counter_rst_gen[i];
    assign counter_en[i]    =|counter_en_gen [i]; 
    // generate the counter
    always @(posedge clk or posedge reset)begin 
        if(reset) begin 
            counter[i]<={CNTw{1'b0}};
        end else begin 
            if(counter_rst[i])      counter[i]<={CNTw{1'b0}};
            else if(counter_en[i])  counter[i]<=counter[i]+1'b1;
        end//reset
    end//always
    // check counters value to detect deadlock
    assign detect_gen[i]=     (counter[i]== MAX_CLK-1);
    
 end//i
 
 assign detect=|detect_gen;
 
 
 
 endgenerate




endmodule




 

