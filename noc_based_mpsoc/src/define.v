/*********************************************************************
							
	File: define.v 
	
	Copyright (C) 2014  Alireza Monemi

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
	
	
	Purpose:
	contains global definitions 
	
	Info: monemi@fkegraduate.utm.my
*********************************************************************/
`ifndef	DEFINE_H
	`define	DEFINE_H

	
	
	
/*********************************************************************

The NoC router `define for  generate a mech topology. The following `defines will generate 
a 4X4 noC 

********************************************************************/	
//define the topology: "MESH" or "TORUS"
`define						TOPOLOGY_DEF						"MESH" 
//define the routing algorithm : "XY" or "MINIMAL"		
`define						ROUTE_ALGRMT_DEF					"XY"						
// The number of virtual channel (VC) for each individual physical channel. this value must be power of 2. The typical value is two and four.
`define 						VC_NUM_PER_PORT_DEF 				2

//The payload size in bites. For NIOS II is 32 bites.  The packet flit size is payload size plus the two bit for flit type and the VC_NUM_PER_PORT.  
`define						PYLD_WIDTH_DEF						32

// The buffer size in words (PYLD_WIDTH_DEF	) for each individual VC.  
`define						BUFFER_NUM_PER_VC_DEF			4

// the number of IP core in X axis
`define 						X_NODE_NUM_DEF						4

// the number of IP core in Y axis
`define						Y_NODE_NUM_DEF						4


`define 						AEMB_RAM_WIDTH_IN_WORD_DEF		12




`define 						SDRAM_EN_DEF						1//  0 : disabled  1: enabled 
`define 						SDRAM_SW_X_ADDR_DEF				2
`define 						SDRAM_SW_Y_ADDR_DEF				2
`define 						SDRAM_NI_CONNECT_PORT_DEF		0//local
`define 						SDRAM_ADDR_WIDTH_DEF				25

// aeMB PE def

	`define					AEMB_IWB_DEF							32 //< INST bus width
   `define 					AEMB_DWB_DEF 							32 ///< DATA bus width
   `define					AEMB_XWB_DEF 							7	///< XCEL bus width

   // CACHE `defineS
   `define					AEMB_ICH_DEF 							11 ///< instruction cache size
   `define					AEMB_IDX_DEF 							 6///< cache index size

   // OPTIONAL HARDWARE
   `define					AEMB_BSF_DEF 							1 ///< optional barrel shift
   `define					AEMB_MUL_DEF 							1 ///< optional multiplier

	
	
	
	
	`define					AEMB_IWB_ADRR_RANG					`AEMB_IWB_DEF-3	:	0
	`define					AEMB_DWB_ADRR_RANG					`AEMB_DWB_DEF-3	:	0
	`define					RAM_ADDR_RANG							`AEMB_RAM_WIDTH_IN_WORD_DEF-1		:0
	`define					NOC_S_ADDR_RANG						`NOC_S_ADDR_WIDTH_DEF-1		:	0								
	
	`define 					NOC_S_ADDR_WIDTH_DEF				3

/*************************************************************
Do not change the rest of definition, othervise u need to adjast the other verilog codes 
to work with new values.
************************************************************/

//	 `define				LOCAL									5'b00001
//	 `define 			EAST									5'b00010
//	 `define 			NORTH									5'b00100
//	 `define 			WEAST									5'b01000
//	 `define 			SOUTH									5'b10000
	 
	  `define			HDR_FLIT								2'b10
	  `define			BODY_FLIT							2'b00
	  `define			TAIL_FLIT							2'b01
	 
	 
	 `define 			FLIT_HDR_FLG_LOC				 	FLIT_WIDTH-1
	 `define 			FLIT_TAIL_FLAG_LOC			 	FLIT_WIDTH-2
	 `define 			FLIT_IN_VC_START					FLIT_WIDTH-FLIT_TYPE_WIDTH-1	
	
	 `define 			FLIT_IN_PORT_SEL_START			`FLIT_IN_VC_START			-	VC_NUM_PER_PORT
	 `define 			FLIT_IN_X_DES_START				`FLIT_IN_PORT_SEL_START	-	log2(PORT_NUM)	
	 `define 			FLIT_IN_Y_DES_START				`FLIT_IN_X_DES_START		-	X_NODE_NUM_WIDTH	
	 
	
	 `define 			FLIT_IN_X_SRC_START				`FLIT_IN_Y_DES_START		-	Y_NODE_NUM_WIDTH		
	 `define 			FLIT_IN_Y_SRC_START				`FLIT_IN_X_SRC_START		-	X_NODE_NUM_WIDTH	
	 `define				FLIT_IN_Y_SRC_END					`FLIT_IN_Y_SRC_START		-	Y_NODE_NUM_WIDTH 
	
	 `define				FLIT_IN_TYPE_LOC					`FLIT_HDR_FLG_LOC				:		`FLIT_IN_VC_START+1
	 `define 			FLIT_IN_VC_LOC						`FLIT_IN_VC_START				:		`FLIT_IN_PORT_SEL_START+1				
	 `define 			FLIT_IN_PORT_SEL_LOC				`FLIT_IN_PORT_SEL_START		:		`FLIT_IN_X_DES_START+1
	 `define 			FLIT_IN_X_DES_LOC					`FLIT_IN_X_DES_START			:		`FLIT_IN_Y_DES_START+1		
	 `define 			FLIT_IN_Y_DES_LOC					`FLIT_IN_Y_DES_START			:		`FLIT_IN_X_SRC_START+1			
	 `define 			FLIT_IN_X_SRC_LOC					`FLIT_IN_X_SRC_START			:		`FLIT_IN_Y_SRC_START+1		
	 `define 			FLIT_IN_Y_SRC_LOC					`FLIT_IN_Y_SRC_START			:		`FLIT_IN_Y_SRC_END+1			
	
	 
	 
	 
	`define 			FLIT_IN_PYLD_LOC					`FLIT_IN_PORT_SEL_START		:		0
	`define 			FLIT_IN_AFTER_PORT_LOC			`FLIT_IN_X_DES_START			:		0
	
	`define				JTAG_PROG_LOC						0
	`define				FLIT_IN_WR_RAM_LOC				0				
	`define				FLIT_IN_ACK_REQ_LOC				1
	
	
	`define  START_LOC(port_num,width)	   (width*(port_num+1)-1)
	`define	END_LOC(port_num,width)			(width*port_num)
	`define	CORE_NUM(x,y) 						((y * X_NODE_NUM) +	x)
	`define  SELECT_WIRE(x,y,port,width)	`CORE_NUM(x,y)] [`START_LOC(port,width) : `END_LOC(port,width )
	
	`define	NI_RD_PCK_ADDR				0
	`define	NI_WR_PCK_ADDR				4
	`define	NI_STATUS_ADDR				8
	
	`define	NI_WR_DONE_LOC				0
	`define	NI_RD_DONE_LOC				1
	`define 	NI_RD_OVR_ERR_LOC			2
	`define	NI_RD_NPCK_ERR_LOC		3
	`define	NI_HAS_PCK_LOC				4
	
	`define	NI_PTR_WIDTH				19
	`define	NI_PCK_SIZE_WIDTH			13
	
	
	
	
	`define JTAG_HAS_DATA_LOC				31
	`define JTAG_DONE_LOC					30
	`define JTAG_NO_PCK_ERR_LOC			29		
	`define JTAG OVR_SIZE_ERR				28
	
	`define	JTAG_START_LOC					7
	`define	JTAG_RAM_RW_LOC				6
	`define 	JTAG_LAST_PART_LOC			5
	`define 	JTAG_FIRST_PART_LOC			4
	`define  JTAG_START_RD_LOC				3
	`define  JTAG_START_WR_LOC				2
	`define	JTAG_PROG_START_LOC			1  
	`define  JTAG_NIOS_RST_LOC				0


 `define LOG2	function integer log2;\
      input integer number;	begin	\
         log2=0;	\
         while(2**log2<number) begin	\
            log2=log2+1;	\
         end	\
      end	\
   endfunction // log2 



`endif


