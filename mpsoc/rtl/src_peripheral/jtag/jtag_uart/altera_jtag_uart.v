// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on


module altera_jtag_uart #(
    parameter SIM_BUFFER_SIZE   =100,  
    parameter SIM_WAIT_COUNT    =1000


)(
    reset,
    clk,
    irq,
    s_dat_i,
    s_sel_i,
    s_addr_i,  
    s_cti_i,
    s_stb_i,
    s_cyc_i,
    s_we_i,    
    s_dat_o,
    s_ack_o,
    RxD_din_sim,
    RxD_wr_sim,
    RxD_ready_sim 
    

);

	localparam
		Dw            =   32,
		M_Aw          =   32,
		TAGw          =   3,
		SELw          =   4;
  


    input reset,clk;
//wishbone slave interface signals
    input   [Dw-1       :   0]      s_dat_i;
    input   [SELw-1     :   0]      s_sel_i;
    input    			    s_addr_i;  
    input   [TAGw-1     :   0]      s_cti_i;
    input                           s_stb_i;
    input                           s_cyc_i;
    input                           s_we_i;
    output irq;
    output  [Dw-1       :   0]  s_dat_o;
    output                     s_ack_o;


    
    
    input [7:0 ] RxD_din_sim;
    input RxD_wr_sim;
    output RxD_ready_sim;
    

    `ifdef MODEL_TECH 
    	`define RUN_SIM
    `endif
    `ifdef VERILATOR
    	`define RUN_SIM
    `endif

    

`ifdef RUN_SIM

	// code for simulation with verilator/mpdelsim
    // synthesis translate_off
	altera_uart_simulator #(
		.BUFFER_SIZE(SIM_BUFFER_SIZE),  
    		.WAIT_COUNT(SIM_WAIT_COUNT)    
	)
	Suart
	(
		.reset(reset),
		.clk(clk),
		.s_dat_i(s_dat_i),
		.s_sel_i(s_sel_i),
		.s_addr_i(s_addr_i),  
		.s_cti_i(s_cti_i),
		.s_stb_i(s_stb_i),
		.s_cyc_i(s_cyc_i),
		.s_we_i(s_we_i),    
		.s_dat_o(s_dat_o),
		.s_ack_o(s_ack_o),
		.RxD_din(RxD_din_sim),
		.RxD_wr(RxD_wr_sim),
		.RxD_ready(RxD_ready_sim)


	);
	// synthesis translate_on
`else 
 `
// code for synthesis

	altera_jtag_uart_wb_hw Juart(
	  	.clk(clk),
		.rst(reset),
	  	.wb_irq(irq),
	  	.dat_o(s_dat_o),
	  	.ack_o(s_ack_o),
	  	.adr_i(s_addr_i),
	  	.stb_i(s_stb_i),
	  	.cyc_i(s_cyc_i),
	  	.we_i(s_we_i),
	  	.dat_i(s_dat_i),
	  	.dataavailable(),
	  	.readyfordata()
	);

	assign  RxD_ready_sim = 1'bX;


`endif


endmodule





module altera_jtag_uart_wb_hw(
  input 				clk,rst,
  output           wb_irq,
  output  [ 31: 0] dat_o,
  output           ack_o,
  input            adr_i,
  input            stb_i,
  input            cyc_i,
  input            we_i,
  input   [ 31: 0] dat_i,
  output           dataavailable,
  output           readyfordata
);
	wire av_waitrequest;
	assign ack_o=~av_waitrequest;

	qsys_jtag_uart_0 jtag_uart_0 (
		.clk            (clk),
		.rst_n          (~rst),
		.av_chipselect  (stb_i),
		.av_address     (adr_i),
		.av_read_n      (~(cyc_i&~we_i)),
		.av_readdata    (dat_o),
		.av_write_n     (~(cyc_i&we_i)),
		.av_writedata   (dat_i),
		.av_waitrequest (av_waitrequest),
		.av_irq         (wb_irq),
		.dataavailable	(dataavailable),
		.readyfordata	(readyfordata)
	);

endmodule 






//Legal Notice: (C)2015 Altera Corporation. All rights reserved.  Your
//use of Altera Corporation's design tools, logic functions and other
//software and tools, and its AMPP partner logic functions, and any
//output files any of the foregoing (including device programming or
//simulation files), and any associated documentation or information are
//expressly subject to the terms and conditions of the Altera Program
//License Subscription Agreement or other applicable license agreement,
//including, without limitation, that your use is for the sole purpose
//of programming logic devices manufactured by Altera and sold by Altera
//or its authorized distributors.  Please refer to the applicable
//agreement for further details.



// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module qsys_jtag_uart_0_sim_scfifo_w (
                                       // inputs:
                                        clk,
                                        fifo_wdata,
                                        fifo_wr,

                                       // outputs:
                                        fifo_FF,
                                        r_dat,
                                        wfifo_empty,
                                        wfifo_used
                                     )
;

  output           fifo_FF;
  output  [  7: 0] r_dat;
  output           wfifo_empty;
  output  [  5: 0] wfifo_used;
  input            clk;
  input   [  7: 0] fifo_wdata;
  input            fifo_wr;

  wire             fifo_FF;
  wire    [  7: 0] r_dat;
  wire             wfifo_empty;
  wire    [  5: 0] wfifo_used;

//synthesis translate_off
//////////////// SIMULATION-ONLY CONTENTS
  always @(posedge clk)
    begin
      if (fifo_wr)
          $write("%c", fifo_wdata);
    end


  assign wfifo_used = {6{1'b0}};
  assign r_dat = {8{1'b0}};
  assign fifo_FF = 1'b0;
  assign wfifo_empty = 1'b1;

//////////////// END SIMULATION-ONLY CONTENTS

//synthesis translate_on

endmodule


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module qsys_jtag_uart_0_scfifo_w (
                                   // inputs:
                                    clk,
                                    fifo_clear,
                                    fifo_wdata,
                                    fifo_wr,
                                    rd_wfifo,

                                   // outputs:
                                    fifo_FF,
                                    r_dat,
                                    wfifo_empty,
                                    wfifo_used
                                 )
;

  output           fifo_FF;
  output  [  7: 0] r_dat;
  output           wfifo_empty;
  output  [  5: 0] wfifo_used;
  input            clk;
  input            fifo_clear;
  input   [  7: 0] fifo_wdata;
  input            fifo_wr;
  input            rd_wfifo;

  wire             fifo_FF;
  wire    [  7: 0] r_dat;
  wire             wfifo_empty;
  wire    [  5: 0] wfifo_used;

//synthesis translate_off
//////////////// SIMULATION-ONLY CONTENTS
  qsys_jtag_uart_0_sim_scfifo_w the_qsys_jtag_uart_0_sim_scfifo_w
    (
      .clk         (clk),
      .fifo_FF     (fifo_FF),
      .fifo_wdata  (fifo_wdata),
      .fifo_wr     (fifo_wr),
      .r_dat       (r_dat),
      .wfifo_empty (wfifo_empty),
      .wfifo_used  (wfifo_used)
    );


//////////////// END SIMULATION-ONLY CONTENTS

//synthesis translate_on
//synthesis read_comments_as_HDL on
//  scfifo wfifo
//    (
//      .aclr (fifo_clear),
//      .clock (clk),
//      .data (fifo_wdata),
//      .empty (wfifo_empty),
//      .full (fifo_FF),
//      .q (r_dat),
//      .rdreq (rd_wfifo),
//      .usedw (wfifo_used),
//      .wrreq (fifo_wr)
//    );
//
//  defparam wfifo.lpm_hint = "RAM_BLOCK_TYPE=AUTO",
//           wfifo.lpm_numwords = 64,
//           wfifo.lpm_showahead = "OFF",
//           wfifo.lpm_type = "scfifo",
//           wfifo.lpm_width = 8,
//           wfifo.lpm_widthu = 6,
//           wfifo.overflow_checking = "OFF",
//           wfifo.underflow_checking = "OFF",
//           wfifo.use_eab = "ON";
//
//synthesis read_comments_as_HDL off

endmodule


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module qsys_jtag_uart_0_sim_scfifo_r (
                                       // inputs:
                                        clk,
                                        fifo_rd,
                                        rst_n,

                                       // outputs:
                                        fifo_EF,
                                        fifo_rdata,
                                        rfifo_full,
                                        rfifo_used
                                     )
;

  output           fifo_EF;
  output  [  7: 0] fifo_rdata;
  output           rfifo_full;
  output  [  5: 0] rfifo_used;
  input            clk;
  input            fifo_rd;
  input            rst_n;

  reg     [ 31: 0] bytes_left;
  wire             fifo_EF;
  reg              fifo_rd_d;
  wire    [  7: 0] fifo_rdata;
  wire             new_rom;
  wire    [ 31: 0] num_bytes;
  wire    [  6: 0] rfifo_entries;
  wire             rfifo_full;
  wire    [  5: 0] rfifo_used;

//synthesis translate_off
//////////////// SIMULATION-ONLY CONTENTS
  // Generate rfifo_entries for simulation
  always @(posedge clk or negedge rst_n)
    begin
      if (rst_n == 0)
        begin
          bytes_left <= 32'h0;
          fifo_rd_d <= 1'b0;
        end
      else 
        begin
          fifo_rd_d <= fifo_rd;
          // decrement on read
          if (fifo_rd_d)
              bytes_left <= bytes_left - 1'b1;
          // catch new contents
          if (new_rom)
              bytes_left <= num_bytes;
        end
    end


  assign fifo_EF = bytes_left == 32'b0;
  assign rfifo_full = bytes_left > 7'h40;
  assign rfifo_entries = (rfifo_full) ? 7'h40 : bytes_left;
  assign rfifo_used = rfifo_entries[5 : 0];
  assign new_rom = 1'b0;
  assign num_bytes = 32'b0;
  assign fifo_rdata = 8'b0;

//////////////// END SIMULATION-ONLY CONTENTS

//synthesis translate_on

endmodule


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module qsys_jtag_uart_0_scfifo_r (
                                   // inputs:
                                    clk,
                                    fifo_clear,
                                    fifo_rd,
                                    rst_n,
                                    t_dat,
                                    wr_rfifo,

                                   // outputs:
                                    fifo_EF,
                                    fifo_rdata,
                                    rfifo_full,
                                    rfifo_used
                                 )
;

  output           fifo_EF;
  output  [  7: 0] fifo_rdata;
  output           rfifo_full;
  output  [  5: 0] rfifo_used;
  input            clk;
  input            fifo_clear;
  input            fifo_rd;
  input            rst_n;
  input   [  7: 0] t_dat;
  input            wr_rfifo;

  wire             fifo_EF;
  wire    [  7: 0] fifo_rdata;
  wire             rfifo_full;
  wire    [  5: 0] rfifo_used;

//synthesis translate_off
//////////////// SIMULATION-ONLY CONTENTS
  qsys_jtag_uart_0_sim_scfifo_r the_qsys_jtag_uart_0_sim_scfifo_r
    (
      .clk        (clk),
      .fifo_EF    (fifo_EF),
      .fifo_rd    (fifo_rd),
      .fifo_rdata (fifo_rdata),
      .rfifo_full (rfifo_full),
      .rfifo_used (rfifo_used),
      .rst_n      (rst_n)
    );


//////////////// END SIMULATION-ONLY CONTENTS

//synthesis translate_on
//synthesis read_comments_as_HDL on
//  scfifo rfifo
//    (
//      .aclr (fifo_clear),
//      .clock (clk),
//      .data (t_dat),
//      .empty (fifo_EF),
//      .full (rfifo_full),
//      .q (fifo_rdata),
//      .rdreq (fifo_rd),
//      .usedw (rfifo_used),
//      .wrreq (wr_rfifo)
//    );
//
//  defparam rfifo.lpm_hint = "RAM_BLOCK_TYPE=AUTO",
//           rfifo.lpm_numwords = 64,
//           rfifo.lpm_showahead = "OFF",
//           rfifo.lpm_type = "scfifo",
//           rfifo.lpm_width = 8,
//           rfifo.lpm_widthu = 6,
//           rfifo.overflow_checking = "OFF",
//           rfifo.underflow_checking = "OFF",
//           rfifo.use_eab = "ON";
//
//synthesis read_comments_as_HDL off

endmodule


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module qsys_jtag_uart_0 (
                          // inputs:
                           av_address,
                           av_chipselect,
                           av_read_n,
                           av_write_n,
                           av_writedata,
                           clk,
                           rst_n,

                          // outputs:
                           av_irq,
                           av_readdata,
                           av_waitrequest,
                           dataavailable,
                           readyfordata
                        )
  /* synthesis ALTERA_ATTRIBUTE = "SUPPRESS_DA_RULE_INTERNAL=\"R101,C106,D101,D103\"" */ ;

  output           av_irq;
  output  [ 31: 0] av_readdata;
  output           av_waitrequest;
  output           dataavailable;
  output           readyfordata;
  input            av_address;
  input            av_chipselect;
  input            av_read_n;
  input            av_write_n;
  input   [ 31: 0] av_writedata;
  input            clk;
  input            rst_n;

  reg              ac;
  wire             activity;
  wire             av_irq;
  wire    [ 31: 0] av_readdata;
  reg              av_waitrequest;
  reg              dataavailable;
  reg              fifo_AE;
  reg              fifo_AF;
  wire             fifo_EF;
  wire             fifo_FF;
  wire             fifo_clear;
  wire             fifo_rd;
  wire    [  7: 0] fifo_rdata;
  wire    [  7: 0] fifo_wdata;
  reg              fifo_wr;
  reg              ien_AE;
  reg              ien_AF;
  wire             ipen_AE;
  wire             ipen_AF;
  reg              pause_irq;
  wire    [  7: 0] r_dat;
  wire             r_ena;
  reg              r_val;
  wire             rd_wfifo;
  reg              read_0;
  reg              readyfordata;
  wire             rfifo_full;
  wire    [  5: 0] rfifo_used;
  reg              rvalid;
  reg              sim_r_ena;
  reg              sim_t_dat;
  reg              sim_t_ena;
  reg              sim_t_pause;
  wire    [  7: 0] t_dat;
  reg              t_dav;
  wire             t_ena;
  wire             t_pause;
  wire             wfifo_empty;
  wire    [  5: 0] wfifo_used;
  reg              woverflow;
  wire             wr_rfifo;
  //avalon_jtag_slave, which is an e_avalon_slave
  assign rd_wfifo = r_ena & ~wfifo_empty;
  assign wr_rfifo = t_ena & ~rfifo_full;
  assign fifo_clear = ~rst_n;
  qsys_jtag_uart_0_scfifo_w the_qsys_jtag_uart_0_scfifo_w
    (
      .clk         (clk),
      .fifo_FF     (fifo_FF),
      .fifo_clear  (fifo_clear),
      .fifo_wdata  (fifo_wdata),
      .fifo_wr     (fifo_wr),
      .r_dat       (r_dat),
      .rd_wfifo    (rd_wfifo),
      .wfifo_empty (wfifo_empty),
      .wfifo_used  (wfifo_used)
    );

  qsys_jtag_uart_0_scfifo_r the_qsys_jtag_uart_0_scfifo_r
    (
      .clk        (clk),
      .fifo_EF    (fifo_EF),
      .fifo_clear (fifo_clear),
      .fifo_rd    (fifo_rd),
      .fifo_rdata (fifo_rdata),
      .rfifo_full (rfifo_full),
      .rfifo_used (rfifo_used),
      .rst_n      (rst_n),
      .t_dat      (t_dat),
      .wr_rfifo   (wr_rfifo)
    );

  assign ipen_AE = ien_AE & fifo_AE;
  assign ipen_AF = ien_AF & (pause_irq | fifo_AF);
  assign av_irq = ipen_AE | ipen_AF;
  assign activity = t_pause | t_ena;
  always @(posedge clk or negedge rst_n)
    begin
      if (rst_n == 0)
          pause_irq <= 1'b0;
      else // only if fifo is not empty...
      if (t_pause & ~fifo_EF)
          pause_irq <= 1'b1;
      else if (read_0)
          pause_irq <= 1'b0;
    end


  always @(posedge clk or negedge rst_n)
    begin
      if (rst_n == 0)
        begin
          r_val <= 1'b0;
          t_dav <= 1'b1;
        end
      else 
        begin
          r_val <= r_ena & ~wfifo_empty;
          t_dav <= ~rfifo_full;
        end
    end


  always @(posedge clk or negedge rst_n)
    begin
      if (rst_n == 0)
        begin
          fifo_AE <= 1'b0;
          fifo_AF <= 1'b0;
          fifo_wr <= 1'b0;
          rvalid <= 1'b0;
          read_0 <= 1'b0;
          ien_AE <= 1'b0;
          ien_AF <= 1'b0;
          ac <= 1'b0;
          woverflow <= 1'b0;
          av_waitrequest <= 1'b1;
        end
      else 
        begin
          fifo_AE <= {fifo_FF,wfifo_used} <= 8;
          fifo_AF <= (7'h40 - {rfifo_full,rfifo_used}) <= 8;
          fifo_wr <= 1'b0;
          read_0 <= 1'b0;
          av_waitrequest <= ~(av_chipselect & (~av_write_n | ~av_read_n) & av_waitrequest);
          if (activity)
              ac <= 1'b1;
          // write
          if (av_chipselect & ~av_write_n & av_waitrequest)
              // addr 1 is control; addr 0 is data
              if (av_address)
                begin
                  ien_AF <= av_writedata[0];
                  ien_AE <= av_writedata[1];
                  if (av_writedata[10] & ~activity)
                      ac <= 1'b0;
                end
              else 
                begin
                  fifo_wr <= ~fifo_FF;
                  woverflow <= fifo_FF;
                end
          // read
          if (av_chipselect & ~av_read_n & av_waitrequest)
            begin
              // addr 1 is interrupt; addr 0 is data
              if (~av_address)
                  rvalid <= ~fifo_EF;
              read_0 <= ~av_address;
            end
        end
    end


  assign fifo_wdata = av_writedata[7 : 0];
  assign fifo_rd = (av_chipselect & ~av_read_n & av_waitrequest & ~av_address) ? ~fifo_EF : 1'b0;
  assign av_readdata = read_0 ? { {9{1'b0}},rfifo_full,rfifo_used,rvalid,woverflow,~fifo_FF,~fifo_EF,1'b0,ac,ipen_AE,ipen_AF,fifo_rdata } : { {9{1'b0}},(7'h40 - {fifo_FF,wfifo_used}),rvalid,woverflow,~fifo_FF,~fifo_EF,1'b0,ac,ipen_AE,ipen_AF,{6{1'b0}},ien_AE,ien_AF };
  always @(posedge clk or negedge rst_n)
    begin
      if (rst_n == 0)
          readyfordata <= 0;
      else 
        readyfordata <= ~fifo_FF;
    end



//synthesis translate_off
//////////////// SIMULATION-ONLY CONTENTS
  // Tie off Atlantic Interface signals not used for simulation
  always @(posedge clk)
    begin
      sim_t_pause <= 1'b0;
      sim_t_ena <= 1'b0;
      sim_t_dat <= t_dav ? r_dat : {8{r_val}};
      sim_r_ena <= 1'b0;
    end


  assign r_ena = sim_r_ena;
  assign t_ena = sim_t_ena;
  assign t_dat = sim_t_dat;
  assign t_pause = sim_t_pause;
  always @(fifo_EF)
    begin
      dataavailable = ~fifo_EF;
    end



//////////////// END SIMULATION-ONLY CONTENTS

//synthesis translate_on
//synthesis read_comments_as_HDL on
//  alt_jtag_atlantic qsys_jtag_uart_0_alt_jtag_atlantic
//    (
//      .clk (clk),
//      .r_dat (r_dat),
//      .r_ena (r_ena),
//      .r_val (r_val),
//      .rst_n (rst_n),
//      .t_dat (t_dat),
//      .t_dav (t_dav),
//      .t_ena (t_ena),
//      .t_pause (t_pause)
//    );
//
//  defparam qsys_jtag_uart_0_alt_jtag_atlantic.INSTANCE_ID = 0,
//           qsys_jtag_uart_0_alt_jtag_atlantic.LOG2_RXFIFO_DEPTH = 6,
//           qsys_jtag_uart_0_alt_jtag_atlantic.LOG2_TXFIFO_DEPTH = 6,
//           qsys_jtag_uart_0_alt_jtag_atlantic.SLD_AUTO_INSTANCE_INDEX = "YES";
//
//  always @(posedge clk or negedge rst_n)
//    begin
//      if (rst_n == 0)
//          dataavailable <= 0;
//      else 
//        dataavailable <= ~fifo_EF;
//    end
//
//
//synthesis read_comments_as_HDL off

endmodule


