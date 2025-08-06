`include "pronoc_def.v"
/**********************************************************************
**    File: crossbar.v
**    
**    Copyright (C) 2014-2017  Alireza Monemi
**    
**    This file is part of ProNoC 
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
**
**
**    Description: 
**    NoC router crosbar module
**
**************************************************************/

module crossbar #(
    parameter P = 5// router port num
)(
    granted_dest_port_all,
    flit_in_all,
    flit_out_all,
    flit_out_wr_all,
    ssa_flit_wr_all
);
    import pronoc_pkg::*;
    
    localparam 
        P_1 = (SELF_LOOP_EN )?  P : P-1,
        P_1w = log2(P_1);
    
    input [P_1-1 : 0] granted_dest_port_all[P-1 : 0];
    input [Fw-1 : 0] flit_in_all[P-1 : 0];
    output logic [Fw-1 : 0] flit_out_all [P-1 : 0];
    output [P-1 : 0] flit_out_wr_all;
    input  [P-1 : 0] ssa_flit_wr_all;
    
    wire [P-1 : 0]  flit_we_mux_out;
    wire [Fw-1 : 0] mux_in [P-1 : 0][P_1-1 : 0];
    wire [P_1-1 : 0] mux_sel_pre [P-1 : 0];
    wire [P_1-1 : 0]  mux_sel [P-1 : 0];
    logic [P_1w-1 : 0] mux_sel_bin [P-1 : 0];
    logic [P-1 : 0] flit_out_wr_gen [P-1 : 0];
    
    //one_hot_to_bin
    always_comb begin
        for(int m=0;m<P;m++) begin
            mux_sel_bin[m] = '0;
            for (int k = 0; k < P_1; k++) begin
                if (mux_sel[m][k]) mux_sel_bin[m] = P_1w'(k);
            end
        end
    end
    
    //add_sw_loc_one_hot 
    always_comb begin 
        for(int m=0;m< P;m++) begin 
            if (SELF_LOOP_EN == 0) begin
                for(int k=0;k<P; k++) begin 
                    if (k>m) flit_out_wr_gen[m][k] = granted_dest_port_all[m][k-1];
                    else if (k==m) flit_out_wr_gen[m][k] = 1'b0;
                    else flit_out_wr_gen[m][k] = granted_dest_port_all[m][k];
                end//for 
            end else flit_out_wr_gen[m][P_1-1 : 0] = granted_dest_port_all[m];
        end//for
    end//always
    
    genvar i,j;
    generate
    for(i=0;i<P;i=i+1) begin : P_
        for(j=0;j<P;j=j+1)begin : P_ 
            if(SELF_LOOP_EN == 0) begin : nslp
                //remove sender port flit from flit list
                if(i>j)    begin 
                    assign mux_in[i][j] = flit_in_all[j];
                    assign mux_sel_pre[i][j] = granted_dest_port_all[j][i-1];
                end
                else if(i<j) begin 
                    assign mux_in[i][j-1] = flit_in_all[j];
                    assign mux_sel_pre[i][j-1] = granted_dest_port_all[j][i];
                end
            end else begin : slp
                assign mux_in[i][j] = flit_in_all[j];
                assign mux_sel_pre[i][j] = granted_dest_port_all[j][i];            
            end
        end//for j
        
        if (SSA_EN) begin : predict //If no output is granted replace the output port with SS port
            add_ss_port #(
                .SW_LOC(i),
                .P(P)
            ) ss_port (
                .destport_in (mux_sel_pre[i]),
                .destport_out(mux_sel [i])
            );        
        end else begin : nopredict
            assign mux_sel[i]= mux_sel_pre[i];
        end
        if (IS_ONE_HOT_MUX) begin : one_hot_gen
            // One-hot mux
            always_comb begin
                flit_out_all[i] = {Fw{1'b0}};
                for (int k = 0; k < P_1; k++)
                    flit_out_all[i] |= (mux_sel[i][k]) ?  mux_in[i][k] : {Fw{1'b0}};
            end
        end else begin : binary
            assign flit_out_all[i]= mux_in[i][mux_sel_bin[i]];
        end//binary
    end//for i
    endgenerate
    reduction_or #(
        .W(P),
        .N(P)
    ) wide_or (
        .D_in(flit_out_wr_gen),
        .Q_out(flit_we_mux_out)
    );
    assign flit_out_wr_all = flit_we_mux_out | ssa_flit_wr_all;
endmodule
