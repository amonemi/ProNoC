`timescale     1ns/1ps
/****************************************************************************
 * pronoc_pkg.sv
 ****************************************************************************/

package piton_pkg; 
	`include "define.tmp.h"
	localparam FLATID_WIDTH = 8;
	
	typedef struct packed {
		logic [`DATA_WIDTH-1:0] 	data;
		logic valid;
		logic yummy; 
	} piton_chan_t;
	localparam PITON_CHANEL_w = $bits(piton_chan_t); 
	
	
	
endpackage :piton_pkg
