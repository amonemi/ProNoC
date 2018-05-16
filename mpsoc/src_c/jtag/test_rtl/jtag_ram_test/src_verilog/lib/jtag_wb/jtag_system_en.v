/**********************************************************************
**	File:  jtag_system_en.v 
**	
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
**	each system single core or many core must have one jtag_system_en module in order
**	to allow mmeory programming.
**	This module has two output ports which can be programed using jtag interface:
**	cpu_en: which can enable/disable the cpu cores. This port must be connected to all
**		cpus enable port in order tio deactiavte them during memory programming
**	system_reset: This pin must be ored by sytem global reset pin. The jtag memory 
**		programmer will reset the system before and after perogramming the memories.
**
*******************************************************************/


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on


module jtag_system_en (
	cpu_en,
	system_reset
	
);
	output cpu_en, 	system_reset;
	wire [1	:	0] jtag_out;

	jtag_control_port #(
		.VJTAG_INDEX(127),
		.DW(2)	

	)enable(
		.jtag_out(jtag_out)
	);

	assign system_reset=jtag_out[0];
	assign cpu_en=~jtag_out[1];

endmodule



module jtag_control_port #(
	parameter VJTAG_INDEX=127,
	parameter DW=2	

)(
	jtag_out
);


	output [DW-1	:	0] jtag_out;
	
	
	
	//vjtag	vjtag signals declaration
	wire	[2:0]  ir_out ,  ir_in;
	wire	  tdo, tck,	  tdi;	
	wire	  cdr ,cir,e1dr,e2dr,pdr,sdr,udr,uir;
	
	
	vjtag	#(
	 .VJTAG_INDEX(VJTAG_INDEX)
	)
	vjtag_inst (
	.ir_out ( ir_out ),
	.tdo ( tdo ),
	.ir_in ( ir_in ),
	.tck ( tck ),
	.tdi ( tdi ),
	.virtual_state_cdr 	( cdr ),
	.virtual_state_cir 	( cir ),
	.virtual_state_e1dr 	( e1dr ),
	.virtual_state_e2dr 	( e2dr ),
	.virtual_state_pdr 	( pdr ),
	.virtual_state_sdr 	( sdr ),
	.virtual_state_udr 	( udr ),
	.virtual_state_uir 	( uir )
	);

	
	// IR states
	
	
	
	reg [2:0] ir;
	reg bypass_reg;
	reg [DW-1	:	0] shift_buffer,shift_buffer_next;
	reg cdr_delayed,sdr_delayed;
	reg [DW-1	:	0] status,status_next;
	
	assign jtag_out = status ;
 /*	
	always @(negedge tck)
	begin
		//  Delay the CDR signal by one half clock cycle 
		cdr_delayed = cdr;
		sdr_delayed = sdr;
	end
	*/
	
	assign ir_out = ir_in;	// Just pass the IR out
	assign tdo = (ir == 3'b000) ? bypass_reg : shift_buffer[0];
   
	
	
	
	
	always @(posedge tck )
	begin
			if( uir ) ir <= ir_in; // Capture the instruction provided
			bypass_reg <= tdi;
			shift_buffer<=shift_buffer_next;
			status<=status_next;
	
	end
	
generate
	if(DW==1)begin :DW1
		always @ (*)begin 
			shift_buffer_next=shift_buffer;
			status_next = status;
			if( sdr ) shift_buffer_next= tdi; //,shift_buffer[DW-1:1]};// shift buffer
			if((ir == 3'b001) &  cdr ) shift_buffer_next  = status;
			if((ir == 3'b001) &  udr ) status_next = shift_buffer;
		end
	end
	else begin :DWB
		always @ (*)begin 
			shift_buffer_next=shift_buffer;
			status_next = status;
			if( sdr ) shift_buffer_next= {tdi, shift_buffer[DW-1:1]};// shift buffer
			if((ir == 3'b001) &  cdr ) shift_buffer_next  = status;
			if((ir == 3'b001) &  udr ) status_next = shift_buffer;
		end
	
	end
endgenerate	
	
	
endmodule


