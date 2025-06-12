
/**************************************************************************
**	WARNING: THIS IS AN AUTO-GENERATED FILE. CHANGES TO IT ARE LIKELY TO BE
**	OVERWRITTEN AND LOST. Rename this file if you wish to do any modification.
****************************************************************************/


/**********************************************************************
**	File: noc_localparam.v
**    
**	Copyright (C) 2014-2022  Alireza Monemi
**    
**	This file is part of ProNoC 2.2.0 
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

	
	`ifdef   NOC_LOCAL_PARAM 
 
 
	

//NoC parameters
    localparam NOC_ID=0;
            //NOC_ID : Unique identifier for the NoC. Will be modified by phy_noc_gen.pl script
	localparam TOPOLOGY="MESH";
            //TOPOLOGY : Specifies the NoC topology. 
            //    Options include "MESH","FMESH","TORUS","RING","LINE","FATTREE","TREE","STAR","CUSTOM"

	localparam T1=4;
            //T1 : Number of NoC routers in row (X dimension)

	localparam T2=4;
            //T2 : Number of NoC routers in column (Y dimension)

	localparam T3=2;
            //T3 : Number of endpoints per router. In "MESH" topology, each router
            //        can have up to 4 endpoint processing tile.

	localparam V=2;
            //V : Number of Virtual chanel per each router port

	localparam B=4;
            //B : Buffer queue size per VC in flits

	localparam LB=7;
            //LB : Buffer width for local router ports connected to endpoints. 
            //    May differ from B, which is for neighboring router ports. 
            //    Applicable to MESH, FMESH, TORUS, LINE, and RING topologies. 
            //    In FMESH, LB does not affect extra endpoints on edge routers.

	localparam Fpay=32;
            //Fpay : The packet payload width in bits

	localparam ROUTE_NAME="XY";
            //ROUTE_NAME : Select the routing algorithm: XY(DoR) , partially adaptive (Turn models). Fully adaptive (Duato) 
            //    options are "XY","WEST_FIRST","NORTH_LAST","NEGETIVE_FIRST","ODD_EVEN","DUATO"

	localparam PCK_TYPE="MULTI_FLIT";
            //PCK_TYPE : Packet type.
            //    - SINGLE_FLIT: All packets are single-flit sized.
            //    - MULTI_FLIT: Packets can be single-flit, two-flit, or multi-flit sized:
            //        a) Single-flit: Head and tail flags set on one flit.
            //        b) Two-flit: Separate header and tail flits.
            //        c) Multi-flit: Header, one or more body flits, and a tail flit.

	localparam MIN_PCK_SIZE=2;
            //MIN_PCK_SIZE : Minimum packet size in flits.
            //    - For atomic VC reallocation, any value ≥1 is valid.
            //    - For non-atomic VC reallocation, this value defines buffer behavior.
            //    Note: Setting a value smaller than received packet size may cause crashes.

	localparam BYTE_EN=0;
            //BYTE_EN : 0 - Disable, 1 - Enable. 
            //    Adds a Byte Enable (BE) field to the header flit, indicating the location of 
            //    the last valid byte in the tail flit. This is required when the data unit being 
            //    sent is smaller than the Fpay value.

	localparam CAST_TYPE="UNICAST";
            //CAST_TYPE : Specifies NoC communication type.
            //    - UNICAST: A packet targets a single destination.
            //    - MULTICAST/BROADCAST: A single packet targets multiple/all destinations.
            //    Options: FULL (all nodes) or PARTIAL (defined by MCAST_ENDP_LIST).
            //    Select one of "UNICAST","MULTICAST_PARTIAL","MULTICAST_FULL","BROADCAST_PARTIAL","BROADCAST_FULL"

	localparam MCAST_ENDP_LIST=32'hf;
	localparam SSA_EN=0;
            //SSA_EN : Enable single cycle latency on packets traversing in the same direction using 
            //    static straight allocator (SSA)

	localparam SMART_MAX=0;
            //SMART_MAX : Maximum number of routers a packet can bypass in a straight direction
            //    in a single cycle (0 = no bypass)

	localparam CONGESTION_INDEX=3;
            //CONGESTION_INDEX : Congestion index determines how congestion information is collected 
            //    from neighboring routers. Please refer to the usere manual for more information

	localparam ESCAP_VC_MASK=2'b01;
            //ESCAP_VC_MASK : Select the escap VC for fully adaptive routing.

	localparam VC_REALLOCATION_TYPE="NONATOMIC";
            //VC_REALLOCATION_TYPE : VC reallocation policy.
            //    - ATOMIC: Only empty VCs can be reallocated.
            //    - NONATOMIC: Non-empty VCs with completed packets can accept new packets.

	localparam COMBINATION_TYPE="COMB_NONSPEC";
            //COMBINATION_TYPE : Specifies the joint VC/Switch allocator type as either speculative or non-speculative. 
            //Options are: 
            //    - SPEC: Speculative allocation.
            //    - NONSPEC: Non-speculative allocation.

	localparam MUX_TYPE="BINARY";
            //MUX_TYPE : Crossbar multiplexer type

	localparam C=0;
	localparam DEBUG_EN=0;
            //DEBUG_EN : Add extra Verilog code for debugging NoC for simulation

	localparam ADD_PIPREG_AFTER_CROSSBAR=1'b0;
            //ADD_PIPREG_AFTER_CROSSBAR : If is enabled it adds a pipeline register at the output port of the router.

	localparam FIRST_ARBITER_EXT_P_EN=1;
            //FIRST_ARBITER_EXT_P_EN : Enables switch allocator's input priority registers 
            //    only when a request gets grants from both input and output arbiters.

	localparam SWA_ARBITER_TYPE="RRA";
            //SWA_ARBITER_TYPE : Switch allocator arbitration type.
            //    - RRA: Round Robin Arbiter (local fairness only).
            //    - WRRA: Weighted Round Robin Arbiter (global fairness based on contention).
            //

	localparam WEIGHTw=4;
            //WEIGHTw : Maximum weight width

	localparam SELF_LOOP_EN=0;
            //SELF_LOOP_EN : Allows a router input port to send packets to its own output port, 
            //    enabling self-communication for tiles.

	localparam HETERO_VC=0;
            //HETERO_VC : Configures the VC (Virtual Channel) distribution across routers and ports in the NoC.
            //    0 : Uniform VC distribution. All routers in the NoC have an equal number of VCs.
            //    1 : Router-specific VC distribution. All ports in a specific router have the same number of VCs, 
            //    but different routers in the NoC can have different numbers of VCs.
            //    2 : Fully heterogeneous VC distribution. Each port in any router can have a unique number of VCs.

	localparam MAX_ROUTER=1;
	localparam MAX_PORT=1;
	localparam int VC_CONFIG_TABLE [MAX_ROUTER][MAX_PORT]='{'{0}};
            //int VC_CONFIG_TABLE [MAX_ROUTER][MAX_PORT] : Defines how a heterogeneous number of VCs are distributed in the NoC.
            //    - HETERO_VC= 0: Uniform VC configuration. All routers and ports have 
            //        the same number of VCs, and this parameter is not used.
            //    - HETERO_VC= 1,2 : Specifies the VC count in a 2D parameter array, where:
            //        * The first dimension represents the router ID.
            //        * The second dimension represents the port number.
            //    - For HETERO_VC = 1: All ports within a router have the same number of VCs, 
            //        so only the first element of each row is considered valid.
            //    - For HETERO_VC = 2: Each port in every router can have a unique VC count.

	localparam AVC_ATOMIC_EN=0;
            //AVC_ATOMIC_EN : AVC_ATOMIC_EN

	localparam CLASS_SETTING={V{1'b1}};
 	localparam  CVw=(C==0)? V : C * V;
  
	
	
	//simulation parameter	
	//localparam MAX_RATIO = 1000;
	localparam MAX_PCK_NUM = 1000000000;
	localparam MAX_PCK_SIZ = 16383; 
	localparam MAX_SIM_CLKs=  1000000000;
	localparam TIMSTMP_FIFO_NUM = 16;	
	
		

 
 `endif
