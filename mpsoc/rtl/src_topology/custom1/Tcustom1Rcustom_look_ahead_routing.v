
/**************************************************************************
**    WARNING: THIS IS AN AUTO-GENERATED FILE. CHANGES TO IT ARE LIKELY TO BE
**    OVERWRITTEN AND LOST. Rename this file if you wish to do any modification.
****************************************************************************/


/**********************************************************************
**    File: /home/alireza/work/git/hca_git/git-hub/ProNoC/mpsoc/rtl/src_topology/custom1/Tcustom1Rcustom_look_ahead_routing.v
**    
**    Copyright (C) 2014-2022  Alireza Monemi
**    
**    This file is part of ProNoC 2.2.0 
**
**    ProNoC ( stands for Prototype Network-on-chip)  is free software: 
**    you can redistribute it and/or modify it under the terms of the GNU
**    Lesser General Public License as published by the Free Software Foundation,
**    either version 2 of the License, or (at your option) any later version.
**
**     ProNoC is distributed in the hope that it will be useful, but WITHOUT
**     ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
**     or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General
**     Public License for more details.
**
**     You should have received a copy of the GNU Lesser General Public
**     License along with ProNoC. If not, see <http:**www.gnu.org/licenses/>.
******************************************************************************/ 

    
`include "pronoc_def.v"
/*******************
*  Tcustom1Rcustom_look_ahead_routing
*******************/  
module Tcustom1Rcustom_look_ahead_routing  #(
    parameter RAw = 3,  
    parameter EAw = 3,   
    parameter DSTPw=4  
)(
    reset,
    clk,
    current_r_addr,
    dest_e_addr,
    src_e_addr,
    destport
);
    input   [RAw-1   :0] current_r_addr;
    input   [EAw-1   :0] dest_e_addr;
    input   [EAw-1   :0] src_e_addr;
    output  [DSTPw-1 :0] destport;    
    input reset,clk;
    reg [EAw-1   :0] dest_e_addr_delay;
    reg [EAw-1   :0] src_e_addr_delay;
    
    always @ (`pronoc_clk_reset_edge )begin 
        if(`pronoc_reset)begin 
            dest_e_addr_delay<={EAw{1'b0}};
            src_e_addr_delay<={EAw{1'b0}};
        end else begin 
            dest_e_addr_delay<=dest_e_addr;
            src_e_addr_delay<=src_e_addr;
        end     
    end
    
    Tcustom1Rcustom_look_ahead_routing_comb  #(
        .RAw(RAw),  
        .EAw(EAw),   
        .DSTPw(DSTPw)  
    ) lkp_cmb  (
        .current_r_addr(current_r_addr),
        .dest_e_addr(dest_e_addr_delay),
        .src_e_addr(src_e_addr_delay),
        .destport(destport)        
    );
endmodule  

/*******************
*  Tcustom1Rcustom_look_ahead_routing_comb
*******************/ 
module Tcustom1Rcustom_look_ahead_routing_comb  #(
    parameter RAw = 3,  
    parameter EAw = 3,   
    parameter DSTPw=4  
)(
    current_r_addr,
    dest_e_addr,
    src_e_addr,
    destport
);
    input   [RAw-1   :0] current_r_addr;
    input   [EAw-1   :0] dest_e_addr;
    input   [EAw-1   :0] src_e_addr;
    output reg [DSTPw-1 :0] destport;    

localparam [EAw-1 : 0]    E0=0;
localparam [EAw-1 : 0]    E1=1;
localparam [EAw-1 : 0]    E2=2;
localparam [EAw-1 : 0]    E3=3;
localparam [EAw-1 : 0]    E4=4;
localparam [EAw-1 : 0]    E5=5;
localparam [EAw-1 : 0]    E6=6;
localparam [EAw-1 : 0]    E7=7;
localparam [EAw-1 : 0]    E8=8;
localparam [EAw-1 : 0]    E9=9;
localparam [EAw-1 : 0]    E10=10;
localparam [EAw-1 : 0]    E11=11;
localparam [EAw-1 : 0]    E12=12;
localparam [EAw-1 : 0]    E13=13;
localparam [EAw-1 : 0]    E14=14;
localparam [EAw-1 : 0]    E15=15;


    always@(*)begin
        destport=0;
        case(current_r_addr) //current_r_addr of each individual router is fixed. So this CASE will be optimized by the synthesizer for each router. 
        0: begin
            case({src_e_addr,dest_e_addr})
            {E0,E9},{E0,E10}: begin 
                destport= 0; 
            end
            {E0,E2},{E0,E3},{E0,E8},{E0,E11},{E0,E12}: begin 
                destport= 1; 
            end
            {E0,E1},{E0,E4},{E0,E5},{E0,E6},{E0,E7},{E0,E13},{E0,E14},{E0,E15}: begin 
                destport= 2; 
            end
            default: begin 
                destport= {DSTPw{1'bX}};
            end
            endcase
        end//0
        1: begin
            case({src_e_addr,dest_e_addr})
            {E1,E2},{E1,E7},{E2,E7}: begin 
                destport= 0; 
            end
            {E1,E3},{E1,E4},{E1,E5},{E1,E6},{E1,E8},{E1,E9},{E1,E11},{E1,E12},{E1,E13},{E1,E14},{E1,E15},{E2,E9},{E2,E12}: begin 
                destport= 1; 
            end
            {E1,E0},{E1,E10},{E2,E0},{E2,E10}: begin 
                destport= 2; 
            end
            default: begin 
                destport= {DSTPw{1'bX}};
            end
            endcase
        end//1
        2: begin
            case({src_e_addr,dest_e_addr})
            {E1,E11},{E2,E1},{E2,E11}: begin 
                destport= 0; 
            end
            {E1,E5},{E1,E6},{E1,E13},{E1,E14},{E2,E0},{E2,E4},{E2,E5},{E2,E6},{E2,E7},{E2,E8},{E2,E9},{E2,E10},{E2,E12},{E2,E13},{E2,E14},{E2,E15}: begin 
                destport= 1; 
            end
            {E1,E3},{E2,E3}: begin 
                destport= 3; 
            end
            default: begin 
                destport= {DSTPw{1'bX}};
            end
            endcase
        end//2
        3: begin
            case({src_e_addr,dest_e_addr})
            {E3,E4},{E3,E11}: begin 
                destport= 0; 
            end
            {E3,E1},{E3,E6},{E3,E7},{E3,E8},{E3,E10},{E3,E12},{E3,E13},{E3,E14}: begin 
                destport= 1; 
            end
            {E3,E2}: begin 
                destport= 2; 
            end
            {E3,E0},{E3,E5},{E3,E9},{E3,E15}: begin 
                destport= 3; 
            end
            default: begin 
                destport= {DSTPw{1'bX}};
            end
            endcase
        end//3
        4: begin
            case({src_e_addr,dest_e_addr})
            {E3,E13},{E4,E3},{E4,E13},{E5,E3},{E6,E3},{E7,E3},{E8,E3},{E9,E3},{E10,E3},{E12,E3},{E13,E3},{E14,E3},{E15,E3}: begin 
                destport= 0; 
            end
            {E4,E2},{E4,E11},{E4,E14}: begin 
                destport= 1; 
            end
            {E3,E0},{E3,E5},{E3,E9},{E3,E15},{E4,E0},{E4,E5},{E4,E9},{E4,E12},{E4,E15}: begin 
                destport= 2; 
            end
            {E3,E6},{E4,E6}: begin 
                destport= 3; 
            end
            {E3,E1},{E3,E7},{E3,E8},{E3,E14},{E4,E1},{E4,E7},{E4,E8},{E4,E10}: begin 
                destport= 4; 
            end
            default: begin 
                destport= {DSTPw{1'bX}};
            end
            endcase
        end//4
        5: begin
            case({src_e_addr,dest_e_addr})
            {E0,E6},{E0,E15},{E3,E9},{E3,E15},{E4,E9},{E4,E15},{E5,E6},{E5,E9},{E5,E15},{E6,E9},{E6,E15},{E9,E6},{E9,E15},{E13,E9},{E14,E9},{E15,E9}: begin 
                destport= 0; 
            end
            {E0,E4},{E0,E13},{E4,E12},{E5,E1},{E5,E2},{E5,E3},{E5,E4},{E5,E7},{E5,E8},{E5,E10},{E5,E12},{E5,E13},{E5,E14},{E6,E1},{E6,E7},{E6,E8},{E6,E10},{E6,E12},{E9,E3},{E9,E4},{E9,E13},{E9,E14}: begin 
                destport= 1; 
            end
            {E0,E14},{E5,E11},{E6,E2},{E6,E11},{E6,E14},{E9,E2},{E9,E11}: begin 
                destport= 2; 
            end
            {E3,E0},{E4,E0},{E5,E0},{E6,E0},{E11,E0},{E13,E0},{E15,E0}: begin 
                destport= 3; 
            end
            default: begin 
                destport= {DSTPw{1'bX}};
            end
            endcase
        end//5
        6: begin
            case({src_e_addr,dest_e_addr})
            {E0,E13},{E3,E5},{E4,E5},{E5,E13},{E6,E5},{E6,E13},{E9,E13}: begin 
                destport= 0; 
            end
            {E3,E15},{E4,E12},{E4,E15},{E6,E1},{E6,E2},{E6,E7},{E6,E8},{E6,E10},{E6,E11},{E6,E12},{E6,E14},{E6,E15}: begin 
                destport= 1; 
            end
            {E0,E4},{E5,E3},{E5,E4},{E6,E3},{E6,E4},{E9,E3},{E9,E4}: begin 
                destport= 2; 
            end
            {E3,E0},{E3,E9},{E4,E0},{E4,E9},{E6,E0},{E6,E9}: begin 
                destport= 3; 
            end
            {E4,E2},{E4,E11},{E4,E14},{E5,E2},{E5,E14},{E9,E14}: begin 
                destport= 4; 
            end
            default: begin 
                destport= {DSTPw{1'bX}};
            end
            endcase
        end//6
        7: begin
            case({src_e_addr,dest_e_addr})
            {E0,E1},{E1,E8},{E1,E10},{E2,E10},{E3,E1},{E3,E10},{E4,E1},{E4,E10},{E5,E1},{E6,E1},{E7,E1},{E7,E8},{E7,E10},{E8,E1},{E9,E1},{E10,E1},{E11,E1},{E11,E10},{E12,E1},{E13,E1},{E13,E10},{E14,E1},{E14,E10},{E15,E1}: begin 
                destport= 0; 
            end
            {E1,E9},{E1,E12},{E1,E15},{E2,E9},{E2,E12},{E7,E9},{E7,E12}: begin 
                destport= 1; 
            end
            {E1,E4},{E7,E2},{E7,E3},{E7,E4},{E7,E5},{E7,E6},{E7,E11},{E7,E13},{E7,E14},{E7,E15}: begin 
                destport= 2; 
            end
            {E1,E0},{E2,E0},{E7,E0},{E14,E0}: begin 
                destport= 3; 
            end
            default: begin 
                destport= {DSTPw{1'bX}};
            end
            endcase
        end//7
        8: begin
            case({src_e_addr,dest_e_addr})
            {E1,E12},{E2,E12},{E3,E7},{E4,E7},{E7,E12},{E7,E14},{E8,E7},{E8,E12},{E8,E14},{E9,E7},{E11,E7},{E13,E7},{E14,E7}: begin 
                destport= 0; 
            end
            {E1,E15},{E7,E5},{E7,E15},{E8,E4},{E8,E5},{E8,E15}: begin 
                destport= 1; 
            end
            {E1,E4},{E1,E9},{E2,E9},{E3,E10},{E4,E10},{E7,E3},{E7,E4},{E7,E6},{E7,E9},{E7,E13},{E8,E0},{E8,E3},{E8,E6},{E8,E9},{E8,E13},{E11,E10},{E13,E10},{E14,E0},{E14,E10}: begin 
                destport= 2; 
            end
            {E3,E1},{E4,E1},{E8,E1},{E8,E10},{E9,E1},{E11,E1},{E13,E1},{E14,E1}: begin 
                destport= 3; 
            end
            {E7,E2},{E7,E11},{E8,E2},{E8,E11}: begin 
                destport= 4; 
            end
            default: begin 
                destport= {DSTPw{1'bX}};
            end
            endcase
        end//8
        9: begin
            case({src_e_addr,dest_e_addr})
            {E0,E5},{E0,E12},{E3,E0},{E4,E0},{E5,E0},{E6,E0},{E8,E0},{E9,E0},{E9,E5},{E9,E12},{E11,E0},{E12,E0},{E13,E0},{E15,E0}: begin 
                destport= 0; 
            end
            {E0,E11},{E0,E14},{E0,E15},{E9,E2},{E9,E11},{E9,E15}: begin 
                destport= 1; 
            end
            {E0,E4},{E0,E6},{E0,E13},{E9,E3},{E9,E4},{E9,E6},{E9,E13},{E9,E14}: begin 
                destport= 2; 
            end
            {E9,E10}: begin 
                destport= 3; 
            end
            {E0,E8},{E9,E1},{E9,E7},{E9,E8}: begin 
                destport= 4; 
            end
            default: begin 
                destport= {DSTPw{1'bX}};
            end
            endcase
        end//9
        10: begin
            case({src_e_addr,dest_e_addr})
            {E0,E7},{E1,E0},{E2,E0},{E5,E7},{E6,E7},{E7,E0},{E10,E0},{E10,E7},{E10,E12},{E12,E7},{E14,E0},{E15,E7}: begin 
                destport= 0; 
            end
            {E0,E2},{E0,E3},{E10,E2},{E10,E3},{E10,E4},{E10,E5},{E10,E6},{E10,E11},{E10,E13},{E10,E14},{E10,E15}: begin 
                destport= 1; 
            end
            {E10,E9}: begin 
                destport= 2; 
            end
            {E0,E1},{E5,E1},{E6,E1},{E10,E1},{E12,E1},{E15,E1}: begin 
                destport= 3; 
            end
            {E10,E8}: begin 
                destport= 4; 
            end
            default: begin 
                destport= {DSTPw{1'bX}};
            end
            endcase
        end//10
        11: begin
            case({src_e_addr,dest_e_addr})
            {E0,E2},{E0,E3},{E1,E3},{E1,E14},{E2,E3},{E2,E14},{E3,E2},{E4,E2},{E5,E2},{E6,E2},{E7,E2},{E8,E2},{E9,E2},{E10,E2},{E11,E2},{E11,E3},{E11,E14},{E12,E2},{E13,E2},{E14,E2},{E15,E2}: begin 
                destport= 0; 
            end
            {E1,E5},{E1,E13},{E2,E5},{E2,E15},{E3,E12},{E11,E0},{E11,E5},{E11,E9},{E11,E12},{E11,E15}: begin 
                destport= 1; 
            end
            {E1,E6},{E2,E4},{E2,E6},{E2,E13},{E11,E4},{E11,E6},{E11,E13}: begin 
                destport= 2; 
            end
            {E2,E8},{E3,E10},{E11,E1},{E11,E7},{E11,E8},{E11,E10}: begin 
                destport= 3; 
            end
            default: begin 
                destport= {DSTPw{1'bX}};
            end
            endcase
        end//11
        12: begin
            case({src_e_addr,dest_e_addr})
            {E0,E8},{E1,E9},{E1,E15},{E2,E9},{E5,E8},{E5,E10},{E6,E8},{E6,E10},{E7,E9},{E8,E9},{E8,E10},{E9,E8},{E9,E10},{E10,E8},{E10,E9},{E10,E15},{E11,E9},{E12,E8},{E12,E9},{E12,E10},{E12,E15},{E15,E8},{E15,E10}: begin 
                destport= 0; 
            end
            {E0,E2},{E0,E3},{E0,E11},{E5,E1},{E5,E7},{E6,E1},{E6,E7},{E10,E2},{E10,E11},{E10,E14},{E12,E1},{E12,E2},{E12,E7},{E12,E11},{E12,E14},{E15,E1},{E15,E7}: begin 
                destport= 2; 
            end
            {E8,E0},{E8,E4},{E9,E1},{E9,E7},{E10,E3},{E10,E4},{E10,E6},{E10,E13},{E12,E0},{E12,E3},{E12,E4},{E12,E6},{E12,E13}: begin 
                destport= 3; 
            end
            {E8,E5},{E10,E5},{E12,E5}: begin 
                destport= 4; 
            end
            default: begin 
                destport= {DSTPw{1'bX}};
            end
            endcase
        end//12
        13: begin
            case({src_e_addr,dest_e_addr})
            {E0,E4},{E1,E4},{E1,E6},{E2,E4},{E2,E6},{E3,E6},{E3,E14},{E4,E6},{E4,E14},{E5,E4},{E5,E14},{E6,E4},{E7,E4},{E7,E6},{E8,E4},{E8,E6},{E9,E4},{E9,E14},{E10,E4},{E10,E6},{E11,E4},{E11,E6},{E12,E4},{E12,E6},{E13,E4},{E13,E6},{E13,E14},{E14,E4},{E14,E6},{E15,E4},{E15,E6}: begin 
                destport= 0; 
            end
            {E13,E0},{E13,E5},{E13,E9},{E13,E12},{E13,E15}: begin 
                destport= 1; 
            end
            {E5,E3},{E6,E3},{E7,E3},{E8,E3},{E9,E3},{E10,E3},{E12,E3},{E13,E3},{E14,E3},{E15,E3}: begin 
                destport= 2; 
            end
            {E3,E1},{E3,E7},{E3,E8},{E4,E1},{E4,E7},{E4,E8},{E4,E10},{E13,E1},{E13,E7},{E13,E8},{E13,E10}: begin 
                destport= 3; 
            end
            {E4,E2},{E4,E11},{E5,E2},{E13,E2},{E13,E11}: begin 
                destport= 4; 
            end
            default: begin 
                destport= {DSTPw{1'bX}};
            end
            endcase
        end//13
        14: begin
            case({src_e_addr,dest_e_addr})
            {E0,E11},{E2,E8},{E2,E13},{E2,E15},{E3,E8},{E4,E8},{E4,E11},{E5,E11},{E6,E11},{E7,E11},{E7,E13},{E7,E15},{E8,E11},{E8,E13},{E8,E15},{E9,E11},{E10,E11},{E11,E8},{E11,E13},{E11,E15},{E12,E11},{E13,E8},{E13,E11},{E13,E15},{E14,E8},{E14,E11},{E14,E13},{E14,E15},{E15,E11}: begin 
                destport= 0; 
            end
            {E3,E12},{E11,E9},{E11,E12},{E13,E12},{E14,E12}: begin 
                destport= 1; 
            end
            {E0,E2},{E1,E4},{E2,E4},{E4,E2},{E5,E2},{E6,E2},{E7,E2},{E7,E3},{E7,E4},{E8,E2},{E8,E3},{E9,E2},{E10,E2},{E11,E4},{E12,E2},{E13,E2},{E14,E2},{E14,E3},{E14,E4},{E15,E2}: begin 
                destport= 2; 
            end
            {E0,E3},{E1,E6},{E1,E13},{E2,E6},{E3,E1},{E3,E7},{E3,E10},{E4,E1},{E4,E7},{E4,E10},{E7,E6},{E8,E6},{E11,E1},{E11,E6},{E11,E7},{E11,E10},{E13,E1},{E13,E7},{E13,E10},{E14,E0},{E14,E1},{E14,E6},{E14,E7},{E14,E10}: begin 
                destport= 3; 
            end
            {E1,E5},{E2,E5},{E7,E5},{E11,E0},{E11,E5},{E13,E0},{E13,E5},{E13,E9},{E14,E5},{E14,E9}: begin 
                destport= 4; 
            end
            default: begin 
                destport= {DSTPw{1'bX}};
            end
            endcase
        end//14
        15: begin
            case({src_e_addr,dest_e_addr})
            {E0,E14},{E1,E5},{E1,E13},{E2,E5},{E3,E12},{E4,E12},{E5,E12},{E6,E12},{E6,E14},{E7,E5},{E8,E5},{E10,E5},{E10,E13},{E10,E14},{E11,E5},{E11,E12},{E12,E5},{E12,E13},{E12,E14},{E13,E5},{E13,E12},{E14,E5},{E14,E12},{E15,E5},{E15,E12},{E15,E13},{E15,E14}: begin 
                destport= 0; 
            end
            {E8,E4},{E10,E3},{E10,E4},{E11,E9},{E12,E3},{E12,E4},{E15,E3},{E15,E4}: begin 
                destport= 2; 
            end
            {E5,E1},{E5,E7},{E5,E10},{E6,E1},{E6,E7},{E6,E10},{E10,E6},{E11,E0},{E12,E6},{E13,E0},{E13,E9},{E14,E9},{E15,E0},{E15,E1},{E15,E6},{E15,E7},{E15,E9},{E15,E10}: begin 
                destport= 3; 
            end
            {E0,E2},{E0,E3},{E0,E11},{E5,E8},{E5,E11},{E6,E2},{E6,E8},{E6,E11},{E9,E2},{E9,E11},{E10,E2},{E10,E11},{E12,E2},{E12,E11},{E15,E2},{E15,E8},{E15,E11}: begin 
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
