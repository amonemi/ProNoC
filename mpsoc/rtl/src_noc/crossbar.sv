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
        PP_1 = P_1 * P,
        PFw = P*Fw,
        P_1Fw = P_1 * Fw,
        P_1w = log2(P_1);
    
    input [PP_1-1 : 0] granted_dest_port_all;
    input [PFw-1 : 0] flit_in_all;
    output [PFw-1 : 0] flit_out_all;
    output [P-1 : 0] flit_out_wr_all;
    input  [P-1 : 0] ssa_flit_wr_all;
    
    wire [P-1 : 0]  flit_we_mux_out;
    wire [P_1-1 : 0] granted_dest_port [P-1 : 0];
    wire [P_1Fw-1 : 0] mux_in [P-1 : 0];
    wire [P_1-1 : 0] mux_sel_pre [P-1 : 0];
    wire [P_1-1 : 0]  mux_sel [P-1 : 0];
    wire [P_1w-1 : 0] mux_sel_bin [P-1 : 0];
    wire [P-1 : 0] flit_out_wr_gen [P-1 : 0];
    
    genvar i,j;
    generate
    for(i=0;i<P;i=i+1) begin : P_
        assign granted_dest_port[i] = granted_dest_port_all[(i+1)*P_1-1 : i*P_1];
        for(j=0;j<P;j=j+1)begin : P_ 
            if(SELF_LOOP_EN == 0) begin : nslp
                //remove sender port flit from flit list
                if(i>j)    begin 
                    assign mux_in[i][(j+1)*Fw-1 : j*Fw]=     flit_in_all[(j+1)*Fw-1 : j*Fw];
                    assign mux_sel_pre[i][j] =    granted_dest_port[j][i-1];
                end
                else if(i<j) begin 
                    assign mux_in[i][j*Fw-1 : (j-1)*Fw]=     flit_in_all[(j+1)*Fw-1 : j*Fw];
                    assign mux_sel_pre[i][j-1] =    granted_dest_port[j][i];
                end
            end else begin : slp
                assign mux_in[i][(j+1)*Fw-1 : j*Fw]=     flit_in_all[(j+1)*Fw-1 : j*Fw];
                assign mux_sel_pre[i][j] =    granted_dest_port[j][i];            
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
            onehot_mux_1D #(
                .W (Fw),
                .N (P_1)
            ) cross_mux (
                .D_in(mux_in [i]),
                .Q_out(flit_out_all[(i+1)*Fw-1 : i*Fw]),
                .sel (mux_sel[i])
            );
        end else begin : binary
            one_hot_to_bin #(
                .ONE_HOT_WIDTH(P_1),
                .BIN_WIDTH(P_1w)
            )  conv (
                .one_hot_code(mux_sel[i]),
                .bin_code(mux_sel_bin[i])
            );
            
            binary_mux #(
                .IN_WIDTH(P_1Fw),
                .OUT_WIDTH(Fw)
            ) cross_mux (
                .mux_in(mux_in [i]),
                .mux_out(flit_out_all[(i+1)*Fw-1 : i*Fw]),
                .sel(mux_sel_bin[i])
            );
        end//binary
        if(SELF_LOOP_EN == 0) begin : nslp
            add_sw_loc_one_hot #(
                .P(P),
                .SW_LOC(i)
            ) add_sw_loc (
                .destport_in(granted_dest_port_all[(i+1)*P_1-1 : i*P_1]),
                .destport_out(flit_out_wr_gen [i])
            );
        end else begin :slp
            assign flit_out_wr_gen [i] = granted_dest_port_all[(i+1)*P_1-1 : i*P_1];
        end
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