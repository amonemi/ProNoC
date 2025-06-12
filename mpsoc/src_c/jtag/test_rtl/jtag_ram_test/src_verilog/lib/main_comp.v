`include "pronoc_def.v"
/**********************************************************************
**    File: main_comp.v
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
**    This file contains several general RTL modules such as 
**    different types of multiplexors, converters and counters ...
**
**************************************************************/
`ifndef PRONOC_COMMON
`define PRONOC_COMMON

module pronoc_register #(
    parameter W=1,
    parameter  RESET_TO={W{1'b0}}
)( 
    input [W-1: 0] D_in,
    input reset,    
    input clk,      
    output [W-1: 0] Q_out
);
    pronoc_register_reset_init #(
        .W(W)           
    )reg1( 
        .D_in(D_in),
        .reset(reset),  
        .clk(clk),      
        .Q_out(Q_out),
        .reset_to(RESET_TO[W-1 : 0])
    );
endmodule


module pronoc_register_reset_init #(
    parameter W=1       
)( 
    input [W-1: 0] D_in,
    input reset,    
    input clk,      
    output reg [W-1: 0] Q_out,
    input [W-1 : 0] reset_to
);
    always @ (`pronoc_clk_reset_edge )begin 
        if(`pronoc_reset)   Q_out<=reset_to;
        else        Q_out<=D_in;
    end   
endmodule


module pronoc_register_reset_init_ld_en   #(
    parameter W=1       
)( 
    input [W-1: 0] D_in,
    input reset,    
    input clk, 
    input ld,
    output reg [W-1: 0] Q_out,
    input [W-1 : 0] reset_to
);    
    always @ (`pronoc_clk_reset_edge )begin 
        if(`pronoc_reset)   Q_out<=reset_to;
        else  if(ld)      Q_out<=D_in;
    end        
endmodule


module pronoc_register_ld_en  #(
    parameter W=1,
    parameter  RESET_TO={W{1'b0}}
)( 
    input [W-1: 0] D_in,
    input reset,    
    input clk,  
    input ld,
    output [W-1: 0] Q_out
);
    pronoc_register_reset_init_ld_en  #(
        .W(W)           
    )reg1( 
        .D_in(D_in),
        .reset(reset),  
        .clk(clk),  
        .ld(ld),
        .Q_out(Q_out),
        .reset_to(RESET_TO[W-1 : 0])
    );
endmodule



/*********************************
*   multiplexer
********************************/
module one_hot_mux #(
    parameter   IN_WIDTH = 20,
    parameter   SEL_WIDTH = 5, 
    parameter   OUT_WIDTH = IN_WIDTH/SEL_WIDTH
)(
    input [IN_WIDTH-1 : 0] mux_in,
    output[OUT_WIDTH-1 : 0] mux_out,
    input[SEL_WIDTH-1 : 0] sel
);
    wire [IN_WIDTH-1 : 0] mask;
    wire [IN_WIDTH-1 : 0] masked_mux_in;
    wire [SEL_WIDTH-1: 0]    mux_out_gen [OUT_WIDTH-1: 0]; 
    
    genvar i,j;
    //first selector masking
    generate    // first_mask = {sel[0],sel[0],sel[0],....,sel[n],sel[n],sel[n]}
        for(i=0; i<SEL_WIDTH; i=i+1) begin : mask_loop
            assign mask[(i+1)*OUT_WIDTH-1 : (i)*OUT_WIDTH] = {OUT_WIDTH{sel[i]} };
        end
        assign masked_mux_in = mux_in & mask;
        for(i=0; i<OUT_WIDTH; i=i+1) begin : lp1
            for(j=0; j<SEL_WIDTH; j=j+1) begin : lp2
                assign mux_out_gen [i][j] = masked_mux_in[i+OUT_WIDTH*j];
            end
            assign mux_out[i] = | mux_out_gen [i];
        end
    endgenerate
endmodule


/******************************
*    One hot demultiplexer
****************************/   
module one_hot_demux    #(
    parameter IN_WIDTH=5,
    parameter SEL_WIDTH=4,
    parameter OUT_WIDTH=IN_WIDTH*SEL_WIDTH
)(
    input   [SEL_WIDTH-1 : 0] demux_sel,//selectore
    input   [IN_WIDTH-1 : 0] demux_in,//repeated
    output  [OUT_WIDTH-1 : 0]  demux_out
);

    genvar i,j;
    generate 
    for(i=0;i<SEL_WIDTH;i=i+1)begin :loop1
        for(j=0;j<IN_WIDTH;j=j+1)begin :loop2
                assign demux_out[i*IN_WIDTH+j] = demux_sel[i]   &   demux_in[j];
        end//for j
    end//for i
    endgenerate
endmodule

/**************************
*    reduction_or
***************************/
module reduction_or #(
    parameter W = 5,//out width
    parameter N = 4 //array lenght 
)(
    D_in,
    Q_out
);
    input  [W-1 : 0] D_in [N-1 : 0];
    output reg [W-1 : 0] Q_out;
    
    // assign Q_out = D_in.or(); //it is not synthesizable able by some compiler
    always_comb begin
        Q_out = {W{1'b0}};
        for (int i = 0; i < N; i++)
            Q_out |=   D_in[i];
    end
endmodule


/*****************************************
* sum the output of all ports 
* except the output of  port itself
****************************************/
module outport_sum #(
    parameter IN_ARRAY_WIDTH =10,
    parameter IN_NUM =5,
    parameter IN_WIDTH = IN_ARRAY_WIDTH/IN_NUM,
    parameter CMP_VAL = IN_WIDTH/(IN_NUM-1),
    parameter OUT_WIDTH = (IN_ARRAY_WIDTH/IN_NUM)+CMP_VAL
)(
    input   [IN_ARRAY_WIDTH-1 : 0]  D_in,
    output  [OUT_WIDTH-1 : 0]  Q_out
);
    
    genvar i,j;
    wire [IN_WIDTH-1 : 0]      in_sep  [IN_NUM-1 : 0];
    wire [IN_NUM-2 : 0]      gen         [OUT_WIDTH-1 : 0];
    generate 
        for(i=0;i<IN_NUM; i=i+1      ) begin : lp
            assign in_sep[i] = D_in[(IN_WIDTH*(i+1))-1 : IN_WIDTH*i];
        end
        for (j=0;j<IN_NUM-1;j=j+1)begin : loop1
                for(i=0;i<OUT_WIDTH; i=i+1  )begin : loop2
                    if(i>=CMP_VAL*(j+1))begin : if1
                        assign gen[i][j] = in_sep[j][i-CMP_VAL];
                    end 
                    else if( i< CMP_VAL*(j+1) && i>= (CMP_VAL*j)) begin :if2
                        assign gen[i][j] = in_sep[IN_NUM-1][i];
                    end
                    else    begin :els
                        assign gen[i][j] = in_sep[j][i];
                    end
                end// for i
            end// for j
        for(i=0;i<OUT_WIDTH; i=i+1       ) begin : lp2
            assign Q_out[i] = |  gen[i];
        end
    endgenerate
endmodule

/***********************************
*   module bin_to_one_hot 
************************************/
module bin_to_one_hot #(
    parameter BIN_WIDTH = 2,
    parameter ONE_HOT_WIDTH = 2**BIN_WIDTH
    
)(
    input   [BIN_WIDTH-1 : 0]  bin_code,
    output  [ONE_HOT_WIDTH-1 : 0] one_hot_code
);
    genvar i;
    generate 
        for(i=0; i<ONE_HOT_WIDTH; i=i+1) begin :one_hot_gen_loop
                assign one_hot_code[i] = (bin_code == i[BIN_WIDTH-1 : 0]);
        end
    endgenerate
endmodule

/***********************************
*        one_hot_to_binary
************************************/
module one_hot_to_bin #(
    parameter ONE_HOT_WIDTH = 4,
    parameter BIN_WIDTH = (ONE_HOT_WIDTH > 1) ? $clog2(ONE_HOT_WIDTH) : 1
)(
    input   [ONE_HOT_WIDTH-1 : 0] one_hot_code,
    output  [BIN_WIDTH-1 : 0]  bin_code
);
    localparam MUX_IN_WIDTH = BIN_WIDTH * ONE_HOT_WIDTH;
    wire [MUX_IN_WIDTH-1 : 0]  bin_temp ;
    genvar i;
    generate 
    if(ONE_HOT_WIDTH>1)begin :if1
        for(i=0; i<ONE_HOT_WIDTH; i=i+1) begin :mux_in_gen_loop
            assign bin_temp[(i+1)*BIN_WIDTH-1 : i*BIN_WIDTH] = i[BIN_WIDTH-1: 0];
        end
        one_hot_mux #(
            .IN_WIDTH (MUX_IN_WIDTH),
            .SEL_WIDTH (ONE_HOT_WIDTH)
        ) mux (
            .mux_in (bin_temp),
            .mux_out (bin_code),
            .sel (one_hot_code)
        );
    end else begin :els
        // assign  bin_code = one_hot_code;
        assign  bin_code = 1'b0;
    end
    endgenerate
endmodule


/****************************************
*     binary_mux
***************************************/
module binary_mux #(
    parameter IN_WIDTH = 20,
    parameter OUT_WIDTH = 5
)(
    mux_in,
    mux_out,
    sel
);
    localparam  
        IN_NUM = IN_WIDTH / OUT_WIDTH,
        SEL_WIDTH_BIN = (IN_NUM > 1) ? $clog2(IN_NUM) : 1; 
    input   [IN_WIDTH-1 : 0] mux_in;
    output  [OUT_WIDTH-1 : 0] mux_out;
    input   [SEL_WIDTH_BIN-1 : 0] sel;                 
    genvar i;
    generate 
        if(IN_NUM > 1) begin 
            wire [OUT_WIDTH-1 : 0] mux_in_2d [IN_NUM -1 : 0];
            for (i=0; i< IN_NUM; i=i+1) begin : loop
                assign mux_in_2d[i] = mux_in[((i+1)*OUT_WIDTH)-1 : i*OUT_WIDTH];   
            end
            assign mux_out = mux_in_2d[sel];        
        end else  begin 
            assign mux_out = mux_in;            
        end
    endgenerate
endmodule


module  accumulator #(
    parameter INw= 20,
    parameter OUTw=4,
    parameter NUM =5
)(
    in_all,
    sum_o         
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
        N = INw/NUM,
        SUMw = log2(NUM)+N; 
    input [INw-1 : 0] in_all;
    output[OUTw-1 : 0] sum_o;
    
    wire [N-1 : 0] in [NUM-1 : 0];
    reg [SUMw-1 : 0] sum;
    genvar i;
    generate 
    for (i=0; i<NUM; i=i+1)begin : lp
        assign in[i] = in_all[(i+1)*N-1 : i*N];
    end
    
    if(  SUMw == OUTw) begin : equal
        assign sum_o = sum;
    end else if(SUMw >  OUTw) begin : bigger
        assign sum_o = (sum[SUMw-1 : OUTw] > 0 ) ? {OUTw{1'b1}} : sum[OUTw-1 : 0] ;
    end else begin : less
        assign sum_o = {{(OUTw-SUMw){1'b0}},  sum} ;
    end
    endgenerate
    // This is supposed to be synyhesized as "sum=in[0]+in[1]+...in[Num-1]"; 
    // It works with Quartus, Verilator and Modelsim compilers  
    integer k; 
    always @(*)begin 
        sum = {SUMw{1'b0}};
        for (k=0;k<NUM;k=k+1)begin 
            sum= sum + {{(SUMw-N){1'b0}},in[k]};
        end
    end
    //In case your compiler could not synthesize or wrongly synthesizes it try this
    //assumming the maximum NUM as parameter can be 20:
    /*
    generate 
    wire [N-1 : 0] tmp [19 : 0];
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

/******************************
*    check_single_bit_assertation
*******************************/
module is_onehot0 #(
    parameter IN_WIDTH =2
)(
    input   [IN_WIDTH-1 : 0]  D_in,
    output  result
);
    function integer log2;
    input integer number; begin   
        log2=(number <=1) ? 1: 0;    
        while(2**log2<number) begin    
            log2=log2+1;    
        end        
    end   
    endfunction // log2 
    
    localparam OUT_WIDTH = log2(IN_WIDTH+1);
    wire [OUT_WIDTH-1 : 0]  sum;
    
    accumulator #(
        .INw(IN_WIDTH),
        .OUTw(OUT_WIDTH),
        .NUM(IN_WIDTH)
    ) accum (
        .in_all(D_in),
        .sum_o(sum)         
    );
    assign result = (sum <=1)? 1'b1: 1'b0;
endmodule

/**********************************
*fast_minimum_number
***********************************/
module fast_minimum_number#(
    parameter NUM_OF_INPUTS = 8,
    parameter DATA_WIDTH = 5,
    parameter IN_ARRAY_WIDTH = NUM_OF_INPUTS   * DATA_WIDTH
)(
    input  [IN_ARRAY_WIDTH-1 : 0] in_array,
    output [NUM_OF_INPUTS-1 : 0]  min_out
);

    genvar i,j;
    wire [DATA_WIDTH-1 : 0]  numbers             [NUM_OF_INPUTS-1 : 0];    
    wire [NUM_OF_INPUTS-2 : 0]  comp_array          [NUM_OF_INPUTS-1 : 0];    
    
    generate
    if(NUM_OF_INPUTS==1)begin:if1
        assign min_out = 1'b1;
    end
    else begin : els//(vc num >1)
        for(i=0; i<NUM_OF_INPUTS;  i=i+1) begin : loop_i
                assign numbers[i] = in_array  [(i+1)* DATA_WIDTH-1: i*DATA_WIDTH];
                for(j=0; j<NUM_OF_INPUTS-1;  j=j+1) begin : loop_j
                            if(i>j) begin :if1 assign comp_array [i][j] = ~ comp_array [j][i-1]; end
                            else   begin :els     assign comp_array [i]   [j] = numbers[i]<= numbers[j+1]; end
                end//for j
                assign min_out[i]= & comp_array[i];
        end//for i
    end//else
    endgenerate
endmodule



module start_delay_gen #(
    parameter NC = 64 //number of cores
)(
    clk,
    reset,
    start_i,
    start_o
);
    input reset,clk,start_i;
    output [NC-1 : 0] start_o;
    reg start_i_reg;
    wire start;
    wire cnt_increase;
    reg [NC-1 : 0] start_o_next;
    reg [NC-1 : 0] start_o_reg;
    
    assign start= start_i_reg|start_i;
    generate 
    if(NC > 2) begin :l1
        always @(*)begin 
            if(NC[0]==1'b0)begin // odd
                start_o_next={start_o[NC-3: 0],start_o[NC-2],start};
            end else begin //even
                start_o_next={start_o[NC-3: 0],start_o[NC-1],start};
            end    
        end
    end else begin :l2
        always @(*) start_o_next = {NC{start}}; 
    end
    endgenerate
    
    reg [2: 0] counter;
    assign cnt_increase=(counter==3'd0);
    always @ (`pronoc_clk_reset_edge )begin 
        if(`pronoc_reset)  begin             
            start_o_reg <= {NC{1'b0}};
            start_i_reg <= 1'b0;
            counter <= 3'd0;
        end else begin 
            counter <= counter+3'd1;
            start_i_reg <= start_i;
            if(cnt_increase | start) start_o_reg <= start_o_next;
            
        end//reset
    end //always
    assign start_o=(cnt_increase | start)? start_o_reg : {NC{1'b0}};
endmodule
`endif