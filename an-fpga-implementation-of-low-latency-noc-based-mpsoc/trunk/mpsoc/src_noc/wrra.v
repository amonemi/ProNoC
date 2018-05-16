/**********************************************************************
**	File:  wrra.v
**	Date:2017-07-11   
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
**	Weighted round robin arbiter support for QoS support in NoC:	
**  Packets are injected with initial weights. The defualt value is 1. 
**  Weights are assigned to each input ports according to contention degree. 
**  The contention degree is calculated based on the accumulation of input ports 
**  weight sending packet to the same output ports.
**  Swich allocator's output arbters' priority is lucked until the winner's 
**  input weight is not consumed. A weight is consumed when a packet is sent.
******************************************************************/



 `timescale  1ns/1ps






module  wrra #(
    parameter ARBITER_WIDTH = 8,
    parameter WEIGHTw = 4, // maximum weight size in bits
    parameter EXT_P_EN = 1 
        
)
(  
   
   ext_pr_en_i,
   clk, 
   reset, 
   request, 
   grant,
   any_grant,
   weight_array,
   winner_weight_consumed
);

    localparam WEIGHT_ARRAYw= WEIGHTw * ARBITER_WIDTH;

    input                                  ext_pr_en_i;
    input     [ARBITER_WIDTH-1  :    0]    request;
    output    [ARBITER_WIDTH-1  :    0]    grant;
    output                                 any_grant;
    input                                  clk;
    input                                  reset;
    input    [WEIGHT_ARRAYw-1   :   0]     weight_array;
    output                                 winner_weight_consumed;


    wire [WEIGHTw-1 :   0] weight [ARBITER_WIDTH-1  :   0];
    wire [ARBITER_WIDTH-1:  0] weight_counter_is_reset;
    
    genvar i;
    generate 
    for (i=0; i<ARBITER_WIDTH; i=i+1) begin : wcount 
        // seperate wieghts
        assign weight [i] = weight_array [ ((i+1)*WEIGHTw)-1    :   i*WEIGHTw];
       
        weight_counter #(
            .WEIGHTw(WEIGHTw)
        )
        w_counter
        (
            .load_i(1'b0),
            .weight_i(weight [i]),
            .reset(reset),
            .clk(clk),
            .decr(grant[i]),
            .out(weight_counter_is_reset[i])
        );
    
    end
    endgenerate
    
   
    
    
    // one hot mux
    
    one_hot_mux #(
        .IN_WIDTH(ARBITER_WIDTH),
        .SEL_WIDTH(ARBITER_WIDTH),
        .OUT_WIDTH(1)
    )
    mux
    (
        .mux_in(weight_counter_is_reset),
        .mux_out(winner_weight_consumed),
        .sel(grant)
    );
    
    wire priority_en = (EXT_P_EN == 1) ? ext_pr_en_i & winner_weight_consumed : winner_weight_consumed;

    //round robin arbiter with external priority

     arbiter_priority_en #(
        .ARBITER_WIDTH(ARBITER_WIDTH)
    )
    rra
    (
        .request(request),
        .grant(grant),
        .any_grant(any_grant),
        .clk(clk),
        .reset(reset),
        .priority_en(priority_en)
    );

endmodule






module  rra_priority_lock #(
    parameter    ARBITER_WIDTH    =8        
)
(  
   
   ext_pr_en_i,
   winner_weight_consumed,
   pr_en_array_i,
   
   clk, 
   reset, 
  
   request, 
   grant,
   any_grant
);

    
    input     [ARBITER_WIDTH-1:     0]     pr_en_array_i;
    input                                  ext_pr_en_i;
    output                                 winner_weight_consumed;
    input     [ARBITER_WIDTH-1  :    0]    request;
    output    [ARBITER_WIDTH-1  :    0]    grant;
    output                                 any_grant;
    input                                  clk;
    input                                  reset;  
    
    
    // one hot mux
    
    one_hot_mux #(
        .IN_WIDTH(ARBITER_WIDTH),
        .SEL_WIDTH(ARBITER_WIDTH),
        .OUT_WIDTH(1)
    )
    mux
    (
        .mux_in(pr_en_array_i),
        .mux_out(winner_weight_consumed),
        .sel(grant)
    );
    
    wire priority_en = ext_pr_en_i & winner_weight_consumed;

    //round robin arbiter with external priority

     arbiter_priority_en #(
        .ARBITER_WIDTH(ARBITER_WIDTH)
    )
    rra
    (
        .request(request),
        .grant(grant),
        .any_grant(any_grant),
        .clk(clk),
        .reset(reset),
        .priority_en(priority_en)
    );

endmodule





/**************
*   weight_counter
*
***************/


module weight_counter #(
    parameter WEIGHTw=4
)(
    
    weight_i,
    decr,
    load_i,
    out,
    reset,
    clk    

);

    input [WEIGHTw-1    :   0]  weight_i;
    input reset,clk,decr,load_i;
    output  out;
    wire [WEIGHTw-1    :   0]  weight;

    reg [WEIGHTw-1    :   0] counter,counter_next;
    wire couner_zero, load;
    
    assign couner_zero = counter == {WEIGHTw{1'b0}};
    assign load =  (counter > weight_i) | load_i;
    assign out = couner_zero;
    assign weight= (weight_i == {WEIGHTw{1'b0}} )? 1 : weight_i; // minimum weight is 1;
    always @(*)begin 
        counter_next = counter;
        if(load) counter_next  = weight- 1'b1 ;
        if(decr) counter_next  = (couner_zero)? weight-1'b1  : counter - 1'b1; // if the couner has zero value then the load is active not decrese
    
    end
    

    always @(posedge clk or posedge reset) begin  
        if (reset)begin 
            counter<= {WEIGHTw{1'b0}};
        end else begin 
            counter <= counter_next;        
        end   //else
    end //always   
    
    
    
  


endmodule


/**************
*   weight_counter
*
***************/


module classic_weight_counter #(
    parameter WEIGHTw=4
)(
    
    weight_i,
    decr,
    load_i,
    out,
    reset,
    clk    

);

    input [WEIGHTw-1    :   0]  weight_i;
    input reset,clk,decr,load_i;
    output  out;
    wire [WEIGHTw-1    :   0]  weight;

    reg [WEIGHTw-1    :   0] counter,counter_next;
    wire couner_zero, load;
    
    assign couner_zero = counter == {WEIGHTw{1'b0}};
    assign load =  (counter > weight_i) | load_i;
    assign out = couner_zero;
    assign weight= (weight_i == {WEIGHTw{1'b0}} )? 1 : weight_i; // minimum weight is 1;
    always @(*)begin 
        counter_next = counter;
        if(load) counter_next  = weight- 1'b1 ;
        if(decr && !couner_zero) counter_next  = counter - 1'b1; // if the couner has zero value then the load is active not decrese
    
    end
    

    always @(posedge clk or posedge reset) begin  
        if (reset)begin 
            counter<= {WEIGHTw{1'b0}};
        end else begin 
            counter <= counter_next;        
        end   //else
    end //always   
    
    
    
endmodule



/***************
*   weight_control
***************/


module  weight_control #(
    parameter ARBITER_TYPE="WRRA",
    parameter SW_LOC=0,
    parameter WEIGHTw= 4,
    parameter WRRA_CONFIG_INDEX=0,
    parameter P=5  
)
(
   
    sw_is_granted,
    flit_is_tail,  
    iport_weight,
    granted_dest_port,
    weight_is_consumed_o, 
    oports_weight,  
    refresh_w_counter,     
    clk,
    reset           
);      

    localparam 
        W = WEIGHTw,
        WP = W * P,
        P_1 = P-1;
    
    localparam 
        [W-1 : 0] INIT_WEIGHT = 1;
        
    localparam PROPOGATE_EQUALL = (WRRA_CONFIG_INDEX==0 ),
               PROPOGATE_LIMITED = (WRRA_CONFIG_INDEX==1 );
    
    


    input  sw_is_granted , flit_is_tail;
    input  [WEIGHTw-1 : 0] iport_weight;
    input  clk,reset;                  
    output weight_is_consumed_o;         
    input  [P_1-1 : 0] granted_dest_port; 
    output [WP-1 : 0] oports_weight;  
    input refresh_w_counter;
  
    // wire ivc_empty = ~ivc_not_empty;    
    wire counter_is_reset;
    wire weight_dcrease_en = sw_is_granted & flit_is_tail;
    wire [P-1 : 0] dest_port; 
    reg  [W-1 : 0] oport_weight_counter [P-1 : 0];
    reg  [W-1 : 0] oport_weight [P-1 : 0];
    
    
    add_sw_loc_one_hot #(
    	.P(P),
    	.SW_LOC(SW_LOC)
    )
    add_sw_loc
    (
    	.destport_in(granted_dest_port),
    	.destport_out(dest_port)
    );
    
    
    assign oports_weight [W-1 : 0] = {W{1'b0}};
    
    genvar i;
    generate 
    
    
    if(PROPOGATE_EQUALL | PROPOGATE_LIMITED )begin : eq         
        
         for (i=1;i<P;i=i+1)begin : port
             if(i==SW_LOC) begin : if1
                assign oports_weight [(i+1)*W-1 : i*W] = {W{1'b0}};
             end else begin :else1
                assign oports_weight[(i+1)*W-1 : i*W]  = iport_weight; 
            end
         end //for
           
    end else begin :neq
        
        always @(*)begin 
               oport_weight_counter[0]= {W{1'b0}};// the output port weight of local port is useless. hence fix it as zero.
               oport_weight[0]= {W{1'b0}};
        end
    
         
        for (i=1;i<P;i=i+1)begin : port
             if(i==SW_LOC) begin : if1
                
                always @(*) begin 
                    oport_weight_counter[i]= {W{1'b0}};// The loopback injection is forbiden hence it will be always as zero.
                    oport_weight[i]= {W{1'b0}};
                end
                assign oports_weight [(i+1)*W-1 : i*W] = {W{1'b0}};
             end else begin :else1
        
                always @ (posedge clk or posedge reset) begin 
                    if(reset) begin 
                        oport_weight_counter[i]<=INIT_WEIGHT;
                    end else begin 
                        if (weight_dcrease_en && counter_is_reset) oport_weight_counter[i]<= INIT_WEIGHT;
                        else if (weight_dcrease_en && dest_port[i] && oport_weight_counter[i] != {W{1'b1}} )oport_weight_counter[i]<= oport_weight_counter[i] +1'b1;
                    end
                end //always
                
                always @ (posedge clk or posedge reset) begin 
                    if(reset) begin 
                        oport_weight[i]<={W{1'b0}};
                    end else begin 
                        if (weight_dcrease_en && counter_is_reset) oport_weight[i]<= oport_weight_counter[i];  //capture oweight counters                    
                    end
                end //always
                assign oports_weight [(i+1)*W-1 : i*W] = oport_weight[i];
             end  //else 
        
           
           
        end //for
    
    
    end  
    
    
    /* verilator lint_off WIDTH */
    if(ARBITER_TYPE == "WRRA_CLASSIC") begin : wrra_classic 
    /* verilator lint_on WIDTH */
        // use classic WRRA. only for compasrion with propsoed wrra 
    
        classic_weight_counter #(
            .WEIGHTw(WEIGHTw)
        )
           iport_weight_counter
        (
            .load_i(refresh_w_counter),    
            .weight_i(iport_weight),
            .reset(reset),
            .clk(clk),
            .decr(weight_dcrease_en),
            .out(counter_is_reset)
        );     
    
    end else begin : wrra_mine
        // weight counters   
        weight_counter #(
            .WEIGHTw(WEIGHTw)
        )
        iport_weight_counter
        (
            .load_i(refresh_w_counter),    
            .weight_i(iport_weight),
            .reset(reset),
            .clk(clk),
            .decr(weight_dcrease_en),
            .out(counter_is_reset)
        ); 
    
    
    end    
    
    endgenerate
    
      
  
    
   
    
    
    assign weight_is_consumed_o = counter_is_reset; //  & flit_is_tail ;

endmodule




/***************
*       wrra_contention_gen
* generate contention based on number of request to 
* the same output port
***************/


module  wrra_contention_gen #(
    parameter V=4,
    parameter P=5,
    parameter WRRA_CONFIG_INDEX=0,
    parameter WEIGHTw = 4 // WRRA width        
)(
    ovc_is_assigned_all, 
    ivc_request_all,
    dest_port_all,    
    iport_weight_all,
    oports_weight_all,
    contention_all,
    limited_oport_weight_all    
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
        P_1 = P-1,
        PV = P * V, 
        VP_1= V * P_1,
        PVP_1 = PV * P_1,
        Pw= log2(P),
        PwP= Pw *P,
        W= WEIGHTw,
        WP= W * P,
        WPP = WP * P; 
        
        localparam 
            VALID_IF_HAS_FLIT  = 1, //1: has flit 0: VC-Assigned
            PROPOGATE_EQUALL = (WRRA_CONFIG_INDEX==0 ),
            PROPOGATE_LIMITED = (WRRA_CONFIG_INDEX==1 );
       
        
    input  [PVP_1-1 :  0] dest_port_all;
    input  [PV-1 : 0] ovc_is_assigned_all; 
    input  [PV-1 : 0] ivc_request_all;
    input  [WP-1 : 0] iport_weight_all;
    output [WP-1 : 0] contention_all;
    input  [WPP-1 : 0] oports_weight_all;
    input  [WP-1 : 0] limited_oport_weight_all;
    
    
    wire [P-1 : 0] destport_sum [P-1 : 0];//destport_sum[inport-num][out-num]=  out-port is requested by inport-num
    wire [P-1 : 0] contention_one_hot [P-1  :   0];  //contention_one_hot[outport-num][inport-num]=  inport- is requesting this outport
    
    wire [W-1 : 0] iport_weight [P-1  :   0];
    wire [W-1 : 0] weight_sum [P-1  :   0];  
    wire [W-1 : 0] contention [P-1  :   0];  
    wire [WP-1 : 0] weight_array_per_outport [P-1  :   0]; 
    wire [WP-1: 0] oports_weight [P-1  :   0]; 
    // weight_array_per_outport[outport-num][inport-num]= weight-inport-num if  inport- is requesting this outport
    
   
   wire [PV-1 : 0] weight_is_valid = (VALID_IF_HAS_FLIT)? ivc_request_all : ovc_is_assigned_all ;
   
    genvar j,i;
    generate 
    for (i=0;i<P; i=i+1) begin : port_lp
        assign iport_weight[i]= iport_weight_all[(i+1)*W-1  : i*W]; 
        assign oports_weight[i]= oports_weight_all [(i+1)*WP-1  : i*WP];       
       
         //get the lis of all destination ports requested by each port
         wrra_inputport_destports_sum #(
         	.V(V),
         	.P(P),
         	.SW_LOC(i)
         )
         destports_sum
         (
         	.weight_is_valid(weight_is_valid[(i+1)*V-1  : i*V]),
         	.dest_ports(dest_port_all [(i+1)*VP_1-1  : i*VP_1]),
         	.destports_sum(destport_sum[i])
         );
         
        
         
         
         for (j=0;j<P;j=j+1) begin : outlp1 
            assign  contention_one_hot[j][i] =  destport_sum[i][j];
            if(PROPOGATE_EQUALL | PROPOGATE_LIMITED ) begin : peq
               assign  weight_array_per_outport[j][(i+1)*W-1  : i*W] = (contention_one_hot[j][i])? iport_weight[i] : {W{1'b0}}; 
            end  
            else begin : pneq
               assign  weight_array_per_outport[j][(i+1)*W-1  : i*W] = (contention_one_hot[j][i])? oports_weight[i][(j+1)*W-1 : j*W] : {W{1'b0}};               
            end         
         end//for
         
                 
         //contention is the sum of all inputports weights requesting this outputport
         accumulator #(
            .INw(WP),
            .OUTw(W),
            .NUM(P)
         
         )
         accum
         (
            .in_all(weight_array_per_outport[i]),
            .out(weight_sum[i])         
         );
         
       
         if(PROPOGATE_LIMITED) begin : limted
         
            wire [W-1 : 0] limited_oport_weight [P-1 : 0]; 
            for (j=0;j<P;j=j+1) begin : outlp1 
                assign  limited_oport_weight [j] = limited_oport_weight_all [(j+1)*W-1 : j*W];
                assign contention[j] = (limited_oport_weight [j] > weight_sum [j]) ? weight_sum [j] : limited_oport_weight [j];
                
            end
         
         
         end else begin : eq_or_actual
            for (j=0;j<P;j=j+1) begin : outlp1 
                assign contention[j] = weight_sum [j];
            end
         end
         
         
         
       
         
         assign contention_all[(i+1)*W-1 : i*W] =  contention[i];
    
    end    
    endgenerate  

endmodule


module  wrra_inputport_destports_sum #(
    parameter V=4,
    parameter P=5,
    parameter SW_LOC=0        
)(
    weight_is_valid,
    dest_ports,
    destports_sum
    
);

    localparam 
        P_1 = P - 1,
        VP_1 = V * P_1;

    input [V-1 : 0] weight_is_valid;
    input [VP_1-1 : 0] dest_ports;
    output [P-1 : 0] destports_sum;
     
    wire [VP_1-1 : 0] dest_ports_masked;     

  
    wire  [P_1-1    :   0] sum;
    
    genvar i;
    generate 
    for (i=0;i<V; i=i+1) begin : port_lp
        assign  dest_ports_masked [(i+1)*P_1-1  : i*P_1] =  (weight_is_valid[i]) ? dest_ports [(i+1)*P_1-1  : i*P_1] : {P_1{1'b0}};     
    end    
    endgenerate
    
    custom_or #(
    	.IN_NUM(V),
    	.OUT_WIDTH(P_1)
    )
    custom_or(
    	.or_in(dest_ports_masked),
    	.or_out(sum)
    );
    
    
    
    add_sw_loc_one_hot #(
        .P(P),
        .SW_LOC(SW_LOC)
    )
    add_sw_loc
    (
        .destport_in(sum),
        .destport_out(destports_sum)
    );
    

endmodule

/***************
*   weights_update
*
***************/

module weights_update # (
    parameter ARBITER_TYPE="WRRA",
    parameter V=4,
    parameter P=5,
    parameter Fpay =32,
    parameter WEIGHTw=4,
    parameter C = 4,
    parameter WRRA_CONFIG_INDEX=0,
    parameter ADD_PIPREG_AFTER_CROSSBAR=0,
    parameter CLASS_HDR_WIDTH =8,
    parameter ROUTING_HDR_WIDTH =8,
    parameter DST_ADR_HDR_WIDTH =8,
    parameter SRC_ADR_HDR_WIDTH =8   

)(
    limited_oports_weight,
    contention_all, 
    flit_in_all,
    flit_out_all,
    flit_out_we_all,
    iport_weight_all,
    refresh_w_counter,
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
     

    localparam 
        Fw = 2+V+Fpay,    //flit width;  
        PFw = P * Fw,
        W= WEIGHTw,
        WP= W * P,
        ALL_WEIGHTw=log2(WP);
        
    localparam  PROPOGATE_LIMITED = (WRRA_CONFIG_INDEX==1 ),
                INIT_WEIGHT = 1;
       

    input [WP-1 : 0] contention_all;
    input [PFw-1 :  0]  flit_in_all;
    output[PFw-1 :  0]  flit_out_all;
    input [P-1 :  0]  flit_out_we_all;
    input [WP-1: 0] iport_weight_all;
    output[WP-1 : 0] limited_oports_weight;  
    output refresh_w_counter;
    input clk,reset;
       
    //assign refresh_w_counter = 1'b0;   
       
    genvar i;
    generate 
    //nonlocal port
    for (i=1; i<P; i=i+1) begin : non_local_port
    
        weight_update_per_port #(
        	.V(V),
        	.C(C),
        	.Fpay(Fpay),
        	.WEIGHTw(WEIGHTw),
        	.CLASS_HDR_WIDTH(CLASS_HDR_WIDTH),
        	.WRRA_CONFIG_INDEX(WRRA_CONFIG_INDEX),
        	.ROUTING_HDR_WIDTH(ROUTING_HDR_WIDTH),
        	.ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        	.DST_ADR_HDR_WIDTH(DST_ADR_HDR_WIDTH),
        	.SRC_ADR_HDR_WIDTH(SRC_ADR_HDR_WIDTH)
        )
        update_per_port
        (
        	.contention_in(contention_all[(i+1)*W-1  :   i*W]),
        	.flit_in(flit_in_all[ (i+1)*Fw-1 : i*Fw]),
        	.flit_out(flit_out_all[(i+1)*Fw-1 : i*Fw]),
        	.flit_out_we(flit_out_we_all[i]),
           	.clk(clk),
        	.reset(reset)
        );
       
        
    
    end
    
   
       
    
    
    if(PROPOGATE_LIMITED) begin : limited
       
        wire [ALL_WEIGHTw-1 :   0] iweight_sum;
        wire [P-1   :   0] flit_out_is_tail,tail_flit_is_sent;
        wire any_tail_is_sent;
        
        wire capture_o_weights;
        reg  [W-1 : 0] oport_weight_counter [P-1 : 0];
        reg  [W-1 : 0] limited_oport_weight [P-1 : 0];
        
        assign tail_flit_is_sent = (flit_out_we_all & flit_out_is_tail);
        assign any_tail_is_sent = | tail_flit_is_sent;
        for (i=0; i<P; i=i+1) begin : lp
            assign flit_out_is_tail[i] = flit_out_all[(i+1)*Fw-2];
            
            always @ (posedge clk or posedge reset) begin 
                    if(reset) begin 
                        oport_weight_counter[i]<=INIT_WEIGHT;
                    end else begin 
                        if (any_tail_is_sent && capture_o_weights) oport_weight_counter[i]<= INIT_WEIGHT;
                        else if (any_tail_is_sent && tail_flit_is_sent[i] && oport_weight_counter[i] != {W{1'b1}})oport_weight_counter[i]<= oport_weight_counter[i] +1'b1;
                    end
                end //always
                
                always @ (posedge clk or posedge reset) begin 
                    if(reset) begin 
                        limited_oport_weight[i]<={W{1'b0}};
                    end else begin 
                        if (any_tail_is_sent && capture_o_weights) limited_oport_weight[i]<= oport_weight_counter[i];  //capture oweight counters                    
                    end
                end //always
                assign limited_oports_weight [(i+1)*W-1 : i*W] = limited_oport_weight[i];
            
            
        end
        //all input wights summation
         accumulator #(
            .INw(WP),
            .OUTw(ALL_WEIGHTw),
            .NUM(P)
         
         )
         accum
         (
            .in_all(iport_weight_all),
            .out(iweight_sum)         
         );
         
        
         
         weight_counter #(
            .WEIGHTw(ALL_WEIGHTw)
         )
         weight_counter
         (
            .weight_i(iweight_sum),
            .reset(reset),
            .clk(clk),
            .decr(any_tail_is_sent),
            .load_i(1'b0),
            .out(capture_o_weights )
         // .out(refresh_w_counter)
         );
         
         
         
         
         
    
    end else begin :dontcare
        assign limited_oports_weight = {WP{1'bX}};    
    end 
    
   
    /* verilator lint_off WIDTH */    
    if(ARBITER_TYPE == "WRRA")begin  : wrra
    /* verilator lint_on WIDTH */
    
         assign refresh_w_counter=1'b0;
    
   
    end else begin  :wrra_classic
    
    
       
        wire [ALL_WEIGHTw-1 :   0] iweight_sum;
        wire any_tail_is_sent;
        wire [P-1   :   0] flit_out_is_tail,tail_flit_is_sent;
        for (i=0; i<P; i=i+1) begin : lp2
            assign flit_out_is_tail[i] = flit_out_all[(i+1)*Fw-2];
        end
        
        
        assign tail_flit_is_sent = (flit_out_we_all & flit_out_is_tail);
        assign any_tail_is_sent = | tail_flit_is_sent;
    
    
    
         //all input wights summation
         accumulator #(
            .INw(WP),
            .OUTw(ALL_WEIGHTw),
            .NUM(P)
         
         )
         accum
         (
            .in_all(iport_weight_all),
            .out(iweight_sum)         
         );
         
        
         
         weight_counter #(
            .WEIGHTw(ALL_WEIGHTw)
         )
         weight_counter
         (
            .weight_i(iweight_sum-1),
            .reset(reset),
            .clk(clk),
            .decr(any_tail_is_sent),
            .load_i(1'b0),
            .out(refresh_w_counter)
         );
    
    end
  
   
   
   
   
    
    
    endgenerate
    
    
        
 
    
       
    
    // localport 
    assign flit_out_all[Fw-1 : 0] = flit_in_all [Fw-1 : 0]; 



endmodule



module weight_update_per_port # (
    parameter V=4,
    parameter C=2,
    parameter Fpay =32,
    parameter WEIGHTw=4,
    parameter WRRA_CONFIG_INDEX=0,
    parameter ADD_PIPREG_AFTER_CROSSBAR=0,
    parameter CLASS_HDR_WIDTH =8,
    parameter ROUTING_HDR_WIDTH =8,
    parameter DST_ADR_HDR_WIDTH =8,
    parameter SRC_ADR_HDR_WIDTH =8   

)(
    contention_in, 
    flit_in,
    flit_out,
    flit_out_we,
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

    localparam 
        Fw = 2+V+Fpay,    //flit width;  
        Cw = log2(C),
        W=WEIGHTw;
        
    localparam WEIGHT_LOC_LSB = DST_ADR_HDR_WIDTH+SRC_ADR_HDR_WIDTH+ROUTING_HDR_WIDTH+ Cw;   
    localparam WEIGHT_LATCHED = 0;  //(WRRA_CONFIG_INDEX==0 || WRRA_CONFIG_INDEX==1 || WRRA_CONFIG_INDEX==2 || WRRA_CONFIG_INDEX==3 ); //1: no latched  0: latched
           
    
    input [W-1 : 0] contention_in;
    input [Fw-1 :  0]  flit_in;
    output[Fw-1 :  0]  flit_out;
    input flit_out_we;
    input clk,reset;
 
   
   
    
    wire flit_is_hdr = flit_in[Fw-1];
    reg [W-1 : 0]  contention;
   
    generate
    if(WEIGHT_LATCHED == 1) begin : add_latch
     
        wire update = flit_out_we & flit_is_hdr;
        wire [W-1 : 0] contention_out;
        output_weight_latch #(
            .WEIGHTw (WEIGHTw)    
        )
        out_weight_latch
        (
            .weight_in(contention_in),
            .weight_out(contention_out),
            .clk(clk),
            .reset(reset),
            .update( update )    
        );   
        always @ (*) begin 
           contention= contention_out;
        end
     
     end else  if(ADD_PIPREG_AFTER_CROSSBAR==1)begin : add_reg 
       always @ (posedge clk or posedge reset) begin 
            if(reset) begin 
                contention<={W{1'b0}};
            end else begin 
                 contention<= contention_in;
            end
        end
     end else begin : no_reg
        always @ (*) begin 
           contention= contention_in;
        end
     end  
     
       
     endgenerate 
     
   
    
    assign flit_out = (flit_is_hdr) ? {flit_in[Fw-1 : WEIGHT_LOC_LSB+WEIGHTw ] ,contention, flit_in[WEIGHT_LOC_LSB-1 : 0] }   : flit_in;
        

endmodule




module output_weight_latch #(
    parameter WEIGHTw =4    
)(
    weight_in,
    weight_out,
    clk,
    reset,
    update    
);

localparam W=WEIGHTw;
    
 input [W-1 : 0] weight_in;
 output reg [W-1 : 0] weight_out;
 input clk, reset, update;
 
 reg  [W-1 : 0] counter,counter_next,weight_out_next;
 
 wire less =  weight_in <  weight_out; 
 wire counter_is_zero = counter == {W{1'b0}};
   
 always @ (*)begin 
    counter_next = counter;
    weight_out_next = weight_out; 
    if(update)begin 
        if (less ) begin // input weight is smaller than the captured one before
           if(counter_is_zero) begin // 
               weight_out_next = weight_in;
           end else begin 
             counter_next =   counter - 1'b1;           
           end
        end
        else begin 
            counter_next = (weight_in[W-1] != 1'b1) ?  {weight_in[W-2:0],1'b0} : {W{1'b1}}; 
            weight_out_next = weight_in;
        end    
    end  
 end


always @ (posedge clk or posedge reset) begin 
    if(reset) begin 
        counter = {WEIGHTw{1'b0}};
        weight_out_next = {WEIGHTw{1'b0}}; 
    end else begin 
        counter = counter_next;
        weight_out = weight_out_next; 
    end
end

endmodule





module  accumulator #(
    parameter INw= 20,
    parameter OUTw=4,
    parameter NUM =5
)
(
    in_all,
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
    
    localparam N= INw/NUM,
               SUMw= log2(NUM)+N; 
    input [INw-1  :   0] in_all;
    output[OUTw-1 :   0] out;
    
    wire [N-1   :   0] in [NUM-1    :   0];
    reg [SUMw-1 :   0] sum;
  
  
    genvar i;
    generate 
    for (i=0; i<NUM; i=i+1)begin : lp
        assign in[i] = in_all[(i+1)*N-1 : i*N];    
    end
    
    if(  SUMw ==  OUTw) begin :  equal
        assign out = sum;
    end else begin : not_eq
        assign out = (sum[SUMw-1 : OUTw] > 0 ) ? {OUTw{1'b1}} : sum[OUTw-1  :   0] ;
    end
    
  
    
    endgenerate
  
  // This is supposed to be synyhesized as "sum=in[0]+in[1]+...in[Num-1]"; 
  // It works with Quartus, Verilator and Modelsim compilers  
    integer k; 
    always @(*)begin 
        sum=0;
        for (k=0;k<NUM;k=k+1)begin 
             sum= sum + {{(SUMw-N){1'b0}},in[k]};        
        end   
    end
    //In case your compiler could not synthesize or wrongly synthesizes it try this
    //assumming the maximum NUM as parameter can be 20:
    /*
    generate 
     wire [N-1   :   0] tmp [19    :   0];
     for (i=0; i<NUM; i=i+1)begin : lp
        assign tmp[i] = in_all[(i+1)*N-1 : i*N];    
     end
     for (i=NUM; i<20; i=i+1)begin : lp2
        assign tmp[i] = {N{1'b0}};    
     end
    
    always @(*)begin 
              sum= tmp[0] + tmp[1]+ tmp[2] + ...+ tmp[19];        
    end
    endgenerate     
    */

endmodule
