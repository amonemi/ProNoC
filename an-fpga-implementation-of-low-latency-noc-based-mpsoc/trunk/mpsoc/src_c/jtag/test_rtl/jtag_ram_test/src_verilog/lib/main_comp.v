 `timescale  1ns/1ps


/**********************************************************************
**	File:  main_comp.v
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
**	This file contains several general RTL modules such as 
**	different types of multiplexors, converters and counters ...
**
**************************************************************/







/*********************************



    multiplexer

    
    
********************************/

module one_hot_mux #(
        parameter   IN_WIDTH      = 20,
        parameter   SEL_WIDTH =   5, 
        parameter   OUT_WIDTH = IN_WIDTH/SEL_WIDTH

    )
    (
        input [IN_WIDTH-1       :0] mux_in,
        output[OUT_WIDTH-1  :0] mux_out,
        input[SEL_WIDTH-1   :0] sel

    );

    wire [IN_WIDTH-1    :0] mask;
    wire [IN_WIDTH-1    :0] masked_mux_in;
    wire [SEL_WIDTH-1:0]    mux_out_gen [OUT_WIDTH-1:0]; 
    
    genvar i,j;
    
    //first selector masking
    generate    // first_mask = {sel[0],sel[0],sel[0],....,sel[n],sel[n],sel[n]}
        for(i=0; i<SEL_WIDTH; i=i+1) begin : mask_loop
            assign mask[(i+1)*OUT_WIDTH-1 : (i)*OUT_WIDTH]  =   {OUT_WIDTH{sel[i]} };
        end
        
        assign masked_mux_in    = mux_in & mask;
        
        for(i=0; i<OUT_WIDTH; i=i+1) begin : lp1
            for(j=0; j<SEL_WIDTH; j=j+1) begin : lp2
                assign mux_out_gen [i][j]   =   masked_mux_in[i+OUT_WIDTH*j];
            end
            assign mux_out[i] = | mux_out_gen [i];
        end
    endgenerate
    
endmodule





    
/******************************

    One hot demultiplexer

****************************/   
    

module one_hot_demux    #(
        parameter IN_WIDTH=5,
        parameter SEL_WIDTH=4,
        parameter OUT_WIDTH=IN_WIDTH*SEL_WIDTH
    )
    (
        input   [SEL_WIDTH-1        :   0] demux_sel,//selectore
        input   [IN_WIDTH-1         :   0] demux_in,//repeated
        output  [OUT_WIDTH-1        :   0]  demux_out
    );

    genvar i,j;
    generate 
    for(i=0;i<SEL_WIDTH;i=i+1)begin :loop1
        for(j=0;j<IN_WIDTH;j=j+1)begin :loop2
                assign demux_out[i*IN_WIDTH+j] =     demux_sel[i]   &   demux_in[j];
        end//for j
    end//for i
    endgenerate

    

endmodule

/**************************


    custom_or

    
***************************/


module custom_or #(
    parameter IN_NUM        =   4,
    parameter OUT_WIDTH =   5
)(
    or_in,
    or_out
);
    
    localparam IN_WIDTH  = IN_NUM*OUT_WIDTH;
    
    input [IN_WIDTH-1       :   0]  or_in;
    output[OUT_WIDTH-1      :   0]  or_out;

    wire        [IN_NUM-1       :   0] in_sep   [OUT_WIDTH-1        :   0];
    genvar i,j;
    generate
    for (i=0;i<OUT_WIDTH;i=i+1) begin: sep_loop
        for (j=0;j<IN_NUM;j=j+1) begin: sep_loop
            assign in_sep[i][j]= or_in [j*OUT_WIDTH+i];
        end
        assign or_out[i]= |in_sep[i];
    end
    endgenerate
    
    
endmodule


/*****************************************

sum the output of all ports except the output of  port itself


****************************************/


module outport_sum #(
    parameter IN_ARRAY_WIDTH =10,
    parameter IN_NUM     =5,
    parameter IN_WIDTH  =   IN_ARRAY_WIDTH/IN_NUM,
    parameter CMP_VAL   =   IN_WIDTH/(IN_NUM-1),
    parameter OUT_WIDTH = (IN_ARRAY_WIDTH/IN_NUM)+CMP_VAL
    
    )
    (
    input   [IN_ARRAY_WIDTH-1       :   0]  in,
    output  [OUT_WIDTH-1                :   0]  out
);
    
    genvar i,j;
    wire [IN_WIDTH-1        :   0]      in_sep  [IN_NUM-1       :   0];
    wire [IN_NUM-2          :   0]      gen         [OUT_WIDTH-1    :   0];
    generate 
        for(i=0;i<IN_NUM; i=i+1      ) begin : lp
            assign in_sep[i]  = in[(IN_WIDTH*(i+1))-1   : IN_WIDTH*i];
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
            assign out[i]               = |  gen[i];
        end
    endgenerate
endmodule

/***********************************

        module bin_to_one_hot 
        

************************************/


module bin_to_one_hot #(
    parameter BIN_WIDTH     =   2,
    parameter ONE_HOT_WIDTH =   2**BIN_WIDTH
    
)
(
    input   [BIN_WIDTH-1            :   0]  bin_code,
    output  [ONE_HOT_WIDTH-1        :   0] one_hot_code
 );

    genvar i;
    generate 
        for(i=0; i<ONE_HOT_WIDTH; i=i+1) begin :one_hot_gen_loop
                assign one_hot_code[i] = (bin_code == i[BIN_WIDTH-1         :   0]);
        end
    endgenerate
 
endmodule

/***********************************

        one_hot_to_binary

************************************/



module one_hot_to_bin #(
    parameter ONE_HOT_WIDTH =   4,
    parameter BIN_WIDTH     =  (ONE_HOT_WIDTH>1)? log2(ONE_HOT_WIDTH):1
)
(
    input   [ONE_HOT_WIDTH-1        :   0] one_hot_code,
    output  [BIN_WIDTH-1            :   0]  bin_code

);

  
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 

localparam MUX_IN_WIDTH =   BIN_WIDTH* ONE_HOT_WIDTH;

wire [MUX_IN_WIDTH-1        :   0]  bin_temp ;

genvar i;
generate 
    if(ONE_HOT_WIDTH>1)begin :if1
        for(i=0; i<ONE_HOT_WIDTH; i=i+1) begin :mux_in_gen_loop
            assign bin_temp[(i+1)*BIN_WIDTH-1 : i*BIN_WIDTH] =  i[BIN_WIDTH-1:0];
        end


        one_hot_mux #(
            .IN_WIDTH   (MUX_IN_WIDTH),
            .SEL_WIDTH  (ONE_HOT_WIDTH)
            
        )
        one_hot_to_bcd_mux
        (
            .mux_in     (bin_temp),
            .mux_out        (bin_code),
            .sel            (one_hot_code)
    
        );
     end else begin :els
        assign  bin_code = one_hot_code;
     
     end

endgenerate

endmodule



/****************************************

            binary_mux

***************************************/

module binary_mux #(
        parameter   IN_WIDTH         =   20,
        parameter   OUT_WIDTH       =   5
    )
    (
        mux_in,
        mux_out,
        sel

    );
    
  
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 

     localparam  IN_NUM          =   IN_WIDTH/OUT_WIDTH,
                 SEL_WIDTH_BIN   = (IN_NUM>1)?  log2(IN_NUM): 1; 
                 
                 
    input   [IN_WIDTH-1         :0] mux_in;
    output  [OUT_WIDTH-1        :0] mux_out;
    input   [SEL_WIDTH_BIN-1    :0] sel;                 
    genvar i;
     
    
	generate 
		if(IN_NUM>1) begin :if1
			wire [OUT_WIDTH-1       :0] mux_in_2d [IN_NUM -1    :0];
			for (i=0; i< IN_NUM; i=i+1) begin : loop
				assign mux_in_2d[i] =mux_in[((i+1)*OUT_WIDTH)-1 :   i*OUT_WIDTH];   
			end
			assign mux_out = mux_in_2d[sel];		
		end else  begin :els
			assign mux_out = mux_in;			
		end
	endgenerate
    
endmodule


/******************************

    set_bits_counter 

*******************************/


module set_bits_counter #(
    parameter IN_WIDTH =120,
    parameter OUT_WIDTH = log2(IN_WIDTH+1)
    )
    (
    input   [IN_WIDTH-1         :   0]  in,
    output  [OUT_WIDTH-1        :   0]  out
    
);
  
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 

    
    wire    [IN_WIDTH-2     :   0]  addrin2;
    wire    [OUT_WIDTH-1    :   0]  addrout [IN_WIDTH-2         :   0];
    wire    [OUT_WIDTH-1    :   0]  addrin1 [IN_WIDTH-1         :   0];
    
    
    assign out          = addrin1 [IN_WIDTH-1];
    
    genvar i;
    //always @(*)begin
    assign  addrin1[0] = {{(OUT_WIDTH-1){1'b0}},in[0]};
    generate        
        for (i=0; i<IN_WIDTH-1; i=i+1) begin : loop
                assign  addrin1[i+1]  = addrout[i];
                assign  addrin2[i]    = in[i+1];
                assign  addrout[i]    = addrin1[i] + addrin2 [i];
        end
    endgenerate

endmodule






/******************************

    check_single_bit_assertation

*******************************/


module check_single_bit_assertation #(
    parameter IN_WIDTH =2
    
    )
    (
    input   [IN_WIDTH-1         :   0]  in,
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
    
    wire [OUT_WIDTH-1   :   0]  sum;
    
    parallel_counter #(
        .IN_WIDTH (IN_WIDTH)
    )counter
    (
        .in(in),
        .out(sum)
    );

    assign result = (sum <=1)? 1'b1: 1'b0;
    
    
endmodule

/**********************************

fast_minimum_number

***********************************/


module fast_minimum_number#(
    parameter NUM_OF_INPUTS     =   8,
    parameter DATA_WIDTH            =   5,
    parameter IN_ARRAY_WIDTH    =   NUM_OF_INPUTS   * DATA_WIDTH
)
(
    input  [IN_ARRAY_WIDTH-1            :   0] in_array,
    output [NUM_OF_INPUTS-1             :   0]  min_out
);

    genvar i,j;
    wire [DATA_WIDTH-1                  :   0]  numbers             [NUM_OF_INPUTS-1            :0];    
    wire [NUM_OF_INPUTS-2               :   0]  comp_array          [NUM_OF_INPUTS-1            :0];    
        
    generate
    if(NUM_OF_INPUTS==1)begin:if1
        assign min_out = 1'b1;
    end
    else begin : els//(vc num >1)
        for(i=0; i<NUM_OF_INPUTS;  i=i+1) begin : loop_i
                assign numbers[i]   = in_array  [(i+1)* DATA_WIDTH-1: i*DATA_WIDTH];
                for(j=0; j<NUM_OF_INPUTS-1;  j=j+1) begin : loop_j
                            if(i>j) begin :if1 assign comp_array [i][j] = ~ comp_array [j][i-1]; end
                            else   begin :els     assign comp_array [i]   [j] = numbers[i]<= numbers[j+1]; end
                end//for j
                assign min_out[i]=  & comp_array[i];
        end//for i
    end//else
    endgenerate
    
endmodule


/********************************************

        Carry-based reduction parallel counter


********************************************/
module parallel_counter  #(
    parameter IN_WIDTH =120 // max 127
)
(
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
    
  localparam OUT_WIDTH = log2(IN_WIDTH+1);
  localparam PCIw      = (IN_WIDTH < 8   )? 7    :
                         (IN_WIDTH < 16  )? 15   :
                         (IN_WIDTH < 31  )? 31   :
                         (IN_WIDTH < 36  )? 63   :   127;
                         
                         
   localparam PCOw      = (IN_WIDTH < 8  )? 3   :
                         (IN_WIDTH < 16  )? 4   :
                         (IN_WIDTH < 31  )? 5   :
                         (IN_WIDTH < 36  )? 6   :   7;                         
  
input   [IN_WIDTH-1         :   0]  in;
output  [OUT_WIDTH-1        :   0]  out;
     
wire [PCIw-1    :   0]  pc_in;
wire [PCOw-1    :   0]  pc_out;

generate 
    if(PCIw > IN_WIDTH ) begin :w1
        assign   pc_in = {{(PCIw-IN_WIDTH){1'b0}},in};
    end else begin:els
         assign   pc_in=in;
    end // if 
    
    if(PCIw == 7) begin :w7
       
        PC_7_3   pc (
            .in(pc_in),
            .out(pc_out)
        );
    
    end else if(PCIw == 15) begin :w15
          PC_15_4   pc (
            .in(pc_in),
            .out(pc_out)
           );
    
    end else if(PCIw == 31) begin :w31
        PC_31_5   pc (
            .in(pc_in),
            .out(pc_out)
        );   
    end else if(PCIw == 63) begin :w63
         PC_63_6   pc (
            .in(pc_in),
            .out(pc_out)
        );   
    
    end else  begin :w127
         PC_127_7 pc (
            .in(pc_in),
            .out(pc_out)
        );   
    end
    
 endgenerate
 
 assign out = pc_out[OUT_WIDTH-1    :   0];
 
endmodule



//carry-sum generation blocks
module CS_GEN (
    in,
    abc,
    s
);
    input   [6  :   0] in;
    output  s;
    output  [2  :   0] abc;
    
    wire      a,b,c,s;
    wire    [3  :   0] in1;
    wire    [2  :   0] in2;
    wire    [2  :   0] j1;
    wire    [1  :   0] j2;
    
    assign {in2,in1} =  in;
    assign j1= in1[3]+in1[2]+in1[1]+in1[0];
    assign j2= in2[2]+in2[1]+in2[0];
    
    //s is asserted when both in1 and in2 have odd number of ones.
    assign s    = j1[0] ^ j2[0];
    // a is asserted when there are at least two ones in in1 (i.e., j1 >= 2);
    assign  a   =   (j1 >   3'd1);
    
    //b is asserted when there are at least two ones in in2 (i.e., j2 >= 2);
    assign  b   =   (j2 >   2'd1);
    
    // C is asserted when when j1 equals 4 or when  s is asserted
    assign c    =   (j1==4) | (j1[0] & j2[0]);

    assign abc = {a,b,c};
endmodule

/*************************
 
 (7,3) parallel counter
 
*************************/

module PC_7_3 (
    in,
    out

);
    input   [6    : 0]  in;
    output  [2    : 0]  out;
    
    wire    [2    : 0] abc;
   
    CS_GEN cs(
        .in(in),
        .abc(abc),
        .s(out[0])
    );
   
    assign out[2:1] = abc[2]+abc[1]+abc[0];  
    
  


endmodule

/*************************

    (15,4) parallel counter
    
*************************/

module PC_15_4 (
    in,
    out

);
    input   [14   : 0]  in;
    output  [3    : 0]  out;
    
    wire    [2:0]   abc0,abc1;
    wire            s0,s1,b2;
   
    CS_GEN cs0(
        .in     (in  [6  :   0]),
        .abc    (abc0),
        .s      (s0)
    );
    
     CS_GEN cs1(
        .in     (in  [13  :   7]),
        .abc    (abc1),
        .s      (s1)
    );
    
    assign {b2,out[0]}  =in  [14] + s0 +s1;
    
    PC_7_3 pc_sub(
        .in({abc0,abc1,b2}),
        .out(out[3:1])
    );  
    
  


endmodule


// (31,5) parallel counter
module PC_31_5 (
    in,
    out

);
    localparam CS_NUM   =   5;
    
    input   [30         : 0]  in;
    output  [4          : 0]  out;
    
   
    wire    [CS_NUM-1   : 0]   s;
    wire    [(CS_NUM*7)-1   :   0]  cs_in;
    wire    [14         :   0]  pc_15_in;
    
    assign cs_in ={s[3:0] ,in };
    
    genvar i;
    generate 
    for (i=0;i<CS_NUM;i=i+1) begin: lp    
        CS_GEN cs(
            .in     (cs_in     [(i+1)*7-1  :  i*7]),
            .abc    (pc_15_in  [(i+1)*3-1  :  i*3]),
            .s      (s      [i])
        );
        
    end//for
    endgenerate
    
    PC_15_4 pc_15(
        .in    (pc_15_in ),
        .out   (out[4:1])
    );
    
    assign out[0] = s[4];
    
 endmodule

/*************************
 
 (63,6) parallel counter
 
**************************/

module PC_63_6 (
    in,
    out

);
    localparam CS_NUM   =   10;
    
    input   [62         : 0]  in;
    output  [5          : 0]  out;
    
   
    wire    [CS_NUM-1   : 0]   s;
    wire    [(CS_NUM*7)-1   :   0]  cs_in;
    wire    [30         : 0]  pc_31_in;
    
    assign cs_in ={s[7:0] ,in };
    
    genvar i;
    generate 
    for (i=0;i<CS_NUM;i=i+1) begin:lp    
        CS_GEN cs(
            .in     (cs_in     [(i+1)*7-1  :  i*7]),
            .abc    (pc_31_in  [(i+1)*3-1  :  i*3]),
            .s      (s      [i])
        );
        
    end//for
    endgenerate
    
    assign {pc_31_in[30],out[0]}    =   s[7]+s[8]+s[9];
         
    PC_31_5 pc_31(
        .in(pc_31_in ),
        .out(out[5:1])
    );
 endmodule

/*************************

 (127,7) parallel counter

*************************/

module PC_127_7 (
    in,
    out

);
    localparam CS_NUM   =   21;
    
    input   [126        : 0]  in;
    output  [6          : 0]  out;
    
   
    wire    [CS_NUM-1       : 0]   s;
    wire    [(CS_NUM*7)-1   : 0]  cs_in;//147
    wire    [62             : 0]  pc_63_in;
    
    assign cs_in ={s[19:0] ,in };
    
    genvar i;
    generate 
    for (i=0;i<CS_NUM;i=i+1) begin :lp   
        CS_GEN cs(
            .in     (cs_in     [(i+1)*7-1  :  i*7]),
            .abc    (pc_63_in  [(i+1)*3-1  :  i*3]),
            .s      (s      [i])
        );
        
    end//for
    endgenerate
    
    assign {out[0]}    =   s[20];
         
    PC_63_6 pc63(
        .in(pc_63_in),
        .out(out[6:1])
    );
   
    
 endmodule





