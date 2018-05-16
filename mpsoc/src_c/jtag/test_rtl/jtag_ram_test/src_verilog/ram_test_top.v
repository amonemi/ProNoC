
/**************************************************************************
**	WARNING: THIS IS AN AUTO-GENERATED FILE. CHANGES TO IT ARE LIKELY TO BE
**	OVERWRITTEN AND LOST. Rename this file if you wish to do any modification.
****************************************************************************/


/**********************************************************************
**	File: ram_test_top.v
**    
**	Copyright (C) 2014-2018  Alireza Monemi
**    
**	This file is part of ProNoC 1.7.0 
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
******************************************************************************/ 

`timescale 1ns / 1ps

module ram_test_top #(
 	parameter	CORE_ID=0,
	parameter	SW_LOC="/home/alireza/mywork/mpsoc_work/SOC/ram_test/sw" ,
	parameter	ram_Dw=32 ,
	parameter	ram_Aw=12
)(
	ss_clk_in, 
	ss_reset_in
);
  
  	function integer log2;
  		input integer number; begin	
          	log2=0;	
          	while(2**log2<number) begin	
        		  	log2=log2+1;	
         		end	
        		end	
     	endfunction // log2 
     	
     	function   [15:0]i2s;   
          input   integer c;  integer i;  integer tmp; begin 
              tmp =0; 
              for (i=0; i<2; i=i+1'b1) begin 
              tmp =  tmp +    (((c % 10)   + 6'd48) << i*8); 
                  c       =   c/10; 
              end 
              i2s = tmp[15:0];
          end     
     endfunction //i2s
  
 	localparam	programer_DW=32;
	localparam	programer_AW=32;
	localparam	programer_S_Aw=   7;
	localparam	programer_M_Aw=   32;
	localparam	programer_TAGw=   3;
	localparam	programer_SELw=   4;
	localparam	programer_VJTAG_INDEX=CORE_ID;

 	localparam	ram_BYTE_WR_EN="YES";
	localparam	ram_FPGA_VENDOR="ALTERA";
	localparam	ram_JTAG_CONNECT= "ALTERA_IMCE";
	localparam	ram_JTAG_INDEX=CORE_ID;
	localparam	ram_TAGw=3;
	localparam	ram_SELw=ram_Dw/8;
	localparam	ram_CTIw=3;
	localparam	ram_BTEw=2;
	localparam	ram_BURST_MODE="DISABLED";
	localparam	ram_MEM_CONTENT_FILE_NAME="ram0";
	localparam	ram_INITIAL_EN="NO";
	localparam	ram_INIT_FILE_PATH=SW_LOC;

 	localparam	bus_M=1;
	localparam	bus_S=1;
	localparam	bus_Dw=32;
	localparam	bus_Aw=32;
	localparam	bus_SELw=bus_Dw/8;
	localparam	bus_TAGw=3;
	localparam	bus_CTIw=3;
	localparam	bus_BTEw=2 ;


	input			ss_clk_in;
 	input			ss_reset_in;

 

// Allow software to remote reset/enable the cpu via jtag

	wire jtag_cpu_en, jtag_system_reset;

	jtag_system_en jtag_en (
		.cpu_en(jtag_cpu_en),
		.system_reset(jtag_system_reset)
	
	);
	
	





 	wire ss_reset_in_ored_jtag;

 ram_test #(
 	.CORE_ID(CORE_ID),
	.SW_LOC(SW_LOC),
	.ram_Dw(ram_Dw),
	.ram_Aw(ram_Aw) 
	)the_ram_test(

		.ss_clk_in(ss_clk_in),
		.ss_reset_in(ss_reset_in_ored_jtag)
	);
 	assign ss_reset_in_ored_jtag = (jtag_system_reset | ss_reset_in);

 
 endmodule
