/*********************************************************************
							
	File: wb_master.v 
	
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
	generating the wishbone bus. 

	Info: monemi@fkegraduate.utm.my

****************************************************************/







module wb_master_socket #(
		
	
	parameter Dw     =	32,	   // maximum data width
	parameter Aw  	 =	32,    // address width
	parameter SELw   =	2,
	parameter TAGw   =	3 ,   //merged  {tga,tgb,tgc}
	parameter CTIw   =   3,
	parameter BTEw   =   2 
  
		
)
(
	
									
	
	//masters interface
	output  [Dw-1      :   0]   dat_o,
	output  		    ack_o,
	output  		    err_o,
	output  		    rty_o,
    
    
	input   [Aw-1      :   0]   adr_i,
	input   [Dw-1      :   0]   dat_i,
	input   [SELw-1    :   0]   sel_i,
	input   [TAGw-1    :   0]   tag_i,
	input   		    we_i,
	input  			    stb_i,
	input 			    cyc_i,
	input   [CTIw-1	   :	0]  cti_i,
	input   [BTEw-1	   :	0]  bte_i
	
	//address compar
	//m_grant_addr,
    //s_sel_one_hot,
	
	
	
	
);

   


endmodule







module wb_slave_socket #(
		
	
	parameter Dw  =	32,	   // maximum data width
	parameter Aw  =	32,    // address width
	parameter SELw   =	2,
	parameter TAGw   =	3,   //merged  {tga,tgb,tgc}
	parameter CTIw   =   3,
	parameter BTEw   =   2 
  
		
)
(



    output  [Aw-1      :   0]   adr_o,
    output  [Dw-1      :   0]   dat_o,
    output  [SELw-1    :   0]   sel_o,
    output  [TAGw-1    :   0]   tag_o,
    output  			we_o,
    output			cyc_o,
    output     			stb_o,
    output   [CTIw-1   :   0]  cti_o,
    output   [BTEw-1   :   0]  bte_o,
    
    
    input   [DwS-1      :   0]   dat_i,
    input      ack_i,
    input      err_i,
    input      rty_i

);

endmodule 


module clk_socket(
	output clk_o

);

endmodule

module reset_socket(
	output reset_o

);

endmodule






