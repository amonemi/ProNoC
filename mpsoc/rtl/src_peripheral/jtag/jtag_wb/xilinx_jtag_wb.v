/**********************************************************************
**  File:  xilinx_jtag_wb.v 
**  
**    
**  Copyright (C) 2020  Alireza Monemi
**    
**  This file is part of ProNoC 
**
**  ProNoC ( stands for Prototype Network-on-chip)  is free software: 
**  you can redistribute it and/or modify it under the terms of the GNU
**  Lesser General Public License as published by the Free Software Foundation,
**  either version 2 of the License, or (at your option) any later version.
**
**  ProNoC is distributed in the hope that it will be useful, but WITHOUT
**  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
**  or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General
**  Public License for more details.
**
**  You should have received a copy of the GNU Lesser General Public
**  License along with ProNoC. If not, see <http:**www.gnu.org/licenses/>.
**
**
**  Description: 
**  xilinx bscan chain to wishbon bus interface. It prvide simple read/write on 
**  whishbone bus. Does not support burst transaction.
**
*******************************************************************/


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

module xilinx_jtag_wb #(
    parameter JTAG_CHAIN=4, // Only used for Virtex 4/5 devices. May be 1, 2, 3, or 4
    parameter JWB_NUM=1,
    parameter JDw=32,
    parameter JAw=32,
    parameter JINDEXw=8,
    parameter JSTATUSw=8,
    parameter CTRL_REG_INDEX =127

)(
   // clk, get the clock from wb interface
    reset,
    cpu_en,
    system_reset,
    wb_to_jtag_all,
    jtag_to_wb_all
);

     function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end       
      end   
    endfunction // log2 

    localparam  J2WBw= 1+1+JDw+JAw;
    localparam  WB2Jw=1+JSTATUSw+JINDEXw+1+JDw;
    
    input reset;//,clk;
    output reg cpu_en, system_reset;
    
   // output [7: 0 ] Q_out;
    
    input [JWB_NUM*WB2Jw-1  : 0] wb_to_jtag_all;
    output[JWB_NUM*J2WBw-1 : 0] jtag_to_wb_all; 
    
    wire  [J2WBw-1  : 0] jtag_to_wb [JWB_NUM-1 : 0];
    wire  [WB2Jw-1  : 0] wb_to_jtag [JWB_NUM-1 : 0];   
    wire  [JINDEXw-1 : 0] wb_to_jtag_index_all[JWB_NUM-1 : 0];
    //wire  [JDw-1 : 0] wb_to_jtag_dat_all [JWB_NUM-1 : 0];
    wire  [JDw*JWB_NUM-1 : 0] wb_to_jtag_dat_all;
    wire  [JDw*JWB_NUM-1 : 0] wb_to_jtag_dat_all_latched;
    wire  [JWB_NUM-1 : 0] wb_to_jtag_ack_all;
    wire  [JWB_NUM-1 : 0] wb_to_jtag_ack_all_latched;
    wire  [JSTATUSw-1 : 0] wb_to_jtag_status_all [JWB_NUM-1 : 0];
    
    wire  [JINDEXw-1 : 0] jtag_to_wb_index;
    wire  [JWB_NUM-1: 0] jtag_sel_onehot;
    wire  [WB2Jw-1  : 0] wb_to_jtag_mux;
    wire  [JWB_NUM-1: 0] stb_all;    

    wire [JSTATUSw-1    : 0] wb_to_jtag_status;
    wire [JDw-1 : 0] wb_to_jtag_dat; 
    wire wb_to_jtag_ack;
    
    wire [JDw-1 : 0] jtag_to_wb_dat;
    wire [JAw-1 : 0] jtag_to_wb_addr;
    reg  [JAw-1 : 0] jtag_to_wb_addr_reg;
    wire jtag_to_wb_stb;
    wire jtag_to_wb_we;
    wire [JWB_NUM-1 : 0] wb_to_jtag_clk;
    
    wire tclk;//jtag clk
    wire clk = wb_to_jtag_clk[0];
    
    wire [JWB_NUM-1 : 0] stb_masked_all; 
    
    reg  [JDw-1 : 0] jtag_dat_in_reg  [JWB_NUM-1: 0];
    
    reg jtag_to_wb_stb_reg;
    reg [JWB_NUM-1: 0] jtag_sel_onehot_reg;
    reg jtag_to_wb_we_reg;
    
    genvar i;
    generate
        for (i = 0; i < JWB_NUM ; i = i + 1) begin : block
           
            assign  wb_to_jtag[i]  = wb_to_jtag_all [(i+1)*WB2Jw-1 : i*WB2Jw];            
            assign  {wb_to_jtag_status_all[i],wb_to_jtag_ack_all[i],wb_to_jtag_dat_all[(i+1)*JDw-1 : i*JDw],wb_to_jtag_index_all [i],wb_to_jtag_clk[i]}  = wb_to_jtag[i];
            assign  jtag_sel_onehot[i] = (wb_to_jtag_index_all [i] == jtag_to_wb_index);
            assign  stb_all[i] = jtag_to_wb_stb_reg & jtag_sel_onehot_reg[i];           
            assign  jtag_to_wb_all[(i+1)*J2WBw-1 : i*J2WBw] =jtag_to_wb[i];
            assign  stb_masked_all[i] = stb_all[i] ; // & ~wb_to_jtag_ack_all_latched[i];
            assign  jtag_to_wb[i] = {jtag_to_wb_addr_reg,stb_masked_all[i],jtag_to_wb_we_reg,jtag_to_wb_dat};
      
            always @ (posedge clk)begin 
                if ( wb_to_jtag_ack_all[i] & jtag_sel_onehot_reg[i] & ~jtag_to_wb_we) jtag_dat_in_reg[i] <= wb_to_jtag_dat_all[(i+1)*JDw-1 : i*JDw]; 
            end
            assign wb_to_jtag_dat_all_latched [(i+1)*JDw-1 : i*JDw] = jtag_dat_in_reg[i];
            
            wb_to_jtag_latch ack_latch 
                (
                .clk(clk),
                .jtag_clk(tclk),
                .D_in(wb_to_jtag_ack_all[i]),
                .Q_out(wb_to_jtag_ack_all_latched[i])
            );
      
            
            
        
        
        
        end
    endgenerate
    
    reg [1:0]ctrl_reg;  
      
    always @(posedge clk )begin 
        jtag_to_wb_stb_reg<= jtag_to_wb_stb ;
        jtag_sel_onehot_reg<=jtag_sel_onehot;
        jtag_to_wb_we_reg<=jtag_to_wb_we;
        jtag_to_wb_addr_reg <=jtag_to_wb_addr;
        system_reset <=   ctrl_reg[0];
        cpu_en       <= ~ ctrl_reg[1];           
    end
    
   
    
    
    
  
    localparam BIN_WIDTH     =  (JWB_NUM>1)? log2(JWB_NUM):1;
    wire [BIN_WIDTH-1 : 0] jtag_sel_bin;

  
    jtag_one_hot_to_bin #(
        .ONE_HOT_WIDTH(JWB_NUM),
        .BIN_WIDTH(BIN_WIDTH)
    )
    convert
    (
        .one_hot_code(jtag_sel_onehot),
        .bin_code(jtag_sel_bin)
    );
   
     
     
     assign wb_to_jtag_status=wb_to_jtag_status_all[jtag_sel_bin];
     assign wb_to_jtag_ack =wb_to_jtag_ack_all_latched[jtag_sel_bin];
    // assign wb_to_jtag_dat=wb_to_jtag_dat_all   [jtag_sel_bin];
   //use one-hot mux if index doesnt match the read data is zero
     jtag_one_hot_mux #(
     	.IN_WIDTH(JDw*JWB_NUM),
     	.SEL_WIDTH(JWB_NUM),
     	.OUT_WIDTH(JDw)
     )
     one_hot_mux
     (
     	.mux_in(wb_to_jtag_dat_all_latched),
     	.mux_out(wb_to_jtag_dat),
     	.sel(jtag_sel_onehot_reg)
     );
   
    
    //assign {wb_to_jtag_status,wb_to_jtag_ack,wb_to_jtag_dat}
   
    
  
    wire mem_ctrl_jtag_ack;
    
  
 
    
    
    
    xilinx_jtag_mem_ctrl #(
        .JTAG_CHAIN(JTAG_CHAIN),
        .Dw(JDw),
        .Aw(JAw),
        .INDEXw(JINDEXw)
    )
    mem_ctrl
    (   
      //  .ps(),
      //  .clk(clk),
        .tclk   (tclk    ),
        .wb_to_jtag_status(wb_to_jtag_status ),
        .wb_to_jtag_dat   (wb_to_jtag_dat    ),
        .wb_to_jtag_ack   (mem_ctrl_jtag_ack    ),
                         
        .jtag_to_wb_ir    (  ),
        .jtag_to_wb_index (jtag_to_wb_index  ),
        .jtag_to_wb_dat   (jtag_to_wb_dat    ),
        .jtag_to_wb_addr  (jtag_to_wb_addr   ),
        .jtag_to_wb_stb   (jtag_to_wb_stb    ),
        .jtag_to_wb_we    (jtag_to_wb_we     ),
        
        .reset (reset)
       
        
   );
   
  
    reg rst_ctrl_ack;
`ifdef SYNC_RESET_MODE 
    always @ (posedge tclk )begin 
`else 
    always @ (posedge tclk or posedge reset)begin 
`endif  
   
       if(reset) begin 
        ctrl_reg <=2'b00;
      
       end 
       else if(jtag_to_wb_index ==   CTRL_REG_INDEX)begin 
           
            if(jtag_to_wb_we & jtag_to_wb_stb) begin 
                ctrl_reg <= jtag_to_wb_dat[1:0];
                
            end
       end  
    end 
`ifdef SYNC_RESET_MODE 
    always @ (posedge tclk )begin 
`else 
    always @ (posedge tclk or posedge reset)begin 
`endif      
    
        if(reset) begin 
            rst_ctrl_ack<=1'b0;
          
       end 
       else begin 
            rst_ctrl_ack <= jtag_to_wb_stb;
           
       end  
    end 
    
    

   
    
    assign  mem_ctrl_jtag_ack = ((jtag_to_wb_index ==   CTRL_REG_INDEX) ||  jtag_sel_onehot == {JWB_NUM{1'b0}} ) ? rst_ctrl_ack : wb_to_jtag_ack; 
endmodule
  
  
 
  
  
  
module wb_to_jtag_latch  (
    clk,
    jtag_clk,
    D_in,
    Q_out
);

   input clk,jtag_clk,D_in;
   output Q_out;

   reg out_latch,reset_out;
    
    
    always @ (posedge clk) begin 
        if(D_in) out_latch<=1'b1;
        else if(reset_out) out_latch<=1'b0;    
    end
    
   always @(posedge jtag_clk)begin 
        if(out_latch | D_in) reset_out<=1'b1;
        else reset_out<=1'b0;
   
   end
    


    assign Q_out =  reset_out ; 


endmodule

  
/**************
 *  xilinx_jtag_mem_ctrl
 * ************/



module  xilinx_jtag_mem_ctrl #(
    parameter JTAG_CHAIN=4,
    parameter Dw=32,
    parameter Aw=32,
    parameter INDEXw=8,
    parameter STATUSw=8
)(
   
   // ps,
    wb_to_jtag_status,
    wb_to_jtag_dat,
    wb_to_jtag_ack,
    
    jtag_to_wb_ir,
    jtag_to_wb_index,
    jtag_to_wb_dat,
    jtag_to_wb_addr,
    jtag_to_wb_stb,
    jtag_to_wb_we,
  //  clk,    
    reset,
    tclk
);

  localparam Iw=3;
    
    input [STATUSw-1    : 0] wb_to_jtag_status;
    input [Dw-1 : 0] wb_to_jtag_dat; 
    input wb_to_jtag_ack;
    
    output [INDEXw-1  : 0] jtag_to_wb_index;
   
    output [Iw-1 : 0] jtag_to_wb_ir;
    output [Dw-1 : 0] jtag_to_wb_dat;
    output [Aw-1 : 0] jtag_to_wb_addr;
    output jtag_to_wb_stb;
    output jtag_to_wb_we;

    //input clk;
    input reset;
    output tclk;

     localparam 
        STATE_NUM=3,
        IDEAL =1,
        WB_WR_DATA=2,
        WB_RD_DATA=4;
    
  
    
    reg [STATE_NUM-1    :   0] ns, ps;
    wire reset_ps=1'b0;
   
      
    wire  wb_wr_addr_en,  wb_wr_data_en,    wb_rd_data_en;
    reg wr_mem_en,  rd_mem_en;//  wb_cap_rd;
    
    reg [Aw-1   :   0]  wb_addr,wb_addr_next;
   // reg [Dw-1   :   0]  wb_rd_data;
    wire [Dw-1   :   0]  wb_wr_data;
    reg wb_addr_inc;    
    
   
    assign  jtag_to_wb_stb    = (wr_mem_en |  rd_mem_en) & ~reset_ps;
    assign  jtag_to_wb_we     = wr_mem_en;
    assign  jtag_to_wb_dat    = wb_wr_data;
    assign  jtag_to_wb_addr   = wb_addr;
   

    localparam 
        JDw= (Dw > Aw)? Dw : Aw;
    
    wire [JDw-1  :0] data_out;
    wire [JDw-1   :0] data_in;
    
    //assign  data_in    = wb_rd_data;
   assign  data_in = wb_to_jtag_dat;
   
    wire ir_updated;
  
    xilinx_jtag_ctrl #(
        .JTAG_CHAIN(JTAG_CHAIN),
        .Dw(JDw),
        .INDEXw(INDEXw),
        .STw(STATUSw)
    )
    vjtag_ctrl_inst
    (
  //      .clk(clk),
        .ir(jtag_to_wb_ir  ),
        .status_i(wb_to_jtag_status),
        .index(jtag_to_wb_index),
        .tck(tclk),
        .reset(reset),
        .data_out(data_out),
        .data_in(data_in),
        .wb_wr_addr_en(wb_wr_addr_en),
        .wb_wr_data_en(wb_wr_data_en),
        .wb_rd_data_en(wb_rd_data_en),
        .ir_updated(ir_updated)
    );
        
`ifdef SYNC_RESET_MODE 
    always @ (posedge tclk )begin 
`else 
    always @ (posedge tclk or posedge reset)begin 
`endif  
        if(reset) begin 
            wb_addr <= {Aw{1'b0}};
           // wb_wr_data  <= {Dw{1'b0}};  
           // wb_rd_data  <= {Dw{1'b0}};
            ps <= IDEAL;
        end else begin
            wb_addr <= wb_addr_next;
              if(reset_ps)   ps <= IDEAL;
              else ps <= ns;
           // if(wb_wr_data_en) wb_wr_data  <= data_out;  
           // if(wb_cap_rd | ir_updated ) wb_rd_data <= wb_to_jtag_dat;
        end
    end
    
    assign wb_wr_data = data_out;
    
    always @(*)begin 
        wb_addr_next= wb_addr;
        if(wb_wr_addr_en) wb_addr_next = data_out [Aw-1 :   0];
        else if (wb_addr_inc)  wb_addr_next = wb_addr +1'b1;    
    end
    
    
    
    always @(*)begin 
        ns=ps;
        wr_mem_en =1'b0;
        rd_mem_en =1'b0;
        wb_addr_inc=1'b0;
       // wb_cap_rd=1'b0;
      
        
        case(ps)
        IDEAL : begin 
            if(wb_wr_data_en) ns= WB_WR_DATA;   
            if(wb_rd_data_en) begin 
                ns= WB_RD_DATA;
               // wb_cap_rd=1'b1;
             end   
        end 
        WB_WR_DATA: begin 
            wr_mem_en =1'b1;
            if(wb_to_jtag_ack) begin 
                wr_mem_en =1'b0;
                ns=IDEAL;
                wb_addr_inc=1'b1;           
            end
        end 
        WB_RD_DATA: begin 
            rd_mem_en =1'b1;
            //wb_cap_rd=1'b1;
            if(wb_to_jtag_ack) begin 
                 rd_mem_en =1'b0;
                // wb_cap_rd=1'b0;
                ns=IDEAL;
                //wb_addr_inc=1'b1;         
            end     
        end 
        default begin 
            ns=IDEAL;
        end    
        endcase 
    end 
        
endmodule



/****************
 *  xilinx_jtag_ctrl
 * *************/
module xilinx_jtag_ctrl #(
    parameter JTAG_CHAIN=4,
    parameter Dw=32,    
    parameter INDEXw=8,
    parameter STw=8
)(
  //  clk,
    tck,
    reset,
    ir_updated,
    status_i,
    data_out,
    data_in,
    wb_wr_addr_en,
    wb_wr_data_en,
    wb_rd_data_en,
    ir,
    index
);

    

    localparam 
        Iw=3,
        M1 = (Dw>Iw)? Dw :Iw,
        M2 = (M1>INDEXw)? M1 :INDEXw,
        BUFFw= M1+4;
        
     // IR states
     localparam [Iw-1:0]  
        UPDATE_WB_ADDR  = 3'b111,
        UPDATE_WB_WR_DATA  = 3'b110,
        UPDATE_WB_RD_DATA  = 3'b101,
        RD_STATUS      =3'b100,
        UPDATE_CTRL =3'b001,
        BYPASS = 3'b000;//not used
        
        

//IO declaration
  //  input clk;
    input reset;
    output tck;
    input [STw-1 :0] status_i;
    input [Dw-1 :0] data_in;
    output reg wb_wr_addr_en, wb_wr_data_en,    wb_rd_data_en;
    
    output  reg [Iw-1:0] ir;
    output  reg [INDEXw-1:0] index;
    output   reg [Dw-1    :0] data_out;
    output reg ir_updated;
    

    wire      tdo, tck,   tdi;  
    wire      cdr ,sdr,udr;
    wire tlr;
    
    xilinx_jtag_bscan #(
        .JTAG_CHAIN(JTAG_CHAIN)
    )
    vjtag_inst
    (
        .tdo ( tdo ),   
        .tck ( tck ),
        .tdi ( tdi ),
        
        .tlr ( tlr ),
        .cdr ( cdr ),
        .sdr ( sdr ),
        .udr ( udr )    
     );
      
    // internal registers 
   (* KEEP = "TRUE" *)  reg [BUFFw-1   :   0] jtag_shift_buffer,jtag_shift_buffer_next;
  
    assign tdo =  jtag_shift_buffer[0];
   
    always @ (*)begin 
        jtag_shift_buffer_next=jtag_shift_buffer;
        if( sdr ) jtag_shift_buffer_next={tdi,jtag_shift_buffer[BUFFw-1:1]};// shift buffer
        else if( cdr )begin 
            case(ir)
            RD_STATUS:begin
                jtag_shift_buffer_next[STw-1  :   0] = status_i;
            end
            UPDATE_WB_RD_DATA: begin 
                jtag_shift_buffer_next[Dw-1 : 0] = data_in;
                //synthesis translate_off 
                 if(data_in[7:0]!=7'd0 && index==126)  $write("%c",data_in[7:0]);
                //synthesis translate_on
            end
            default :begin
                jtag_shift_buffer_next=jtag_shift_buffer;
            end
            endcase 
        end
    end
     
    localparam 
        UPDATE_INDEX =0,
        UPDATE_IR=1,
        UPDATE_DAT=2; 
    
    wire update_index_flag = jtag_shift_buffer[M1+UPDATE_INDEX]; 
    wire update_ir_flag    = jtag_shift_buffer[M1+UPDATE_IR];
    wire update_dat_flag   = jtag_shift_buffer[M1+UPDATE_DAT];     
        
    always @(posedge tck )    begin
         jtag_shift_buffer<=jtag_shift_buffer_next;  
    end   

      reg mask;

      always @(posedge tck )    begin                 
            if( udr)begin 
                if(update_index_flag) begin 
                    index <= jtag_shift_buffer[INDEXw-1 : 0];
                    ir<={Iw{1'b0}};
                    mask<=1'b1;
                   
                    
                end else if(update_ir_flag   )begin 
                    ir    <= jtag_shift_buffer[Iw-1 : 0];
                  
                    mask<=1'b1;
                end    
                if(update_dat_flag  )begin 
                    data_out <= jtag_shift_buffer[Dw-1 : 0];
                    mask<=1'b0;
                 
                end    
            end            
    end 
    
    
    
    always @( posedge tck )    begin                 
            if( udr && update_ir_flag   ) ir_updated<=1'b1;
            else ir_updated<=1'b0;
    end        
   // assign data_out = jtag_shift_buffer[Dw-1 : 0];
    
   /* 
    always @(posedge tck ) begin       
           if( sdr ) jtag_shift_buffer<={tdi,jtag_shift_buffer[BUFFw-1:1]};// shift buffer
           if( cdr ) jtag_shift_buffer<={data_in,ir};
           if( udr ) ir <= jtag_shift_buffer_next[Iw-1:0];
    end   
    */
    
    
  
    //always @(posedge tck or posedge reset)
    always @(posedge tck)
    begin
        //if( reset )   begin
        //  wb_wr_addr1<=1'b0;
        //  wb_wr_data1<=1'b0;
        //end else begin
            wb_wr_addr_en<=(ir== UPDATE_WB_ADDR || ir== UPDATE_WB_RD_DATA) &  udr & update_dat_flag;
            wb_wr_data_en<=((ir== UPDATE_WB_WR_DATA|| ir==UPDATE_CTRL) &  udr & update_dat_flag);  
            wb_rd_data_en<=((ir== UPDATE_WB_RD_DATA) &  cdr  & ~mask);
        //end   
    end
    
   

   
endmodule

/**************
 *  xilinx_jtag_bscan
 * ************/

module xilinx_jtag_bscan #(   
    // Only used for Virtex 4/5 devices
    parameter JTAG_CHAIN = 4  // May be 1, 2, 3, or 4
)
(
    tck,
    tdo,
    tdi,
    
    tlr,
    sdr,
    cdr,
    udr
);



input  tdo;
output tck;
output tdi;

output tlr;
output sdr;
output cdr;
output udr;

wire tck_i;

wire sel;
wire shift,update,capture;
assign sdr = shift & sel;
assign udr = update & sel;
assign cdr = capture & sel;

`ifdef MODEL_TECH 
    `define RUN_SIM
`endif
`ifdef VERILATOR
    `define RUN_SIM
`endif
    
`ifdef  RUN_SIM

    BSCANE2_sim #(
        .JTAG_CHAIN(JTAG_CHAIN) // Value for USER command.
    )
    bse2_inst
    (
        .CAPTURE(capture), // 1-bit output: CAPTURE output from TAP controller.
        .DRCK(), // 1-bit output: Gated TCK output. When SEL is asserted, DRCK toggles when CAPTURE or SHIFT are asserted.
        .RESET(tlr), // 1-bit output: Reset output for TAP controller.
        .RUNTEST(), // 1-bit output: Output asserted when TAP controller is in Run Test/Idle state.
        .SEL(sel), // 1-bit output: USER instruction active output.
        .SHIFT(shift), // 1-bit output: SHIFT output from TAP controller.
        .TCK(tck), // 1-bit output: Test Clock output. Fabric connection to TAP Clock pin.
        .TDI(tdi), // 1-bit output: Test Data Input (TDI) output from TAP controller.
        .TMS( ), // 1-bit output: Test Mode Select output. Fabric connection to TAP.
        .UPDATE(update), // 1-bit output: UPDATE output from TAP controller
        .TDO(tdo) // 1-bit input: Test Data Output (TDO) input for USER function.
    );

  

`else



    BSCANE2 #(
        .JTAG_CHAIN(JTAG_CHAIN) // Value for USER command.
    )
    bse2_inst
    (
        .CAPTURE(capture), // 1-bit output: CAPTURE output from TAP controller.
        .DRCK( ), // 1-bit output: Gated TCK output. When SEL is asserted, DRCK toggles when CAPTURE or SHIFT are asserted.
        .RESET(tlr), // 1-bit output: Reset output for TAP controller.
        .RUNTEST(), // 1-bit output: Output asserted when TAP controller is in Run Test/Idle state.
        .SEL(sel), // 1-bit output: USER instruction active output.
        .SHIFT(shift), // 1-bit output: SHIFT output from TAP controller.
        .TCK(tck), // 1-bit output: Test Clock output. Fabric connection to TAP Clock pin.
        .TDI(tdi), // 1-bit output: Test Data Input (TDI) output from TAP controller.
        .TMS( ), // 1-bit output: Test Mode Select output. Fabric connection to TAP.
        .UPDATE(update), // 1-bit output: UPDATE output from TAP controller
        .TDO(tdo) // 1-bit input: Test Data Output (TDO) input for USER function.
    );
    
 //     BUFG clk_buf(tck, tck_i);
    
`endif
  
endmodule



module jtag_one_hot_to_bin #(
    parameter ONE_HOT_WIDTH =   4,
    parameter BIN_WIDTH     =  (ONE_HOT_WIDTH>1)? log2(ONE_HOT_WIDTH):1
)
(
    input   [ONE_HOT_WIDTH-1        :   0] one_hot_code,
    output  [BIN_WIDTH-1            :   0]  bin_code

);

  
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end       
      end   
    endfunction // log2 

localparam MUX_IN_WIDTH =   BIN_WIDTH* ONE_HOT_WIDTH;

wire [MUX_IN_WIDTH-1        :   0]  bin_temp ;

genvar i;
generate 
    if(ONE_HOT_WIDTH>1)begin :if1
        for(i=0; i<ONE_HOT_WIDTH; i=i+1) begin :mux_in_gen_loop
            assign bin_temp[(i+1)*BIN_WIDTH-1 : i*BIN_WIDTH] =  i[BIN_WIDTH-1:0];
        end


        jtag_one_hot_mux #(
            .IN_WIDTH   (MUX_IN_WIDTH),
            .SEL_WIDTH  (ONE_HOT_WIDTH)
            
        )
        one_hot_to_bcd_mux
        (
            .mux_in     (bin_temp),
            .mux_out        (bin_code),
            .sel            (one_hot_code)
    
        );
     end else begin :els
        assign  bin_code = 1'b0;
     
     end

endgenerate

endmodule


module jtag_one_hot_mux #(
        parameter   IN_WIDTH      = 20,
        parameter   SEL_WIDTH =   5, 
        parameter   OUT_WIDTH = IN_WIDTH/SEL_WIDTH

    )
    (
        input [IN_WIDTH-1       :0] mux_in,
        output[OUT_WIDTH-1  :0] mux_out,
        input[SEL_WIDTH-1   :0] sel

    );

    wire [IN_WIDTH-1    :0] mask;
    wire [IN_WIDTH-1    :0] masked_mux_in;
    wire [SEL_WIDTH-1:0]    mux_out_gen [OUT_WIDTH-1:0]; 
    
    genvar i,j;
    
    //first selector masking
    generate    // first_mask = {sel[0],sel[0],sel[0],....,sel[n],sel[n],sel[n]}
        for(i=0; i<SEL_WIDTH; i=i+1) begin : mask_loop
            assign mask[(i+1)*OUT_WIDTH-1 : (i)*OUT_WIDTH]  =   {OUT_WIDTH{sel[i]} };
        end
        
        assign masked_mux_in    = mux_in & mask;
        
        for(i=0; i<OUT_WIDTH; i=i+1) begin : lp1
            for(j=0; j<SEL_WIDTH; j=j+1) begin : lp2
                assign mux_out_gen [i][j]   =   masked_mux_in[i+OUT_WIDTH*j];
            end
            assign mux_out[i] = | mux_out_gen [i];
        end
    endgenerate
    
endmodule

