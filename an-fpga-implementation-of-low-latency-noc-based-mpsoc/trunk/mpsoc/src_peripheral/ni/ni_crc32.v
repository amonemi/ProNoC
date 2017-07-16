
/**********************************************************************
**	File:  ni_crc32.v 
**	Date:2017-06-14  
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
**	Description: CRC32 generator 
**	
**
*******************************************************************/







 `timescale  1ns/1ps
module crc_32_multi_channel #(
    parameter CHANNEL=4

)(
    reset,
    clk,
    channel_in,
    crc_reset,
    crc_enable,
    data_in,
    crc_out 
   
 );
 
   function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end       
      end   
    endfunction // log2 

 localparam CHw=log2(CHANNEL);

    input  reset, clk, crc_reset, crc_enable;
    input  [CHw-1   :   0] channel_in;
    input  [31  :   0] data_in;
    output [31  :   0] crc_out;
      
    
    wire [31:0] crc_in,crc_reg_next;
    assign crc_out = crc_in;
    
    
    

    
    
    
    
    crc_32_combinational crc_32_comb(
    	.data_in(data_in),
    	.crc_out(crc_reg_next),
    	.crc_in(crc_in)
    );
    
    reg [31 :   0]  crc_channel_reg [CHANNEL-1  :   0];
    
    
    assign crc_in = crc_channel_reg[channel_in];
    
    genvar i;
    generate
    for (i=0;i<CHANNEL; i=i+1)begin :lp
    always @(posedge clk or posedge reset) begin 
        if (reset ) begin 
            crc_channel_reg[i]<=0;
        end else begin 
            if(channel_in == i)begin 
                if(crc_reset)  crc_channel_reg[i]<=0;
                else if(crc_enable   )  crc_channel_reg[i]<=crc_reg_next;
            end
        end
    
    end
    end
    endgenerate
    
endmodule




//-----------------------------------------------------------------------------
// Copyright (C) 2009 OutputLogic.com 
// This source file may be used and distributed without restriction 
// provided that this copyright statement is not removed from the file 
// and that any derivative work contains the original copyright notice 
// and the associated disclaimer. 
// 
// THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS 
// OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED    
// WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE. 
//-----------------------------------------------------------------------------
// CRC module for data[31:0] ,   crc[31:0]=1+x^1+x^2+x^4+x^5+x^7+x^8+x^10+x^11+x^12+x^16+x^22+x^23+x^26+x^32;
//-----------------------------------------------------------------------------
module crc_32_combinational(
    data_in,
    crc_out, 
    crc_in 
 );

    input [31:0] data_in;
    output reg [31:0] crc_out; 
    input [31:0] crc_in;

  
  always @(*) begin
    crc_out[0] = crc_in[0] ^ crc_in[6] ^ crc_in[9] ^ crc_in[10] ^ crc_in[12] ^ crc_in[16] ^ crc_in[24] ^ crc_in[25] ^ crc_in[26] ^ crc_in[28] ^ crc_in[29] ^ crc_in[30] ^ crc_in[31] ^ data_in[0] ^ data_in[6] ^ data_in[9] ^ data_in[10] ^ data_in[12] ^ data_in[16] ^ data_in[24] ^ data_in[25] ^ data_in[26] ^ data_in[28] ^ data_in[29] ^ data_in[30] ^ data_in[31];
    crc_out[1] = crc_in[0] ^ crc_in[1] ^ crc_in[6] ^ crc_in[7] ^ crc_in[9] ^ crc_in[11] ^ crc_in[12] ^ crc_in[13] ^ crc_in[16] ^ crc_in[17] ^ crc_in[24] ^ crc_in[27] ^ crc_in[28] ^ data_in[0] ^ data_in[1] ^ data_in[6] ^ data_in[7] ^ data_in[9] ^ data_in[11] ^ data_in[12] ^ data_in[13] ^ data_in[16] ^ data_in[17] ^ data_in[24] ^ data_in[27] ^ data_in[28];
    crc_out[2] = crc_in[0] ^ crc_in[1] ^ crc_in[2] ^ crc_in[6] ^ crc_in[7] ^ crc_in[8] ^ crc_in[9] ^ crc_in[13] ^ crc_in[14] ^ crc_in[16] ^ crc_in[17] ^ crc_in[18] ^ crc_in[24] ^ crc_in[26] ^ crc_in[30] ^ crc_in[31] ^ data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[6] ^ data_in[7] ^ data_in[8] ^ data_in[9] ^ data_in[13] ^ data_in[14] ^ data_in[16] ^ data_in[17] ^ data_in[18] ^ data_in[24] ^ data_in[26] ^ data_in[30] ^ data_in[31];
    crc_out[3] = crc_in[1] ^ crc_in[2] ^ crc_in[3] ^ crc_in[7] ^ crc_in[8] ^ crc_in[9] ^ crc_in[10] ^ crc_in[14] ^ crc_in[15] ^ crc_in[17] ^ crc_in[18] ^ crc_in[19] ^ crc_in[25] ^ crc_in[27] ^ crc_in[31] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[7] ^ data_in[8] ^ data_in[9] ^ data_in[10] ^ data_in[14] ^ data_in[15] ^ data_in[17] ^ data_in[18] ^ data_in[19] ^ data_in[25] ^ data_in[27] ^ data_in[31];
    crc_out[4] = crc_in[0] ^ crc_in[2] ^ crc_in[3] ^ crc_in[4] ^ crc_in[6] ^ crc_in[8] ^ crc_in[11] ^ crc_in[12] ^ crc_in[15] ^ crc_in[18] ^ crc_in[19] ^ crc_in[20] ^ crc_in[24] ^ crc_in[25] ^ crc_in[29] ^ crc_in[30] ^ crc_in[31] ^ data_in[0] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[6] ^ data_in[8] ^ data_in[11] ^ data_in[12] ^ data_in[15] ^ data_in[18] ^ data_in[19] ^ data_in[20] ^ data_in[24] ^ data_in[25] ^ data_in[29] ^ data_in[30] ^ data_in[31];
    crc_out[5] = crc_in[0] ^ crc_in[1] ^ crc_in[3] ^ crc_in[4] ^ crc_in[5] ^ crc_in[6] ^ crc_in[7] ^ crc_in[10] ^ crc_in[13] ^ crc_in[19] ^ crc_in[20] ^ crc_in[21] ^ crc_in[24] ^ crc_in[28] ^ crc_in[29] ^ data_in[0] ^ data_in[1] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7] ^ data_in[10] ^ data_in[13] ^ data_in[19] ^ data_in[20] ^ data_in[21] ^ data_in[24] ^ data_in[28] ^ data_in[29];
    crc_out[6] = crc_in[1] ^ crc_in[2] ^ crc_in[4] ^ crc_in[5] ^ crc_in[6] ^ crc_in[7] ^ crc_in[8] ^ crc_in[11] ^ crc_in[14] ^ crc_in[20] ^ crc_in[21] ^ crc_in[22] ^ crc_in[25] ^ crc_in[29] ^ crc_in[30] ^ data_in[1] ^ data_in[2] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7] ^ data_in[8] ^ data_in[11] ^ data_in[14] ^ data_in[20] ^ data_in[21] ^ data_in[22] ^ data_in[25] ^ data_in[29] ^ data_in[30];
    crc_out[7] = crc_in[0] ^ crc_in[2] ^ crc_in[3] ^ crc_in[5] ^ crc_in[7] ^ crc_in[8] ^ crc_in[10] ^ crc_in[15] ^ crc_in[16] ^ crc_in[21] ^ crc_in[22] ^ crc_in[23] ^ crc_in[24] ^ crc_in[25] ^ crc_in[28] ^ crc_in[29] ^ data_in[0] ^ data_in[2] ^ data_in[3] ^ data_in[5] ^ data_in[7] ^ data_in[8] ^ data_in[10] ^ data_in[15] ^ data_in[16] ^ data_in[21] ^ data_in[22] ^ data_in[23] ^ data_in[24] ^ data_in[25] ^ data_in[28] ^ data_in[29];
    crc_out[8] = crc_in[0] ^ crc_in[1] ^ crc_in[3] ^ crc_in[4] ^ crc_in[8] ^ crc_in[10] ^ crc_in[11] ^ crc_in[12] ^ crc_in[17] ^ crc_in[22] ^ crc_in[23] ^ crc_in[28] ^ crc_in[31] ^ data_in[0] ^ data_in[1] ^ data_in[3] ^ data_in[4] ^ data_in[8] ^ data_in[10] ^ data_in[11] ^ data_in[12] ^ data_in[17] ^ data_in[22] ^ data_in[23] ^ data_in[28] ^ data_in[31];
    crc_out[9] = crc_in[1] ^ crc_in[2] ^ crc_in[4] ^ crc_in[5] ^ crc_in[9] ^ crc_in[11] ^ crc_in[12] ^ crc_in[13] ^ crc_in[18] ^ crc_in[23] ^ crc_in[24] ^ crc_in[29] ^ data_in[1] ^ data_in[2] ^ data_in[4] ^ data_in[5] ^ data_in[9] ^ data_in[11] ^ data_in[12] ^ data_in[13] ^ data_in[18] ^ data_in[23] ^ data_in[24] ^ data_in[29];
    crc_out[10] = crc_in[0] ^ crc_in[2] ^ crc_in[3] ^ crc_in[5] ^ crc_in[9] ^ crc_in[13] ^ crc_in[14] ^ crc_in[16] ^ crc_in[19] ^ crc_in[26] ^ crc_in[28] ^ crc_in[29] ^ crc_in[31] ^ data_in[0] ^ data_in[2] ^ data_in[3] ^ data_in[5] ^ data_in[9] ^ data_in[13] ^ data_in[14] ^ data_in[16] ^ data_in[19] ^ data_in[26] ^ data_in[28] ^ data_in[29] ^ data_in[31];
    crc_out[11] = crc_in[0] ^ crc_in[1] ^ crc_in[3] ^ crc_in[4] ^ crc_in[9] ^ crc_in[12] ^ crc_in[14] ^ crc_in[15] ^ crc_in[16] ^ crc_in[17] ^ crc_in[20] ^ crc_in[24] ^ crc_in[25] ^ crc_in[26] ^ crc_in[27] ^ crc_in[28] ^ crc_in[31] ^ data_in[0] ^ data_in[1] ^ data_in[3] ^ data_in[4] ^ data_in[9] ^ data_in[12] ^ data_in[14] ^ data_in[15] ^ data_in[16] ^ data_in[17] ^ data_in[20] ^ data_in[24] ^ data_in[25] ^ data_in[26] ^ data_in[27] ^ data_in[28] ^ data_in[31];
    crc_out[12] = crc_in[0] ^ crc_in[1] ^ crc_in[2] ^ crc_in[4] ^ crc_in[5] ^ crc_in[6] ^ crc_in[9] ^ crc_in[12] ^ crc_in[13] ^ crc_in[15] ^ crc_in[17] ^ crc_in[18] ^ crc_in[21] ^ crc_in[24] ^ crc_in[27] ^ crc_in[30] ^ crc_in[31] ^ data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[9] ^ data_in[12] ^ data_in[13] ^ data_in[15] ^ data_in[17] ^ data_in[18] ^ data_in[21] ^ data_in[24] ^ data_in[27] ^ data_in[30] ^ data_in[31];
    crc_out[13] = crc_in[1] ^ crc_in[2] ^ crc_in[3] ^ crc_in[5] ^ crc_in[6] ^ crc_in[7] ^ crc_in[10] ^ crc_in[13] ^ crc_in[14] ^ crc_in[16] ^ crc_in[18] ^ crc_in[19] ^ crc_in[22] ^ crc_in[25] ^ crc_in[28] ^ crc_in[31] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[5] ^ data_in[6] ^ data_in[7] ^ data_in[10] ^ data_in[13] ^ data_in[14] ^ data_in[16] ^ data_in[18] ^ data_in[19] ^ data_in[22] ^ data_in[25] ^ data_in[28] ^ data_in[31];
    crc_out[14] = crc_in[2] ^ crc_in[3] ^ crc_in[4] ^ crc_in[6] ^ crc_in[7] ^ crc_in[8] ^ crc_in[11] ^ crc_in[14] ^ crc_in[15] ^ crc_in[17] ^ crc_in[19] ^ crc_in[20] ^ crc_in[23] ^ crc_in[26] ^ crc_in[29] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[6] ^ data_in[7] ^ data_in[8] ^ data_in[11] ^ data_in[14] ^ data_in[15] ^ data_in[17] ^ data_in[19] ^ data_in[20] ^ data_in[23] ^ data_in[26] ^ data_in[29];
    crc_out[15] = crc_in[3] ^ crc_in[4] ^ crc_in[5] ^ crc_in[7] ^ crc_in[8] ^ crc_in[9] ^ crc_in[12] ^ crc_in[15] ^ crc_in[16] ^ crc_in[18] ^ crc_in[20] ^ crc_in[21] ^ crc_in[24] ^ crc_in[27] ^ crc_in[30] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[7] ^ data_in[8] ^ data_in[9] ^ data_in[12] ^ data_in[15] ^ data_in[16] ^ data_in[18] ^ data_in[20] ^ data_in[21] ^ data_in[24] ^ data_in[27] ^ data_in[30];
    crc_out[16] = crc_in[0] ^ crc_in[4] ^ crc_in[5] ^ crc_in[8] ^ crc_in[12] ^ crc_in[13] ^ crc_in[17] ^ crc_in[19] ^ crc_in[21] ^ crc_in[22] ^ crc_in[24] ^ crc_in[26] ^ crc_in[29] ^ crc_in[30] ^ data_in[0] ^ data_in[4] ^ data_in[5] ^ data_in[8] ^ data_in[12] ^ data_in[13] ^ data_in[17] ^ data_in[19] ^ data_in[21] ^ data_in[22] ^ data_in[24] ^ data_in[26] ^ data_in[29] ^ data_in[30];
    crc_out[17] = crc_in[1] ^ crc_in[5] ^ crc_in[6] ^ crc_in[9] ^ crc_in[13] ^ crc_in[14] ^ crc_in[18] ^ crc_in[20] ^ crc_in[22] ^ crc_in[23] ^ crc_in[25] ^ crc_in[27] ^ crc_in[30] ^ crc_in[31] ^ data_in[1] ^ data_in[5] ^ data_in[6] ^ data_in[9] ^ data_in[13] ^ data_in[14] ^ data_in[18] ^ data_in[20] ^ data_in[22] ^ data_in[23] ^ data_in[25] ^ data_in[27] ^ data_in[30] ^ data_in[31];
    crc_out[18] = crc_in[2] ^ crc_in[6] ^ crc_in[7] ^ crc_in[10] ^ crc_in[14] ^ crc_in[15] ^ crc_in[19] ^ crc_in[21] ^ crc_in[23] ^ crc_in[24] ^ crc_in[26] ^ crc_in[28] ^ crc_in[31] ^ data_in[2] ^ data_in[6] ^ data_in[7] ^ data_in[10] ^ data_in[14] ^ data_in[15] ^ data_in[19] ^ data_in[21] ^ data_in[23] ^ data_in[24] ^ data_in[26] ^ data_in[28] ^ data_in[31];
    crc_out[19] = crc_in[3] ^ crc_in[7] ^ crc_in[8] ^ crc_in[11] ^ crc_in[15] ^ crc_in[16] ^ crc_in[20] ^ crc_in[22] ^ crc_in[24] ^ crc_in[25] ^ crc_in[27] ^ crc_in[29] ^ data_in[3] ^ data_in[7] ^ data_in[8] ^ data_in[11] ^ data_in[15] ^ data_in[16] ^ data_in[20] ^ data_in[22] ^ data_in[24] ^ data_in[25] ^ data_in[27] ^ data_in[29];
    crc_out[20] = crc_in[4] ^ crc_in[8] ^ crc_in[9] ^ crc_in[12] ^ crc_in[16] ^ crc_in[17] ^ crc_in[21] ^ crc_in[23] ^ crc_in[25] ^ crc_in[26] ^ crc_in[28] ^ crc_in[30] ^ data_in[4] ^ data_in[8] ^ data_in[9] ^ data_in[12] ^ data_in[16] ^ data_in[17] ^ data_in[21] ^ data_in[23] ^ data_in[25] ^ data_in[26] ^ data_in[28] ^ data_in[30];
    crc_out[21] = crc_in[5] ^ crc_in[9] ^ crc_in[10] ^ crc_in[13] ^ crc_in[17] ^ crc_in[18] ^ crc_in[22] ^ crc_in[24] ^ crc_in[26] ^ crc_in[27] ^ crc_in[29] ^ crc_in[31] ^ data_in[5] ^ data_in[9] ^ data_in[10] ^ data_in[13] ^ data_in[17] ^ data_in[18] ^ data_in[22] ^ data_in[24] ^ data_in[26] ^ data_in[27] ^ data_in[29] ^ data_in[31];
    crc_out[22] = crc_in[0] ^ crc_in[9] ^ crc_in[11] ^ crc_in[12] ^ crc_in[14] ^ crc_in[16] ^ crc_in[18] ^ crc_in[19] ^ crc_in[23] ^ crc_in[24] ^ crc_in[26] ^ crc_in[27] ^ crc_in[29] ^ crc_in[31] ^ data_in[0] ^ data_in[9] ^ data_in[11] ^ data_in[12] ^ data_in[14] ^ data_in[16] ^ data_in[18] ^ data_in[19] ^ data_in[23] ^ data_in[24] ^ data_in[26] ^ data_in[27] ^ data_in[29] ^ data_in[31];
    crc_out[23] = crc_in[0] ^ crc_in[1] ^ crc_in[6] ^ crc_in[9] ^ crc_in[13] ^ crc_in[15] ^ crc_in[16] ^ crc_in[17] ^ crc_in[19] ^ crc_in[20] ^ crc_in[26] ^ crc_in[27] ^ crc_in[29] ^ crc_in[31] ^ data_in[0] ^ data_in[1] ^ data_in[6] ^ data_in[9] ^ data_in[13] ^ data_in[15] ^ data_in[16] ^ data_in[17] ^ data_in[19] ^ data_in[20] ^ data_in[26] ^ data_in[27] ^ data_in[29] ^ data_in[31];
    crc_out[24] = crc_in[1] ^ crc_in[2] ^ crc_in[7] ^ crc_in[10] ^ crc_in[14] ^ crc_in[16] ^ crc_in[17] ^ crc_in[18] ^ crc_in[20] ^ crc_in[21] ^ crc_in[27] ^ crc_in[28] ^ crc_in[30] ^ data_in[1] ^ data_in[2] ^ data_in[7] ^ data_in[10] ^ data_in[14] ^ data_in[16] ^ data_in[17] ^ data_in[18] ^ data_in[20] ^ data_in[21] ^ data_in[27] ^ data_in[28] ^ data_in[30];
    crc_out[25] = crc_in[2] ^ crc_in[3] ^ crc_in[8] ^ crc_in[11] ^ crc_in[15] ^ crc_in[17] ^ crc_in[18] ^ crc_in[19] ^ crc_in[21] ^ crc_in[22] ^ crc_in[28] ^ crc_in[29] ^ crc_in[31] ^ data_in[2] ^ data_in[3] ^ data_in[8] ^ data_in[11] ^ data_in[15] ^ data_in[17] ^ data_in[18] ^ data_in[19] ^ data_in[21] ^ data_in[22] ^ data_in[28] ^ data_in[29] ^ data_in[31];
    crc_out[26] = crc_in[0] ^ crc_in[3] ^ crc_in[4] ^ crc_in[6] ^ crc_in[10] ^ crc_in[18] ^ crc_in[19] ^ crc_in[20] ^ crc_in[22] ^ crc_in[23] ^ crc_in[24] ^ crc_in[25] ^ crc_in[26] ^ crc_in[28] ^ crc_in[31] ^ data_in[0] ^ data_in[3] ^ data_in[4] ^ data_in[6] ^ data_in[10] ^ data_in[18] ^ data_in[19] ^ data_in[20] ^ data_in[22] ^ data_in[23] ^ data_in[24] ^ data_in[25] ^ data_in[26] ^ data_in[28] ^ data_in[31];
    crc_out[27] = crc_in[1] ^ crc_in[4] ^ crc_in[5] ^ crc_in[7] ^ crc_in[11] ^ crc_in[19] ^ crc_in[20] ^ crc_in[21] ^ crc_in[23] ^ crc_in[24] ^ crc_in[25] ^ crc_in[26] ^ crc_in[27] ^ crc_in[29] ^ data_in[1] ^ data_in[4] ^ data_in[5] ^ data_in[7] ^ data_in[11] ^ data_in[19] ^ data_in[20] ^ data_in[21] ^ data_in[23] ^ data_in[24] ^ data_in[25] ^ data_in[26] ^ data_in[27] ^ data_in[29];
    crc_out[28] = crc_in[2] ^ crc_in[5] ^ crc_in[6] ^ crc_in[8] ^ crc_in[12] ^ crc_in[20] ^ crc_in[21] ^ crc_in[22] ^ crc_in[24] ^ crc_in[25] ^ crc_in[26] ^ crc_in[27] ^ crc_in[28] ^ crc_in[30] ^ data_in[2] ^ data_in[5] ^ data_in[6] ^ data_in[8] ^ data_in[12] ^ data_in[20] ^ data_in[21] ^ data_in[22] ^ data_in[24] ^ data_in[25] ^ data_in[26] ^ data_in[27] ^ data_in[28] ^ data_in[30];
    crc_out[29] = crc_in[3] ^ crc_in[6] ^ crc_in[7] ^ crc_in[9] ^ crc_in[13] ^ crc_in[21] ^ crc_in[22] ^ crc_in[23] ^ crc_in[25] ^ crc_in[26] ^ crc_in[27] ^ crc_in[28] ^ crc_in[29] ^ crc_in[31] ^ data_in[3] ^ data_in[6] ^ data_in[7] ^ data_in[9] ^ data_in[13] ^ data_in[21] ^ data_in[22] ^ data_in[23] ^ data_in[25] ^ data_in[26] ^ data_in[27] ^ data_in[28] ^ data_in[29] ^ data_in[31];
    crc_out[30] = crc_in[4] ^ crc_in[7] ^ crc_in[8] ^ crc_in[10] ^ crc_in[14] ^ crc_in[22] ^ crc_in[23] ^ crc_in[24] ^ crc_in[26] ^ crc_in[27] ^ crc_in[28] ^ crc_in[29] ^ crc_in[30] ^ data_in[4] ^ data_in[7] ^ data_in[8] ^ data_in[10] ^ data_in[14] ^ data_in[22] ^ data_in[23] ^ data_in[24] ^ data_in[26] ^ data_in[27] ^ data_in[28] ^ data_in[29] ^ data_in[30];
    crc_out[31] = crc_in[5] ^ crc_in[8] ^ crc_in[9] ^ crc_in[11] ^ crc_in[15] ^ crc_in[23] ^ crc_in[24] ^ crc_in[25] ^ crc_in[27] ^ crc_in[28] ^ crc_in[29] ^ crc_in[30] ^ crc_in[31] ^ data_in[5] ^ data_in[8] ^ data_in[9] ^ data_in[11] ^ data_in[15] ^ data_in[23] ^ data_in[24] ^ data_in[25] ^ data_in[27] ^ data_in[28] ^ data_in[29] ^ data_in[30] ^ data_in[31];

  end // always



endmodule

