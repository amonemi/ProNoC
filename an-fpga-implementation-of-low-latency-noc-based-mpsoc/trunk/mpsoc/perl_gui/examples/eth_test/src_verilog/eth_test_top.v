module eth_test_top(
//////////// CLOCK //////////
	CLOCK_50,

	//////////// KEY //////////
	KEY,

	LEDG,

		
	//////////// Ethernet 0 //////////
	ENET0_GTX_CLK,
	ENET0_INT_N,
	ENET0_LINK100,
	ENET0_MDC,
	ENET0_MDIO,
	ENET0_RESET_N,
	ENET0_RX_CLK,
	ENET0_RX_COL,
	ENET0_RX_CRS,
	ENET0_RX_DATA,
	ENET0_RX_DV,
	ENET0_RX_ER,
	ENET0_TX_CLK,
	ENET0_TX_DATA,
	ENET0_TX_EN,
	ENET0_TX_ER,
	ENETCLK_25



);




//////////// CLOCK //////////
input		          		CLOCK_50;


output 		[0:0]			LEDG;
input  		[0:0]			KEY;



//////////// Ethernet 0 //////////
output		          	ENET0_GTX_CLK;		// GMII Transmit Clock
input		          		ENET0_INT_N; 			// Interrupt open drain output
input		          		ENET0_LINK100; 		// Parallel LED output of 100BASE-TX link
output		          	ENET0_MDC; 			// Management data clock reference
inout		          		ENET0_MDIO;				// Management Data
output		          	ENET0_RESET_N;		// Hardware reset Signal
input		          		ENET0_RX_CLK;			// GMII/MII Receive clock
input		          		ENET0_RX_COL;			// GMII/MII Collision
input		          		ENET0_RX_CRS;			// GMII/MII Carrier sense
input		     [3:0]		ENET0_RX_DATA;			// GMII/MII Receive data
input		          		ENET0_RX_DV;			// GMII/MII Receive data valid
input		          		ENET0_RX_ER;			// GMII/MII Receive error
input		          		ENET0_TX_CLK;			// MII Transmit Clock
output		     [3:0]	ENET0_TX_DATA;		// MII Transmit Data
output		          	ENET0_TX_EN;		// GMII/MII Transmit enable
output		          	ENET0_TX_ER;		// GMII/MII Transmit error

input		          		ENETCLK_25; // Internal Clock (SHARED) 25MHZ




//=======================================================
//  REG/WIRE declarations
//=======================================================


	
	
	
	wire reset_in,jtag_reset,reset;

	assign  reset_in	=	~KEY[0];
	assign  LEDG[0]		=	reset;
	assign  reset		=	(jtag_reset | reset_in);

// a reset source which can be controled using altera in-system source editor
	
	reset_jtag the_reset(
		.probe(),
		.source(jtag_reset)
	);


wire md_we, md_out,md_in;

	eth_test  soc(
		.aeMB_sys_ena_i(1'b1), 
		.ss_clk_in(CLOCK_50), 
		.ss_reset_in(reset), 
		.ethmac_mcoll_pad_i(ENET0_RX_COL), 
		.ethmac_mcrs_pad_i(ENET0_RX_CRS), 
		.ethmac_md_pad_i(md_in), 
		.ethmac_md_pad_o(md_out), 
		.ethmac_md_padoe_o(md_we), 
		.ethmac_mdc_pad_o(ENET0_MDC), 
		.ethmac_mrx_clk_pad_i(ENET0_RX_CLK), 
		.ethmac_mrxd_pad_i(ENET0_RX_DATA), 
		.ethmac_mrxdv_pad_i(ENET0_RX_DV), 
		.ethmac_mrxerr_pad_i(ENET0_RX_ER), 
		.ethmac_mtx_clk_pad_i(ENET0_TX_CLK), 
		.ethmac_mtxd_pad_o(ENET0_TX_DATA), 
		.ethmac_mtxen_pad_o(ENET0_TX_EN), 
		.ethmac_mtxerr_pad_o(ENET0_TX_ER),
		.uart_dataavailable(), 
		.uart_readyfordata() 

);

//convert tristate pin to two separate lines:

assign ENET0_MDIO = md_we? md_out:1'bz;
assign md_in = ENET0_MDIO;
assign ENET0_RESET_N = ~reset;



endmodule

