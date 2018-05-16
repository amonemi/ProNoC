 `timescale     1ns/1ps
/**********************************************************************
**	File: arbiter.v
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
**
**	Description: 
**	This file contains several Fixed prority and round robin 
**	arbiters 
**
******************************************************************************/ 


/*****************************************
*        
* general round robin arbiter
* 
*
******************************************/

module arbiter #(
    parameter    ARBITER_WIDTH    =8
        
)
(    
   clk, 
   reset, 
   request, 
   grant,
   any_grant
);

    
    input    [ARBITER_WIDTH-1             :    0]    request;
    output    [ARBITER_WIDTH-1            :    0]    grant;
    output                                        any_grant;
    input                                        clk;
    input                                        reset;



    generate 
    if(ARBITER_WIDTH==1)  begin: w1
        assign grant= request;
        assign any_grant =request;
    end else if(ARBITER_WIDTH<=4) begin: w4
        //my own arbiter 
        my_one_hot_arbiter #(
            .ARBITER_WIDTH    (ARBITER_WIDTH)
        )
        one_hot_arb
        (    
            .clk            (clk), 
            .reset         (reset), 
            .request        (request), 
            .grant        (grant),
            .any_grant    (any_grant)
        );
    
    end else begin : wb4
        
        thermo_arbiter #(
            .ARBITER_WIDTH    (ARBITER_WIDTH)
        )
        one_hot_arb
        (    
            .clk            (clk), 
            .reset         (reset), 
            .request        (request), 
            .grant        (grant),
            .any_grant    (any_grant)
        );
    end
    endgenerate
endmodule

/*****************************************
*
*        arbiter_priority_en
* RRA with external priority enable signal
*
******************************************/

module arbiter_priority_en #(
        parameter    ARBITER_WIDTH    =8
        
)
(    
   clk, 
   reset, 
   request, 
   grant,
   any_grant,
   priority_en
);

  


    input        [ARBITER_WIDTH-1             :    0]    request;
    output    [ARBITER_WIDTH-1            :    0]    grant;
    output                                            any_grant;
    input                                                clk;
    input                                                reset;
    input                                              priority_en;
    
    
    generate 
    if(ARBITER_WIDTH==1)  begin: w1
        assign grant= request;
        assign any_grant =request;
    end else if(ARBITER_WIDTH<=4) begin: w4
        //my own arbiter 
        my_one_hot_arbiter_priority_en #(
            .ARBITER_WIDTH    (ARBITER_WIDTH)
        )
        one_hot_arb
        (    
            .clk            (clk), 
            .reset         (reset), 
            .request        (request), 
            .grant        (grant),
            .any_grant    (any_grant),
            .priority_en (priority_en)
            
        );
    
    end else begin :wb4
        
        thermo_arbiter_priority_en #(
            .ARBITER_WIDTH    (ARBITER_WIDTH)
        )
        one_hot_arb
        (    
            .clk            (clk), 
            .reset         (reset), 
            .request        (request), 
            .grant        (grant),
            .any_grant    (any_grant),
            .priority_en (priority_en)
        );
    end
endgenerate
endmodule



/******************************************************
*	my_one_hot_arbiter
* RRA with binary-coded priority register. Binary-coded 
* Priority results in less area cost and CPD for arbire 
* width of 4 and smaller only. 
*
******************************************************/
      
    

module my_one_hot_arbiter #(
    parameter ARBITER_WIDTH    =4
    
    
)
(
    input        [ARBITER_WIDTH-1             :    0]    request,
    output    [ARBITER_WIDTH-1            :    0]    grant,
    output                                            any_grant,
    input                                                clk,
    input                                                reset
);
   
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
    
    localparam ARBITER_BIN_WIDTH= log2(ARBITER_WIDTH);
    reg     [ARBITER_BIN_WIDTH-1        :    0]     low_pr;
    wire     [ARBITER_BIN_WIDTH-1        :    0]     grant_bcd;
    
    one_hot_to_bin #(
        .ONE_HOT_WIDTH    (ARBITER_WIDTH)
    )conv
    (
    .one_hot_code(grant),
    .bin_code(grant_bcd)

    );
    
    
    
    always@(posedge clk or posedge reset) begin
        if(reset) begin
            low_pr    <=    {ARBITER_BIN_WIDTH{1'b0}};
        end else begin
            if(any_grant) low_pr <= grant_bcd;
        end
    end
    

    assign any_grant = | request;

    generate 
        if(ARBITER_WIDTH    ==2) begin: w2        arbiter_2_one_hot arb( .in(request) , .out(grant), .low_pr(low_pr)); end
        if(ARBITER_WIDTH    ==3) begin: w3        arbiter_3_one_hot arb( .in(request) , .out(grant), .low_pr(low_pr)); end
        if(ARBITER_WIDTH    ==4) begin: w4        arbiter_4_one_hot arb( .in(request) , .out(grant), .low_pr(low_pr)); end
    endgenerate

endmodule


module arbiter_2_one_hot(
     input      [1             :    0]    in,
     output    reg[1                :    0]    out,
     input                                low_pr
);
always @(*) begin
     out=2'b00;
      case(low_pr)
         1'd0:
             if(in[1])                 out=2'b10;
             else if(in[0])         out=2'b01;
         1'd1:
             if(in[0])                 out=2'b01;
             else if(in[1])         out=2'b10;
          default: out=2'b00;
     endcase 
  end
 endmodule 




module arbiter_3_one_hot(
     input      [2             :    0]    in,
     output    reg[2                :    0]    out,
     input        [1                :    0]    low_pr
);
always @(*) begin
  out=3'b000;
      case(low_pr)
         2'd0:
             if(in[1])                 out=3'b010;
             else if(in[2])         out=3'b100;
             else if(in[0])         out=3'b001;
         2'd1:
             if(in[2])                 out=3'b100;
             else if(in[0])         out=3'b001;
             else if(in[1])         out=3'b010;
         2'd2:
             if(in[0])                 out=3'b001;
             else if(in[1])         out=3'b010;
             else if(in[2])         out=3'b100;
         default: out=3'b000;
     endcase 
  end
 endmodule 


 module arbiter_4_one_hot(
     input      [3             :    0]    in,
     output    reg[3                :    0]    out,
     input        [1                :    0]    low_pr
);
always @(*) begin
  out=4'b0000;
      case(low_pr)
         2'd0:
             if(in[1])                 out=4'b0010;
             else if(in[2])         out=4'b0100;
             else if(in[3])         out=4'b1000;
             else if(in[0])         out=4'b0001;
         2'd1:
             if(in[2])                 out=4'b0100;
             else if(in[3])         out=4'b1000;
             else if(in[0])         out=4'b0001;
             else if(in[1])         out=4'b0010;
         2'd2:
             if(in[3])                 out=4'b1000;
             else if(in[0])         out=4'b0001;
             else if(in[1])         out=4'b0010;
             else if(in[2])         out=4'b0100;
         2'd3:
             if(in[0])                 out=4'b0001;
             else if(in[1])         out=4'b0010;
             else if(in[2])         out=4'b0100;
             else if(in[3])         out=4'b1000;
         default: out=4'b0000;
     endcase 
  end
 endmodule 


/******************************************************
*	my_one_hot_arbiter_priority_en
* 
******************************************************/



module my_one_hot_arbiter_priority_en #(
    parameter ARBITER_WIDTH    =4
    
    
)
(
    input        [ARBITER_WIDTH-1             :    0]    request,
    output    [ARBITER_WIDTH-1            :    0]    grant,
    output                                            any_grant,
    input                                                clk,
    input                                                reset,
    input                                                priority_en
);
   
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
    
    localparam ARBITER_BIN_WIDTH= log2(ARBITER_WIDTH);
    reg     [ARBITER_BIN_WIDTH-1        :    0]     low_pr;
    wire     [ARBITER_BIN_WIDTH-1        :    0]     grant_bcd;
    
    one_hot_to_bin #(
        .ONE_HOT_WIDTH    (ARBITER_WIDTH)
    )conv 
    (
        .one_hot_code(grant),
        .bin_code(grant_bcd)
    );
    
    always@(posedge clk or posedge reset) begin
        if(reset) begin
            low_pr    <=    {ARBITER_BIN_WIDTH{1'b0}};
        end else begin
            if(priority_en) low_pr <= grant_bcd;
        end
    end
    

    assign any_grant = | request;

    generate 
        if(ARBITER_WIDTH    ==2) begin :w2        arbiter_2_one_hot arb( .in(request) , .out(grant), .low_pr(low_pr)); end
        if(ARBITER_WIDTH    ==3) begin :w3        arbiter_3_one_hot arb( .in(request) , .out(grant), .low_pr(low_pr)); end
        if(ARBITER_WIDTH    ==4) begin :w4        arbiter_4_one_hot arb( .in(request) , .out(grant), .low_pr(low_pr)); end
    endgenerate

endmodule   



/*******************
*
*    thermo_arbiter RRA
*
********************/

module thermo_gen #(
    parameter WIDTH=16


)(
    input  [WIDTH-1    :    0]in,
    output [WIDTH-1    :    0]out
);
    genvar i;
    generate
    for(i=0;i<WIDTH;i=i+1)begin :lp
        assign out[i]= | in[i    :0];    
    end
    endgenerate

endmodule
 
 
 
 
module thermo_arbiter #(
 parameter    ARBITER_WIDTH    =4
        
)
(    
   clk, 
   reset, 
   request, 
   grant,
   any_grant
);

        

    
    input        [ARBITER_WIDTH-1             :    0]    request;
    output    [ARBITER_WIDTH-1            :    0]    grant;
    output                                            any_grant;
    input                                                reset,clk;
    
    
    wire        [ARBITER_WIDTH-1             :    0]    termo1,termo2,mux_out,masked_request,edge_mask;
    reg        [ARBITER_WIDTH-1             :    0]    pr;


    thermo_gen #(
        .WIDTH(ARBITER_WIDTH)
    ) tm1
    (
        .in(request),
        .out(termo1)
    );




    thermo_gen #(
        .WIDTH(ARBITER_WIDTH)
    ) tm2
    (
        .in(masked_request),
        .out(termo2)
    );

    
assign mux_out=(termo2[ARBITER_WIDTH-1])? termo2 : termo1;
assign masked_request= request & pr;
assign any_grant=termo1[ARBITER_WIDTH-1];

always @(posedge clk or posedge reset)begin 
    if(reset) pr<= {ARBITER_WIDTH{1'b1}};
    else begin 
        if(any_grant) pr<= edge_mask;
    end

end

assign edge_mask= {mux_out[ARBITER_WIDTH-2:0],1'b0};
assign grant= mux_out ^ edge_mask;



endmodule
    
    

 
 
module thermo_arbiter_priority_en #(
 parameter    ARBITER_WIDTH    =4
        
)
(    
   clk, 
   reset, 
   request, 
   grant,
   any_grant,
   priority_en
);

        

    
    input        [ARBITER_WIDTH-1             :    0]    request;
    output    [ARBITER_WIDTH-1            :    0]    grant;
    output                                            any_grant;
    input                                                reset,clk;
    input priority_en;
    
    wire        [ARBITER_WIDTH-1             :    0]    termo1,termo2,mux_out,masked_request,edge_mask;
    reg        [ARBITER_WIDTH-1             :    0]    pr;


    thermo_gen #(
        .WIDTH(ARBITER_WIDTH)
    ) tm1
    (
        .in(request),
        .out(termo1)
    );




    thermo_gen #(
        .WIDTH(ARBITER_WIDTH)
    ) tm2
    (
        .in(masked_request),
        .out(termo2)
    );

    
assign mux_out=(termo2[ARBITER_WIDTH-1])? termo2 : termo1;
assign masked_request= request & pr;
assign any_grant=termo1[ARBITER_WIDTH-1];

always @(posedge clk or posedge reset)begin 
    if(reset) pr<= {ARBITER_WIDTH{1'b1}};
    else begin 
        if(priority_en) pr<= edge_mask;
    end

end

assign edge_mask= {mux_out[ARBITER_WIDTH-2:0],1'b0};
assign grant= mux_out ^ edge_mask;



endmodule
    






 
module thermo_arbiter_ext_priority #(
 parameter    ARBITER_WIDTH    =4
        
)
(    
   
   request, 
   grant,
   any_grant,
   priority_in
  
);

        

    
    input        [ARBITER_WIDTH-1             :    0]    request;
    output    [ARBITER_WIDTH-1            :    0]    grant;
    output                                            any_grant;
    input   [ARBITER_WIDTH-1            :   0]  priority_in;

    wire        [ARBITER_WIDTH-1             :    0]    termo1,termo2,mux_out,masked_request,edge_mask;
    wire        [ARBITER_WIDTH-1             :    0]    pr;


    thermo_gen #(
        .WIDTH(ARBITER_WIDTH)
    ) tm1
    (
        .in(request),
        .out(termo1)
    );




    thermo_gen #(
        .WIDTH(ARBITER_WIDTH)
    ) tm2
    (
        .in(masked_request),
        .out(termo2)
    );


    thermo_gen #(
        .WIDTH(ARBITER_WIDTH)
    ) tm3
    (
        .in(priority_in),
        .out(pr)
    );

    
assign mux_out=(termo2[ARBITER_WIDTH-1])? termo2 : termo1;
assign masked_request= request & pr;
assign any_grant=termo1[ARBITER_WIDTH-1];


assign edge_mask= {mux_out[ARBITER_WIDTH-2:0],1'b0};
assign grant= mux_out ^ edge_mask;



endmodule
    


/********************************
*    
*   Tree arbiter
* 
*******************************/

module tree_arbiter #(
        parameter    GROUP_NUM        =4,
        parameter    ARBITER_WIDTH    =16
)
(    
   clk, 
   reset, 
   request, 
   grant,
   any_grant
);

 
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 

  localparam N = ARBITER_WIDTH;
  localparam S = log2(ARBITER_WIDTH); // ceil of log_2 of N - put manually
  

  // I/O interface
  input           clk;
  input           reset;
  input  [N-1:0]  request;
  output [N-1:0]  grant;
  output          any_grant;


    localparam GROUP_WIDTH    =    ARBITER_WIDTH/GROUP_NUM;
  
  wire [GROUP_WIDTH-1        :    0]    group_req    [GROUP_NUM-1        :    0];
  wire [GROUP_WIDTH-1        :    0]    group_grant [GROUP_NUM-1        :    0];
  wire [GROUP_WIDTH-1        :    0]    grant_masked[GROUP_NUM-1        :    0];
  
  wire [GROUP_NUM-1            :    0] any_group_member_req;
  wire [GROUP_NUM-1            :    0] any_group_member_grant;
 
    
    genvar i;
    generate
    for (i=0;i<GROUP_NUM;i=i+1) begin :group_lp
        
        //seprate inputs in group
        assign group_req[i]    =    request[(i+1)*GROUP_WIDTH-1        :    i*GROUP_WIDTH];
        
        //check if any member of qrup has request
        assign any_group_member_req[i]    =    | group_req[i];
        
        //arbiterate one request from each group
        arbiter #(
            .ARBITER_WIDTH    (GROUP_WIDTH)
        )group_member_arbiter
        (    
            .clk            (clk), 
            .reset        (reset), 
            .request        (group_req[i]), 
            .grant        (group_grant[i]),
            .any_grant    ()
        );
        
    // mask the non selected groups        
        assign grant_masked [i] = (any_group_member_grant[i])?    group_grant[i]: {GROUP_WIDTH{1'b0}};
    
    //assemble the grants
        assign grant [(i+1)*GROUP_WIDTH-1        :    i*GROUP_WIDTH] = grant_masked [i];
    
    
    end
    endgenerate
    
    //select one group which has atleast one active request
    
    //arbiterate one request from each group
        arbiter #(
            .ARBITER_WIDTH    (GROUP_NUM)
        )second_arbiter
        (    
            .clk        (clk), 
            .reset        (reset), 
            .request    (any_group_member_req), 
            .grant        (any_group_member_grant),
            .any_grant    (any_grant)
        );
                
    
 
 endmodule 
 



 
 
/*******************************

    my_one_hot_arbiter_ext_priority

*******************************/

module my_one_hot_arbiter_ext_priority #(
    parameter ARBITER_WIDTH =4
    
    
)
(
    input   [ARBITER_WIDTH-1            :   0]  request,
    input   [ARBITER_WIDTH-1            :   0]  priority_in,
    output  [ARBITER_WIDTH-1            :   0]  grant,
    output                                      any_grant
);
 
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 

    localparam ARBITER_BIN_WIDTH= log2(ARBITER_WIDTH);
    wire    [ARBITER_BIN_WIDTH-1        :   0]  low_pr;
      
   
    wire [ARBITER_WIDTH-1            :   0] low_pr_one_hot = {priority_in[0],priority_in[ARBITER_BIN_WIDTH-1:1]};
    
    one_hot_to_bin #(
        .ONE_HOT_WIDTH    (ARBITER_WIDTH)
    )conv 
    (
        .one_hot_code(low_pr_one_hot),
        .bin_code(low_pr)
    );
      

    assign any_grant = | request;

    generate 
        if(ARBITER_WIDTH    ==2) begin: w2       arbiter_2_one_hot arb( .in(request) , .out(grant), .low_pr(low_pr)); end
        if(ARBITER_WIDTH    ==3) begin: w3       arbiter_3_one_hot arb( .in(request) , .out(grant), .low_pr(low_pr)); end
        if(ARBITER_WIDTH    ==4) begin: w4       arbiter_4_one_hot arb( .in(request) , .out(grant), .low_pr(low_pr)); end
    endgenerate

endmodule


/*********************************
*
*       arbiter_ext_priority
*
**********************************/


 module arbiter_ext_priority  #(
        parameter   ARBITER_WIDTH   =8
        
)
(   
  
   request, 
   grant,
   priority_in,
   any_grant
);

    
    input   [ARBITER_WIDTH-1            :   0]  request;
    input   [ARBITER_WIDTH-1            :   0]  priority_in;
    output  [ARBITER_WIDTH-1            :   0]  grant;
    output                                      any_grant;
 
   /*
    generate 
  
    if(ARBITER_WIDTH<=4) begin :ws4
        //my own arbiter 
        my_one_hot_arbiter_ext_priority #(
            .ARBITER_WIDTH  (ARBITER_WIDTH)
        )
        one_hot_arb
        (   
           
            .request    (request),
            .priority_in(priority_in), 
            .grant      (grant),
            .any_grant  (any_grant)
        );
    
    end else begin :wb4
    */
        
        thermo_arbiter_ext_priority #(
            .ARBITER_WIDTH  (ARBITER_WIDTH)
        )
        one_hot_arb
        (   
            
            .request    (request), 
            .priority_in(priority_in), 
            .grant      (grant),
            .any_grant   (any_grant)
        );
   // end
   // endgenerate
 
 
 
 
endmodule 
 






    

 /*
 module fixed_priority_arbiter #(
     parameter   ARBITER_WIDTH   =8,
     parameter   HIGH_PRORITY_BIT = "HSB"
 )
 (   
  
   request, 
   grant,
   any_grant
);

    
    input   [ARBITER_WIDTH-1            :   0]  request;
    output  [ARBITER_WIDTH-1            :   0]  grant;
    output                                      any_grant;
   
    wire    [ARBITER_WIDTH-1            :   0]  cout;
    reg     [ARBITER_WIDTH-1            :   0]  cin;
    
    
    assign  any_grant= | request;
    
    assign grant    = cin & request;
    assign cout     = cin & ~request; 
    
     always @(*) begin 
        if( HIGH_PRORITY_BIT == "HSB")  cin      = {1'b1, cout[ARBITER_WIDTH-1 :1]}; // hsb has highest priority
        else                            cin      = {cout[ARBITER_WIDTH-2 :0] ,1'b1}; // lsb has highest priority
    end//always
endmodule
    
*/

 
 
 
