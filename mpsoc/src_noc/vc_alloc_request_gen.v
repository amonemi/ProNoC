
`timescale   1ns/1ps

/**********************************************************************
**	File:  vc_alloc_request_gen.v
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
**	Mask invalid VC allocation requests	
**
***************************************/


module  vc_alloc_request_gen_determinstic #(
    parameter P = 5,
    parameter V = 4

)(
    ovc_avalable_all,
    dest_port_in_all,
    candidate_ovc_all,
    ivc_request_all,
    ovc_is_assigned_all,
    dest_port_out_all,
    masked_ovc_request_all
);

    localparam  P_1     =   P-1,
                PV      =   V       *   P,
                PVV     =   PV      *  V,
                PVP_1   =   PV      *   P_1,
                VP_1    =   V       *   P_1;

    input   [PV-1       :   0]  ovc_avalable_all;
    input   [PVP_1-1    :   0]  dest_port_in_all;
    input   [PV-1       :   0]  ivc_request_all;
    input   [PV-1       :   0]  ovc_is_assigned_all;
    output  [PVP_1-1    :   0]  dest_port_out_all;
    output  [PVV-1      :   0]  masked_ovc_request_all;
    input   [PVV-1      :   0]  candidate_ovc_all;
    
    wire    [PV-1       :   0]  non_assigned_ovc_request_all; 
    wire    [VP_1-1     :   0]  ovc_avalable_perport        [P-1    :   0];
    wire    [VP_1-1     :   0]  ovc_avalable_ivc            [PV-1   :   0];
    wire    [P_1-1      :   0]  dest_port_ivc               [PV-1   :   0];
    wire    [V-1        :   0]  ovc_avb_muxed               [PV-1   :   0];  
    wire    [V-1        :   0]  ovc_request_ivc             [PV-1   :   0];
  
  assign non_assigned_ovc_request_all =   ivc_request_all & ~ovc_is_assigned_all;
  
  // having determinsit routing only one destination port has been requested
  assign dest_port_out_all = dest_port_in_all;
    
  genvar i;

generate
    //remove avalable ovc of reciver port 
    for(i=0;i< P;i=i+1) begin :port_loop
        if(i==0) begin : first assign ovc_avalable_perport[i]=ovc_avalable_all [PV-1              :   V]; end
        else if(i==(P-1)) begin : last assign ovc_avalable_perport[i]=ovc_avalable_all [PV-V-1               :   0]; end
        else  begin : midle  assign ovc_avalable_perport[i]={ovc_avalable_all [PV-1  :   (i+1)*V],ovc_avalable_all [(i*V)-1  :   0]}; end
    end
        
    // IVC loop
    for(i=0;i< PV;i=i+1) begin :total_vc_loop
        //seprate input/output
        assign ovc_avalable_ivc[i]  =   ovc_avalable_perport[(i/V)];
        assign dest_port_ivc   [i]  =   dest_port_in_all [(i+1)*P_1-1  :   i*P_1   ];
        assign ovc_request_ivc [i]  = (non_assigned_ovc_request_all[i])? candidate_ovc_all  [(i+1)*V-1  :   i*V ]: {V{1'b0}};
          
       
        //available ovc multiplexer
        one_hot_mux #(
            .IN_WIDTH       (VP_1   ),
            .SEL_WIDTH      (P_1)
        )
        multiplexer
        (
            .mux_in     (ovc_avalable_ivc   [i]),
            .mux_out    (ovc_avb_muxed      [i]),
            .sel        (dest_port_ivc      [i])

        );
        
        // mask unavailable ovc from requests
        assign masked_ovc_request_all  [(i+1)*V-1   :   i*V ]     =   ovc_avb_muxed[i] & ovc_request_ivc [i];
        
    end
   endgenerate


endmodule
/*****************************************

pre-sel[xy]
    y
1   |   3
    |
 -------x
0   |   2
    |

*****************************************/


module  vc_alloc_request_gen_adaptive #(
    parameter V = 4,
    parameter ROUTE_TYPE           =  "FULL_ADAPTIVE",    // "FULL_ADAPTIVE", "PAR_ADAPTIVE"  
    parameter [V-1  :   0] ESCAP_VC_MASK = 4'b1000,   // mask scape vc, valid only for full adaptive       
    parameter ROUTE_SUBFUNC="XY"

)(
    ovc_avalable_all,
    dest_port_in_all,
    candidate_ovc_all,
    ivc_request_all,
    ovc_is_assigned_all,
    dest_port_out_all,
    masked_ovc_request_all,
    port_pre_sel,
    //port_pre_sel_ld_all,
    current_x_0,
    x_diff_is_one_all,
    sel,
    reset,
    clk
    
);
    localparam  P = 5;
    
    localparam  P_1     =   P-1,
                PV      =   V       *   P,
                PVV     =   PV      *  V,
                PVP_1   =   PV      *   P_1,
                VP_1    =   V       *   P_1;
                
     localparam LOCAL   =   3'd0,  
                EAST    =   3'd1, 
                NORTH   =   3'd2,  
                WEST    =   3'd3,  
                SOUTH   =   3'd4;  

    input   [PV-1       :   0]  ovc_avalable_all;
    input   [PVP_1-1    :   0]  dest_port_in_all;
    input   [PV-1       :   0]  ivc_request_all;
    input   [PV-1       :   0]  ovc_is_assigned_all;
    output  [PVP_1-1    :   0]  dest_port_out_all;
    output  [PVV-1      :   0]  masked_ovc_request_all;
    input   [PVV-1      :   0]  candidate_ovc_all;
    input   [P_1-1      :   0]  port_pre_sel;
   // input   [PV-1       :   0]  port_pre_sel_ld_all;
   
    output  [PV-1       :   0]  sel;
    input                       reset,clk;
    input                       current_x_0;
    input   [PV-1       :   0]  x_diff_is_one_all;
    
    wire    [PV-1       :   0]  non_assigned_ovc_request_all; 
    wire    [PV-1       :   0]  y_evc_forbiden,x_evc_forbiden;
    wire    [V-1        :   0]  ovc_avb_x_plus,ovc_avb_x_minus,ovc_avb_y_plus,ovc_avb_y_minus,ovc_avb_local;
    wire    [VP_1-1     :   0]  ovc_avalable_perport            [P-1    :   0];
    wire    [P_1-1      :   0]  port_pre_sel_perport            [P-1    :   0];
    wire    [PVV-1      :   0]  candidate_ovc_x_all, candidate_ovc_y_all;
    wire    [PV-1       :   0]  swap_port_presel;
    
    assign non_assigned_ovc_request_all =   ivc_request_all & ~ovc_is_assigned_all;   
    assign {ovc_avb_y_minus,ovc_avb_x_minus,ovc_avb_y_plus,ovc_avb_x_plus,ovc_avb_local} = ovc_avalable_all;
    
    assign ovc_avalable_perport[LOCAL]  = {ovc_avb_x_plus,ovc_avb_x_minus,ovc_avb_y_plus,ovc_avb_y_minus};
    assign ovc_avalable_perport[EAST]   = {ovc_avb_local,ovc_avb_x_minus,ovc_avb_y_plus,ovc_avb_y_minus};
    assign ovc_avalable_perport[NORTH]  = {ovc_avb_x_plus,ovc_avb_x_minus,ovc_avb_local,ovc_avb_y_minus};
    assign ovc_avalable_perport[WEST]   = {ovc_avb_x_plus,ovc_avb_local,ovc_avb_y_plus,ovc_avb_y_minus};
    assign ovc_avalable_perport[SOUTH]  = {ovc_avb_x_plus,ovc_avb_x_minus,ovc_avb_y_plus,ovc_avb_local};
    
    
    
    assign port_pre_sel_perport[LOCAL]   = port_pre_sel;
    assign port_pre_sel_perport[EAST]    = {2'b00,port_pre_sel[1:0]};
    assign port_pre_sel_perport[NORTH]   = {1'b0,port_pre_sel[2],1'b0,port_pre_sel[0]};
    assign port_pre_sel_perport[WEST]    = {port_pre_sel[3:2],2'b0};
    assign port_pre_sel_perport[SOUTH]   = {port_pre_sel[3],1'b0,port_pre_sel[1],1'b0};
    
   
    wire    [PV-1   :   0]  avc_unavailable; 
    genvar i;
    generate 
     
    
    
    
    
    for(i=0;i< PV;i=i+1) begin :all_vc_loop
        
       adaptive_avb_ovc_mux #(
       	.V(V)
       )
       the_adaptive_avb_ovc_mux
       (
       	.ovc_avalable               (ovc_avalable_perport   [i/V]),
       	.sel                        (sel                    [i]),
       	.candidate_ovc_x            (candidate_ovc_x_all    [((i+1)*V)-1 : i*V]),
       	.candidate_ovc_y            (candidate_ovc_y_all    [((i+1)*V)-1 : i*V]),
       	.non_assigned_ovc_request   (non_assigned_ovc_request_all[i]),
       	.xydir                      (dest_port_in_all       [((i+1)*P_1)-1 : ((i+1)*P_1)-2]),
       	.masked_ovc_request         (masked_ovc_request_all [((i+1)*V)-1 : i*V])
       );
       
  
       
        port_selector #(
	       .SW_LOC     (i/V),
	       .ROUTE_SUBFUNC (ROUTE_SUBFUNC)
        )
        the_portsel(
	    //   .reset              (reset),
	    //   .clk                (clk),
	       .port_pre_sel       (port_pre_sel_perport[i/V]),
	       //.port_pre_sel_ld    (port_pre_sel_ld_all[i]),
	       .swap_port_presel   (swap_port_presel[i]),
	       .sel                (sel[i]),
	       .dest_port_in       (dest_port_in_all[((i+1)*P_1)-1 : i*P_1]),
	       .dest_port_out      (dest_port_out_all[((i+1)*P_1)-1 : i*P_1]),
	       .y_evc_forbiden     (y_evc_forbiden[i]),
           .x_evc_forbiden     (x_evc_forbiden[i]),
           .x_diff_is_one      (x_diff_is_one_all[i]),
           .current_x_0        (current_x_0)
	      // .route_subfunc_violated(route_subfunc_violated[i])
	      );
	    /* verilator lint_off WIDTH */   
        if(ROUTE_TYPE ==  "FULL_ADAPTIVE") begin: full_adpt
        /* verilator lint_on WIDTH */ 
            assign candidate_ovc_y_all[((i+1)*V)-1 : i*V] =  (y_evc_forbiden[i]) ? candidate_ovc_all[((i+1)*V)-1 : i*V] & (~ESCAP_VC_MASK) :  candidate_ovc_all[((i+1)*V)-1 : i*V];
            assign candidate_ovc_x_all[((i+1)*V)-1 : i*V] =  (x_evc_forbiden[i]) ? candidate_ovc_all[((i+1)*V)-1 : i*V] & (~ESCAP_VC_MASK) :  candidate_ovc_all[((i+1)*V)-1 : i*V];
            assign avc_unavailable[i] = (masked_ovc_request_all [((i+1)*V)-1 : i*V] & ~ESCAP_VC_MASK) == {V{1'b0}};
            
            
            
            swap_port_presel_gen #(
                .V(V),
                .ESCAP_VC_MASK(ESCAP_VC_MASK),       
                .VC_NUM(i)
            )           
            the_swap_port_presel
            (
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
            assign candidate_ovc_y_all[((i+1)*V)-1 : i*V] =   candidate_ovc_all [((i+1)*V)-1 : i*V];
            assign candidate_ovc_x_all[((i+1)*V)-1 : i*V] =   candidate_ovc_all [((i+1)*V)-1 : i*V];
            assign swap_port_presel[i]=1'b0;
            assign avc_unavailable[i]=1'b0;
            
        end// ROUTE_TYPE
    end//for
    
    //assign candidate_ovc_x_all=  candidate_ovc_all;   
endgenerate
endmodule




/**********************

    swap_port_presel_gen

**********************/

module   swap_port_presel_gen #(
    parameter V = 4,
    parameter [V-1  :   0] ESCAP_VC_MASK = 4'b1000,   // mask scape vc, valid only for full adaptive       
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
    
    

    input    avc_unavailable;
    input    y_evc_forbiden,x_evc_forbiden;
    input    non_assigned_ovc_request,sel;
    input    clk,reset;
    output   swap_port_presel;
    reg      swap_reg;
    
    wire swap_port_presel_next;

   
    wire  evc_forbiden; 
   
    
    /************************
                
        destination-port_in
            x:  1 EAST, 0 WEST  
            y:  1 NORTH, 0 SOUTH
            ab: 00 : LOCAL, 10: xdir, 01: ydir, 11 x&y dir 
        sel:
             0: xdir
             1: ydir
        port_pre_sel
             0: xdir
             1: ydir  

************************/
    
    
    //For an EVC sender, if the use of EVC in destination port is restricted while the destination port has no available AVC,
    //the port pre selection must swap 
  
    
   // generate
    // check if it is an evc sender
   // if(ESCAP_VC_MASK[LOCAL_VC_NUM]== 1'b0)begin 
    //its not EVC
    //   assign swap_port_presel=1'b0;
    
   // end else begin // the sender is an EVC
       
       assign  evc_forbiden = (sel)? y_evc_forbiden : x_evc_forbiden;
       assign  swap_port_presel_next= non_assigned_ovc_request & evc_forbiden & avc_unavailable;
    
        always @(posedge clk or posedge reset)begin 
            if(reset)begin 
                swap_reg<=1'b0;        
            end else begin 
                swap_reg<=swap_port_presel_next;
            end
        end
        assign swap_port_presel = swap_reg;
       
    //end //else
    
   
    
    //endgenerate



endmodule




/************************

    adaptive_avb_ovc_mux


************************/
module  adaptive_avb_ovc_mux #(
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
    localparam  P       =   5;
    localparam  P_1     =   P-1,
                VP_1    =   V  *  P_1;
                
    input   [VP_1-1    :    0] ovc_avalable;
    input                      sel;
    input   [V-1       :    0] candidate_ovc_x;
    input   [V-1       :    0] candidate_ovc_y;
    input                      non_assigned_ovc_request;
    input   [1         :    0] xydir;
    output  [V-1        :   0] masked_ovc_request;
    wire    x,y;
    wire    [V-1        :   0] ovc_avb_x_plus,ovc_avb_x_minus,ovc_avb_y_plus,ovc_avb_y_minus;
    wire    [V-1        :   0] mux_out_x,mux_out_y;
    wire    [V-1        :   0] ovc_request_x,ovc_request_y,masked_ovc_request_x,masked_ovc_request_y;
    
    assign {x,y}= xydir;
    assign {ovc_avb_x_plus,ovc_avb_x_minus,ovc_avb_y_plus,ovc_avb_y_minus}=ovc_avalable;
    //first level mux
    //assign mux_out_x = (x)?  ovc_avb_x_plus :  ovc_avb_x_minus;
    //assign mux_out_y = (y)?  ovc_avb_y_plus :  ovc_avb_y_minus;
    assign mux_out_x = (ovc_avb_x_plus &{V{x}}) |  (ovc_avb_x_minus &{V{~x}});
    assign mux_out_y = (ovc_avb_y_plus &{V{y}}) |  (ovc_avb_y_minus &{V{~y}});
     
     
    //assign ovc_request_x = (non_assigned_ovc_request)? candidate_ovc_x : {V{1'b0}};
    //assign ovc_request_y = (non_assigned_ovc_request)? candidate_ovc_y : {V{1'b0}};
    assign ovc_request_x =  candidate_ovc_x & {V{non_assigned_ovc_request}};
    assign ovc_request_y =  candidate_ovc_y & {V{non_assigned_ovc_request}};
    
    //mask unavailble ovc
    assign masked_ovc_request_x = mux_out_x & ovc_request_x;
    assign masked_ovc_request_y = mux_out_y & ovc_request_y;
    
    //second mux 
   // assign masked_ovc_request = (sel)?  masked_ovc_request_y: masked_ovc_request_x;
     assign masked_ovc_request =  (masked_ovc_request_y & {V{sel}})| (masked_ovc_request_x & {V{~sel}});


endmodule





/*****************************************************

                port_selector


*****************************************************/


module port_selector #(
    parameter SW_LOC    = 0,
    parameter ROUTE_SUBFUNC="XY"// XY,NORTH_LAST,ODD_EVEN

)
(
    port_pre_sel,
    dest_port_out,
    dest_port_in,
    //port_pre_sel_ld,
    swap_port_presel,
    sel,
   // reset,
   // clk,
    
    //full adaptive,
    y_evc_forbiden,
    x_evc_forbiden,
    //full adaptive using oddeven as route subfunction
    x_diff_is_one,
    current_x_0


);

/************************
                
        destination-port_in
            x:  1 EAST, 0 WEST  
            y:  1 NORTH, 0 SOUTH
            ab: 00 : LOCAL, 10: xdir, 01: ydir, 11 x&y dir 
        sel:
             0: xdir
             1: ydir
        port_pre_sel
             0: xdir
             1: ydir  

************************/


    //input           reset,clk;
    input   [3:0]   port_pre_sel;
   // input           port_pre_sel_ld;
    output          sel;
    input   [3:0]   dest_port_in;
    output  [3:0]   dest_port_out;
    input           x_diff_is_one,current_x_0,swap_port_presel;
   // output          route_subfunc_violated;
    output          y_evc_forbiden, x_evc_forbiden;
    
    wire  x,y,a,b;
    wire [3:0] port_pre_sel_final;
    //reg  [3:0] port_pre_sel_delayed , port_pre_sel_latched;
  //  wire o1,o2;
    reg [4:0] portout;

    localparam LOCAL    =       0,  
               EAST     =       1, 
               NORTH    =       2,  
               WEST     =       3,  
               SOUTH    =       4;  

    localparam LOCAL_SEL = (SW_LOC == NORTH || SW_LOC == SOUTH )? 1'b1 : 1'b0; 
   
   
   assign port_pre_sel_final= (swap_port_presel)? ~port_pre_sel: port_pre_sel;
   
    assign {x,y,a,b} = dest_port_in;
    /*
    // the destination port must not change after assigning OVC. latch the port_pre_sel result after assigning OVC.  
     always @(posedge clk or posedge reset) begin 
        if(reset) begin 
            port_pre_sel_delayed <= 4'd0;
            port_pre_sel_latched <= 4'd0;
        end else begin 
            if(port_pre_sel_ld) port_pre_sel_delayed <= port_pre_sel_final;
            if(port_pre_sel_ld) port_pre_sel_latched <= port_pre_sel_final;
            else                port_pre_sel_latched <= port_pre_sel_delayed;
            
        end
    end
    */
    
   // assign port_pre_sel_latched = (port_pre_sel_ld)? port_pre_sel : port_pre_sel_delayed; 
/*
    // mux1
    assign o1 = (x&y & port_pre_sel_latched[3] ) | (~x&~y & port_pre_sel_latched[0] );
    assign o2 = (~x&y & port_pre_sel_latched[1] ) | (x&~y & port_pre_sel_latched[2] );
    //mux2
    assign sel= (~a&b)|(a&b&(o1|o2))|(~a&~b& LOCAL_SEL);
 */
 
 
 
 
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
    generate 
    /* verilator lint_off WIDTH */    
    if(ROUTE_SUBFUNC=="XY") begin :xy_lp
    /* verilator lint_on WIDTH */  
        // Using of all EVCs located in y dimention are restricted when the packet can be sent into both x&y direction 
        assign y_evc_forbiden = a&b;
        
        //there is no restriction in using EVCs located in x dimention
        assign x_evc_forbiden = 1'b0; 
        //assign route_subfunc_violated = a&b;
    /* verilator lint_off WIDTH */         
    end else if (ROUTE_SUBFUNC=="NORTH_LAST") begin :north_last_lp
    /* verilator lint_on WIDTH */ 
        // Using of all EVCs located in y dimention are restricted when the packet can be sent into both -x& y direction  
        assign y_evc_forbiden = a&b&(~x);  
        //there is no restriction in using EVCs located in x dimention
        assign x_evc_forbiden = 1'b0; 
    /* verilator lint_off WIDTH */      
    end else if (ROUTE_SUBFUNC=="ODD_EVEN") begin :odd
    /* verilator lint_on WIDTH */ 
        assign y_evc_forbiden = (a&b) & ((x & (~current_x_0) & (SW_LOC!=0) ) | ( ~x & current_x_0)) ;  
        assign x_evc_forbiden = a & b  & x & current_x_0  & x_diff_is_one;  
       

        //if(EAST_BOUND && current_x[0]==1'b0 && ~LOCATED_IN_NI   ) Y_EVC_FORBIDEN;
        //if(EAST_BOUND && current_x[0]==1'b1 &&  xdiff==1        ) X_EVC_FORBIDEN;// dest_x[0]==1'b0 && xdiff==1 ==> current_x[0]==1'b1
        //if(WEST_BOUND && current_x[0]==1'b1                     ) Y_EVC_FORBIDEN;               
        
    
    end
    endgenerate
    
    
    always @(*)begin 
        case({a,b})
            2'b10 : portout = {1'b0,~x,1'b0,x,1'b0};
            2'b01 : portout = {~y,1'b0,y,1'b0,1'b0};
            2'b11 : portout = (port_pre_sel_final[{x,y}])?  {~y,1'b0,y,1'b0,1'b0} : {1'b0,~x,1'b0,x,1'b0} ;
            2'b00 : portout =  5'b00001;
         endcase
   end //always
    
    remove_sw_loc_one_hot #(
    	.P(5),
    	.SW_LOC(SW_LOC)
    )conv
    (
    	.destport_in(portout),
    	.destport_out(dest_port_out)
    );
    
  

endmodule


module  vc_alloc_request_gen_adaptive_classic #(
    parameter V = 4,
    parameter ROUTE_TYPE =  "FULL_ADAPTIVE",    // "FULL_ADAPTIVE", "PAR_ADAPTIVE"  
    parameter [V-1  :   0] ESCAP_VC_MASK = 4'b001,   // mask scape vc, valid only for full adaptive  
    parameter ROUTE_SUBFUNC = "XY"

)(
    ovc_avalable_all,
    dest_port_in_all,
    candidate_ovc_all,
    ivc_request_all,
    ovc_is_assigned_all,
    dest_port_out_all,
    masked_ovc_request_all,
    port_pre_sel,
    port_pre_sel_ld_all,
    sel,
    reset,
    clk
    
);
    localparam  P = 5;
    
    localparam  P_1     =   P-1,
                PV      =   V       *   P,
                PVV     =   PV      *  V,
                PVP_1   =   PV      *   P_1,
                VP_1    =   V       *   P_1;
                
     localparam LOCAL   =   3'd0,  
                EAST    =   3'd1, 
                NORTH   =   3'd2,  
                WEST    =   3'd3,  
                SOUTH   =   3'd4;  

    input   [PV-1       :   0]  ovc_avalable_all;
    input   [PVP_1-1    :   0]  dest_port_in_all;
    input   [PV-1       :   0]  ivc_request_all;
    input   [PV-1       :   0]  ovc_is_assigned_all; 
    output  [PVP_1-1    :   0]  dest_port_out_all;
    output  [PVV-1      :   0]  masked_ovc_request_all;
    input   [PVV-1      :   0]  candidate_ovc_all;
    input   [P_1-1      :   0]  port_pre_sel;
    input   [PV-1       :   0]  port_pre_sel_ld_all;
    output  [PV-1       :   0]  sel;
    input                       reset,clk;

    wire    [PV-1       :   0]  non_assigned_ovc_request_all; 
    wire    [P_1-1      :   0]  port_pre_sel_perport        [P-1    :   0];
    wire    [VP_1-1     :   0]  ovc_avalable_perport        [P-1    :   0];  
    wire    [VP_1-1     :   0]  ovc_avalable_ivc            [PV-1   :   0];
    wire    [P_1-1      :   0]  dest_port_ivc               [PV-1   :   0];
    wire    [V-1        :   0]  ovc_avb_muxed               [PV-1   :   0];  
    wire    [V-1        :   0]  ovc_request_ivc             [PV-1   :   0];
    wire    [PVV-1      :   0]  candidate_ovc_all_muxed;
    
    wire    [PVV-1      :   0]  candidate_ovc_x_all, candidate_ovc_y_all;
    wire    [PV-1       :   0]  route_subfunc_violated;
    
    assign non_assigned_ovc_request_all  = ivc_request_all & ~ovc_is_assigned_all;  
    assign port_pre_sel_perport[LOCAL]   = port_pre_sel;
    assign port_pre_sel_perport[EAST]    = {2'b00,port_pre_sel[1:0]};
    assign port_pre_sel_perport[NORTH]   = {1'b0,port_pre_sel[2],1'b0,port_pre_sel[0]};
    assign port_pre_sel_perport[WEST]    = {port_pre_sel[3:2],2'b0};
    assign port_pre_sel_perport[SOUTH]   = {port_pre_sel[3],1'b0,port_pre_sel[1],1'b0};
   

genvar i;
generate
 //remove avalable ovc of reciver port 
    for(i=0;i< P;i=i+1) begin :port_loop
        if(i==0) begin: first
		assign ovc_avalable_perport[i]=ovc_avalable_all [PV-1              :   V]; end
        else if(i==(P-1))begin : last 
		assign ovc_avalable_perport[i]=ovc_avalable_all [PV-V-1               :   0]; end
        else begin : middle
		assign ovc_avalable_perport[i]={ovc_avalable_all [PV-1  :   (i+1)*V],ovc_avalable_all [(i*V)-1  :   0]}; end
    end //for
        
    // IVC loop
    for(i=0;i< PV;i=i+1) begin :total_vc_loop
        //seprate input/output
        assign ovc_avalable_ivc[i]  =   ovc_avalable_perport[(i/V)];
        assign dest_port_ivc   [i]  =   dest_port_out_all [(i+1)*P_1-1  :   i*P_1   ];
        assign ovc_request_ivc [i]  = (non_assigned_ovc_request_all[i])? candidate_ovc_all_muxed  [(i+1)*V-1  :   i*V ]: {V{1'b0}};
        assign candidate_ovc_all_muxed[(i+1)*V-1 : i*V] = (sel[i]) ? candidate_ovc_y_all [(i+1)*V-1 : i*V] : candidate_ovc_x_all [(i+1)*V-1 : i*V]; 
       
        //available ovc multiplexer
        one_hot_mux #(
            .IN_WIDTH       (VP_1),
            .SEL_WIDTH      (P_1)
        )
        multiplexer
        (
            .mux_in     (ovc_avalable_ivc   [i]),
            .mux_out    (ovc_avb_muxed      [i]),
            .sel        (dest_port_ivc      [i])

        );
        
        // mask unavailable ovc from requests
        assign masked_ovc_request_all  [(i+1)*V-1   :   i*V ]     =   ovc_avb_muxed[i] & ovc_request_ivc [i];
        
       
        portsel_classic #(
           .SW_LOC    (i/V),
           .ROUTE_SUBFUNC   (ROUTE_SUBFUNC)
        )
        the_portsel
        (
           .reset             (reset),
           .clk               (clk),
           .port_pre_sel      (port_pre_sel_perport[i/V]),
           .port_pre_sel_ld       (port_pre_sel_ld_all[i]),
           .sel               (sel[i]),
           .dest_port_in      (dest_port_in_all[((i+1)*P_1)-1 : i*P_1]),
           .dest_port_out     (dest_port_out_all[((i+1)*P_1)-1 : i*P_1]),
          // .multi_dir         (multi_dir[i])
           .route_subfunc_violated    (route_subfunc_violated[i])
        );
           /* verilator lint_off WIDTH */ 
           if(ROUTE_TYPE ==  "FULL_ADAPTIVE") begin: full_adpt
           /* verilator lint_on WIDTH */ 
             // in full adaptive a packet which can be set to both x and y direction is not allowed to use escape VC in the y direction 
              assign candidate_ovc_y_all[((i+1)*V)-1 : i*V]=  (route_subfunc_violated[i]) ? candidate_ovc_all[((i+1)*V)-1 : i*V] & (~ESCAP_VC_MASK) :  candidate_ovc_all[((i+1)*V)-1 : i*V];       
          end else begin : partial_adpt
              assign candidate_ovc_y_all[((i+1)*V)-1 : i*V] =   candidate_ovc_all [((i+1)*V)-1 : i*V];
          end// ROUTE_TYPE
    end//for
    
    assign candidate_ovc_x_all=  candidate_ovc_all;
        
    
    
endgenerate



endmodule



module portsel_classic #(
    parameter SW_LOC    = 0,
    parameter ROUTE_SUBFUNC="XY"

)
(
    port_pre_sel,
    dest_port_out,
    dest_port_in,
    port_pre_sel_ld,
    sel,
    route_subfunc_violated,
    reset,
    clk


);

/************************
                
        destination-port_in
            x:  1 EAST, 0 WEST  
            y:  1 NORTH, 0 SOUTH
            ab: 00 : LOCAL, 10: xdir, 01: ydir, 11 x&y dir 
        sel:
             0: xdir
             1: ydir
        port_pre_sel
             0: xdir
             1: ydir  

************************/


    input           reset,clk;
    input   [3:0]   port_pre_sel;
    input           port_pre_sel_ld;
    output          sel;
    input   [3:0]   dest_port_in;
    output  [3:0]   dest_port_out;
    output          route_subfunc_violated;
    
    wire  x,y,a,b;
    reg  [3:0] port_pre_sel_delayed ,  port_pre_sel_latched;
    
    reg [4:0] portout;

    localparam LOCAL    =       3'd0,  
               EAST     =       3'd1, 
               NORTH    =       3'd2,  
               WEST     =       3'd3,  
               SOUTH    =       3'd4;  

    
   
    assign {x,y,a,b} = dest_port_in;
    // the destination port must not change after assigning OVC. latch the port_pre_sel result after assigning OVC.  
    always @(posedge clk or posedge reset) begin 
        if(reset) begin 
            port_pre_sel_delayed <= 4'd0;
            port_pre_sel_latched <= 4'd0;
        end else begin 
            if(port_pre_sel_ld) port_pre_sel_delayed <= port_pre_sel;
            if(port_pre_sel_ld) port_pre_sel_latched <= port_pre_sel;
            else                port_pre_sel_latched <= port_pre_sel_delayed;
            
        end
    end
    
    always @(*)begin 
        case({a,b})
            2'b10 : portout = {1'b0,~x,1'b0,x,1'b0};
            2'b01 : portout = {~y,1'b0,y,1'b0,1'b0};
            2'b11 : portout = (port_pre_sel_latched[{x,y}])?  {~y,1'b0,y,1'b0,1'b0}: {1'b0,~x,1'b0,x,1'b0} ;
            2'b00 : portout =  5'b00001;
         endcase
   end //always
    
   assign sel =  portout[NORTH] | portout[SOUTH];
    
    remove_sw_loc_one_hot #(
        .P(5),
        .SW_LOC(SW_LOC)
    )conv
    (
        .destport_in(portout),
        .destport_out(dest_port_out)
    );
    
    generate 
    /* verilator lint_off WIDTH */ 
    if(ROUTE_SUBFUNC=="XY") begin :xy_lp
    /* verilator lint_on WIDTH */ 
        assign route_subfunc_violated = a&b;
    end else begin : nonxy
        assign route_subfunc_violated = a&b&y;    
    end
    endgenerate

endmodule

