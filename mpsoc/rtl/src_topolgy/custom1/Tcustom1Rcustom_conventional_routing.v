
/**************************************************************************
**	WARNING: THIS IS AN AUTO-GENERATED FILE. CHANGES TO IT ARE LIKELY TO BE
**	OVERWRITTEN AND LOST. Rename this file if you wish to do any modification.
****************************************************************************/


/**********************************************************************
**	File: /home/alireza/work/git/hca_git/ProNoC/mpsoc/rtl/src_topolgy/custom1/Tcustom1Rcustom_conventional_routing.v
**    
**	Copyright (C) 2014-2019  Alireza Monemi
**    
**	This file is part of ProNoC 1.9.1 
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
module Tcustom1Rcustom_conventional_routing  #(
	parameter RAw = 3,  
	parameter EAw = 3,   
	parameter DSTPw=4  
)
(
	dest_e_addr,
	src_e_addr,
	destport        
);
    
	input   [EAw-1   :0] dest_e_addr;
	input   [EAw-1   :0] src_e_addr;
	output reg [DSTPw-1 :0] destport;	
        
    
	always@(*)begin
		destport=0;
		case(src_e_addr) //source address of each individual NI is fixed. So this CASE will be optimized by the synthesizer for each endpoint. 
		0: begin
			case(dest_e_addr)
			1,2,3,7,10: begin 
				destport= 1; 
			end
			4,5,6,8,9,11,12,13,14,15: begin 
				destport= 2; 
			end

			default: begin 
				destport= {DSTPw{1'bX}};
			end
			endcase
		end//0
		1: begin
			case(dest_e_addr)
			0,4,7,8,9,10,12,15: begin 
				destport= 1; 
			end
			2,3,5,6,11,13,14: begin 
				destport= 2; 
			end

			default: begin 
				destport= {DSTPw{1'bX}};
			end
			endcase
		end//1
		2: begin
			case(dest_e_addr)
			3,4,5,6,8,11,13,14,15: begin 
				destport= 1; 
			end
			0,1,7,9,10,12: begin 
				destport= 2; 
			end

			default: begin 
				destport= {DSTPw{1'bX}};
			end
			endcase
		end//2
		3: begin
			case(dest_e_addr)
			2,10,11,12: begin 
				destport= 1; 
			end
			0,1,4,5,6,7,8,9,13,14,15: begin 
				destport= 2; 
			end

			default: begin 
				destport= {DSTPw{1'bX}};
			end
			endcase
		end//3
		4: begin
			case(dest_e_addr)
			1,6,7,8,10,13: begin 
				destport= 1; 
			end
			3: begin 
				destport= 2; 
			end
			0,2,5,9,11,12,14,15: begin 
				destport= 3; 
			end

			default: begin 
				destport= {DSTPw{1'bX}};
			end
			endcase
		end//4
		5: begin
			case(dest_e_addr)
			1,7,8,10,11,12,15: begin 
				destport= 1; 
			end
			2,3,4,6,13,14: begin 
				destport= 2; 
			end
			0,9: begin 
				destport= 3; 
			end

			default: begin 
				destport= {DSTPw{1'bX}};
			end
			endcase
		end//5
		6: begin
			case(dest_e_addr)
			3,4,13: begin 
				destport= 1; 
			end
			0,1,2,5,7,8,9,10,11,12,14,15: begin 
				destport= 2; 
			end

			default: begin 
				destport= {DSTPw{1'bX}};
			end
			endcase
		end//6
		7: begin
			case(dest_e_addr)
			2,3,4,5,6,8,9,11,12,13,14,15: begin 
				destport= 1; 
			end
			0,10: begin 
				destport= 2; 
			end
			1: begin 
				destport= 3; 
			end

			default: begin 
				destport= {DSTPw{1'bX}};
			end
			endcase
		end//7
		8: begin
			case(dest_e_addr)
			0,4,5,9,10,12: begin 
				destport= 1; 
			end
			2,3,6,11,13,14,15: begin 
				destport= 2; 
			end
			1,7: begin 
				destport= 3; 
			end

			default: begin 
				destport= {DSTPw{1'bX}};
			end
			endcase
		end//8
		9: begin
			case(dest_e_addr)
			1,7,8,10,12: begin 
				destport= 1; 
			end
			2,3,4,5,6,11,13,14,15: begin 
				destport= 2; 
			end
			0: begin 
				destport= 3; 
			end

			default: begin 
				destport= {DSTPw{1'bX}};
			end
			endcase
		end//9
		10: begin
			case(dest_e_addr)
			2,3,4,5,6,8,9,11,12,13,14,15: begin 
				destport= 1; 
			end
			1,7: begin 
				destport= 2; 
			end
			0: begin 
				destport= 3; 
			end

			default: begin 
				destport= {DSTPw{1'bX}};
			end
			endcase
		end//10
		11: begin
			case(dest_e_addr)
			0,1,4,5,6,7,8,9,10,12,13,14,15: begin 
				destport= 1; 
			end
			2: begin 
				destport= 2; 
			end
			3: begin 
				destport= 3; 
			end

			default: begin 
				destport= {DSTPw{1'bX}};
			end
			endcase
		end//11
		12: begin
			case(dest_e_addr)
			2,3,4,5,6,11,13,14,15: begin 
				destport= 1; 
			end
			0,9: begin 
				destport= 2; 
			end
			1,7,10: begin 
				destport= 3; 
			end
			8: begin 
				destport= 4; 
			end

			default: begin 
				destport= {DSTPw{1'bX}};
			end
			endcase
		end//12
		13: begin
			case(dest_e_addr)
			3,4: begin 
				destport= 2; 
			end
			6: begin 
				destport= 3; 
			end
			0,1,2,5,7,8,9,10,11,12,14,15: begin 
				destport= 4; 
			end

			default: begin 
				destport= {DSTPw{1'bX}};
			end
			endcase
		end//13
		14: begin
			case(dest_e_addr)
			5,9,12,15: begin 
				destport= 1; 
			end
			3,4,6,13: begin 
				destport= 2; 
			end
			0,1,7,8,10: begin 
				destport= 3; 
			end
			2,11: begin 
				destport= 4; 
			end

			default: begin 
				destport= {DSTPw{1'bX}};
			end
			endcase
		end//14
		15: begin
			case(dest_e_addr)
			1,7,8,10,12: begin 
				destport= 1; 
			end
			2,11,14: begin 
				destport= 2; 
			end
			3,4,6,13: begin 
				destport= 3; 
			end
			0,5,9: begin 
				destport= 4; 
			end

			default: begin 
				destport= {DSTPw{1'bX}};
			end
			endcase
		end//15

		default: begin 
			destport= {DSTPw{1'bX}};
		end
		endcase
	end

		
	
endmodule  
    
