
/**********************************************************************
**	File: Top.v
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
 
module Top (
	FPGA_CLK1_50,
	KEY
);
 	 input 			 FPGA_CLK1_50;
 	 input 	[1 : 0]	 KEY;


	ram_test_top uut(	
 	  .ss_clk_in( FPGA_CLK1_50  ),
 	  .ss_reset_in(~ KEY [ 0])
	);


endmodule
