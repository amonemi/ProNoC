
/**********************************************************************
**	File:  jtag_source_probe.v 
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
**	Jtag source probe which can be read/write using host PC 
**	C-based software located in src_c/jtag
**		.
**
*******************************************************************/

// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

module jtag_source_probe #(
	parameter VJTAG_INDEX=127,
	 parameter Dw=2	//probe/probe width in bits	

)(
	source,
	probe
);


	input		[Dw-1	:0]  probe;
	output	reg [Dw-1	:0]  source;
	
	
	
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
	reg [Dw-1	:	0] shift_buffer,shift_buffer_next;
	reg cdr_delayed,sdr_delayed;
	reg [Dw-1	:	0] source_next;//,status_next;
	
	localparam BYPAS_ST= 3'b000,
				  SOURCE_ST=3'b001,
				  PROBE_ST =3'b010;
	
 
	
	assign ir_out = ir_in;	// Just pass the IR out
	assign tdo = (ir == BYPAS_ST) ? bypass_reg : shift_buffer[0];
   
	
	
	
	
	always @(posedge tck )
	begin
			if( uir ) ir <= ir_in; // Capture the instruction provided
			bypass_reg <= tdi;
			shift_buffer<=shift_buffer_next;
			source<=source_next;
	
	end
	
generate
	if(Dw==1)begin :DW1
		always @ (*)begin 
			shift_buffer_next=shift_buffer;
			source_next = source;
			if( sdr ) shift_buffer_next= tdi; //,shift_buffer[DW-1:1]};// shift buffer
			case(ir)
			SOURCE_ST:begin
				if (cdr ) shift_buffer_next  = source;
				if (udr ) source_next = shift_buffer;
			end
			PROBE_ST:begin
				if (cdr ) shift_buffer_next  = probe;
			end
			default begin
				shift_buffer_next=shift_buffer;
				source_next = source;			
			end
			endcase
				
		end
	end
	else begin :DWB
		always @ (*)begin 
			shift_buffer_next=shift_buffer;
			source_next = source;
			if( sdr ) shift_buffer_next= {tdi, shift_buffer[Dw-1:1]};// shift buffer
			case(ir)
			SOURCE_ST:begin
				if (cdr ) shift_buffer_next  = source;
				if (udr ) source_next = shift_buffer ;
			end
			PROBE_ST:begin
				if (cdr ) shift_buffer_next  = probe;
			end
			default begin
				shift_buffer_next=shift_buffer;
				source_next = source;			
			end
			endcase			
		end
	
	end
endgenerate	
	
	
endmodule

