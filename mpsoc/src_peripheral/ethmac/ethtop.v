


`include "ethmac_defines.v"
`include "timescale.v"


module ethtop
(
  // WISHBONE common
  wb_clk_i, wb_rst_i, wb_dat_i, wb_dat_o, 

  // WISHBONE slave
  wb_adr_i, wb_sel_i, wb_we_i, wb_cyc_i, wb_stb_i, wb_ack_o, wb_err_o, 

  // WISHBONE master
  m_wb_adr_o, m_wb_sel_o, m_wb_we_o, 
  m_wb_dat_o, m_wb_dat_i, m_wb_cyc_o, 
  m_wb_stb_o, m_wb_ack_i, m_wb_err_i, 

`ifdef ETH_WISHBONE_B3
  m_wb_cti_o, m_wb_bte_o, 
`endif

  //TX
  mtx_clk_pad_i, mtxd_pad_o, mtxen_pad_o, mtxerr_pad_o,

  //RX
  mrx_clk_pad_i, mrxd_pad_i, mrxdv_pad_i, mrxerr_pad_i, mcoll_pad_i, mcrs_pad_i,
  
  // MIIM
  mdc_pad_o, md_pad_i, md_pad_o, md_padoe_o,

  int_o

  // Bist
`ifdef ETH_BIST
  ,
  // debug chain signals
  mbist_si_i,       // bist scan serial in
  mbist_so_o,       // bist scan serial out
  mbist_ctrl_i        // bist chain shift control
`endif

);


parameter TX_FIFO_DATA_WIDTH = `ETH_TX_FIFO_DATA_WIDTH;
parameter TX_FIFO_DEPTH      = `ETH_TX_FIFO_DEPTH;
parameter TX_FIFO_CNT_WIDTH  = `ETH_TX_FIFO_CNT_WIDTH;
parameter RX_FIFO_DATA_WIDTH = `ETH_RX_FIFO_DATA_WIDTH;
parameter RX_FIFO_DEPTH      = `ETH_RX_FIFO_DEPTH;
parameter RX_FIFO_CNT_WIDTH  = `ETH_RX_FIFO_CNT_WIDTH;


// WISHBONE common
input           wb_clk_i;     // WISHBONE clock
input           wb_rst_i;     // WISHBONE reset
input   [31:0]  wb_dat_i;     // WISHBONE data input
output  [31:0]  wb_dat_o;     // WISHBONE data output
output          wb_err_o;     // WISHBONE error output

// WISHBONE slave
input   [9:0]  wb_adr_i;     // WISHBONE address input
input    [3:0]  wb_sel_i;     // WISHBONE byte select input
input           wb_we_i;      // WISHBONE write enable input
input           wb_cyc_i;     // WISHBONE cycle input
input           wb_stb_i;     // WISHBONE strobe input
output          wb_ack_o;     // WISHBONE acknowledge output

// WISHBONE master
output  [31:0]  m_wb_adr_o;
output   [3:0]  m_wb_sel_o;
output          m_wb_we_o;
input   [31:0]  m_wb_dat_i;
output  [31:0]  m_wb_dat_o;
output          m_wb_cyc_o;
output          m_wb_stb_o;
input           m_wb_ack_i;
input           m_wb_err_i;

wire    [29:0]  m_wb_adr_tmp;

`ifdef ETH_WISHBONE_B3
output   [2:0]  m_wb_cti_o;   // Cycle Type Identifier
output   [1:0]  m_wb_bte_o;   // Burst Type Extension
`endif

// Tx
input           mtx_clk_pad_i; // Transmit clock (from PHY)
output   [3:0]  mtxd_pad_o;    // Transmit nibble (to PHY)
output          mtxen_pad_o;   // Transmit enable (to PHY)
output          mtxerr_pad_o;  // Transmit error (to PHY)

// Rx
input           mrx_clk_pad_i; // Receive clock (from PHY)
input    [3:0]  mrxd_pad_i;    // Receive nibble (from PHY)
input           mrxdv_pad_i;   // Receive data valid (from PHY)
input           mrxerr_pad_i;  // Receive data error (from PHY)

// Common Tx and Rx
input           mcoll_pad_i;   // Collision (from PHY)
input           mcrs_pad_i;    // Carrier sense (from PHY)

// MII Management interface
input           md_pad_i;      // MII data input (from I/O cell)
output          mdc_pad_o;     // MII Management data clock (to PHY)
output          md_pad_o;      // MII data output (to I/O cell)
output          md_padoe_o;    // MII data output enable (to I/O cell)

output          int_o;         // Interrupt output

// Bist
`ifdef ETH_BIST
input   mbist_si_i;       // bist scan serial in
output  mbist_so_o;       // bist scan serial out
input [`ETH_MBIST_CTRL_WIDTH - 1:0] mbist_ctrl_i;       // bist chain shift control
`endif

wire [31:0] m_wb_adr_o_in_byte;

eth_top top
(
  	// WISHBONE common
	.wb_clk_i(wb_clk_i), 
	.wb_rst_i(wb_rst_i), 
	.wb_dat_i(wb_dat_i), 
	.wb_dat_o(wb_dat_o), 

	// WISHBONE slave
	.wb_adr_i(wb_adr_i), 
	.wb_sel_i(wb_sel_i), 
	.wb_we_i(wb_we_i), 
	.wb_cyc_i(wb_cyc_i), 
	.wb_stb_i(wb_stb_i), 
	.wb_ack_o(wb_ack_o), 
	.wb_err_o(wb_err_o), 
	

	// WISHBONE master
  	.m_wb_adr_o(m_wb_adr_o_in_byte), 
	.m_wb_sel_o(m_wb_sel_o), 
	.m_wb_we_o(m_wb_we_o), 
	.m_wb_dat_o(m_wb_dat_o), 
	.m_wb_dat_i(m_wb_dat_i), 
	.m_wb_cyc_o(m_wb_cyc_o), 
	.m_wb_stb_o(m_wb_stb_o), 
	.m_wb_ack_i(m_wb_ack_i), 
	.m_wb_err_i(m_wb_err_i), 

`ifdef ETH_WISHBONE_B3
  	.m_wb_cti_o(m_wb_cti_o),
	.m_wb_bte_o(m_wb_bte_o), 
`endif

  //TX
  	.mtx_clk_pad_i(mtx_clk_pad_i), 
	.mtxd_pad_o(mtxd_pad_o), 
	.mtxen_pad_o(mtxen_pad_o), 
	.mtxerr_pad_o(mtxerr_pad_o), 

  //RX
 	.mrx_clk_pad_i(mrx_clk_pad_i), 
	.mrxd_pad_i(mrxd_pad_i), 
	.mrxdv_pad_i(mrxdv_pad_i), 
	.mrxerr_pad_i(mrxerr_pad_i), 
	.mcoll_pad_i(mcoll_pad_i), 
	.mcrs_pad_i(mcrs_pad_i), 
  
  // MIIM
  	.mdc_pad_o(mdc_pad_o), 
	.md_pad_i(md_pad_i), 
	.md_pad_o(md_pad_o), 
	.md_padoe_o(md_padoe_o), 
	.int_o(int_o)

  // Bist
`ifdef ETH_BIST
  ,
  // debug chain signals
  	.mbist_si_i(mbist_si_i),       // bist scan serial in
  	.mbist_so_o(mbist_so_o),       // bist scan serial out
  	.mbist_ctrl_i(mbist_ctrl_i)        // bist chain shift control
`endif

);

assign m_wb_adr_o= {2'b00,m_wb_adr_o_in_byte[31:2]};

endmodule
