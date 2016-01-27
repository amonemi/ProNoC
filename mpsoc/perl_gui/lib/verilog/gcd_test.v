module gcd_test #(
    	parameter	ram_RAM_TAG_STRING="00" ,
	parameter	aeMB_AEMB_BSF= 1 ,
	parameter	aeMB_AEMB_MUL= 1 ,
	parameter	display_PORT_WIDTH=28
)(
	aeMB_sys_ena_i, 
	ss_clk_in, 
	ss_reset_in, 
	display_port_o
);
 	localparam	ram_Aw=13;
	localparam	ram_Dw=32;
	localparam	ram_FPGA_FAMILY="ALTERA";
	localparam	ram_SELw=4;
	localparam	ram_TAGw=3;

 	localparam	aeMB_AEMB_DWB= 32;
	localparam	aeMB_AEMB_ICH= 11;
	localparam	aeMB_AEMB_IDX= 6;
	localparam	aeMB_AEMB_IWB= 32;
	localparam	aeMB_AEMB_XWB= 7;

 
 	localparam	gcd_Aw=5;
	localparam	gcd_Dw=32;
	localparam	gcd_SELw=4;
	localparam	gcd_TAGw=3;

 	localparam	display_Aw=    2;
	localparam	display_Dw=    32;
	localparam	display_SELw=    4;
	localparam	display_TAGw=    3;

 	localparam	bus_Aw=	32;
	localparam	bus_Dw=	32;
	localparam	bus_M=2;
	localparam	bus_S=3;
	localparam	bus_SELw=	4;
	localparam	bus_TAGw=	3    ;

 	input			aeMB_sys_ena_i;

 	input			ss_clk_in;
 	input			ss_reset_in;

 	output	 [ display_PORT_WIDTH-1     :   0    ] display_port_o;

 	wire			 ram_plug_clk_0_clk_i;
 	wire			 ram_plug_reset_0_reset_i;
 	wire			 ram_plug_wb_slave_0_ack_o;
 	wire	[ ram_Aw-1       :   0 ] ram_plug_wb_slave_0_adr_i;
 	wire			 ram_plug_wb_slave_0_cyc_i;
 	wire	[ ram_Dw-1       :   0 ] ram_plug_wb_slave_0_dat_i;
 	wire	[ ram_Dw-1       :   0 ] ram_plug_wb_slave_0_dat_o;
 	wire			 ram_plug_wb_slave_0_err_o;
 	wire			 ram_plug_wb_slave_0_rty_o;
 	wire	[ ram_SELw-1     :   0 ] ram_plug_wb_slave_0_sel_i;
 	wire			 ram_plug_wb_slave_0_stb_i;
 	wire	[ ram_TAGw-1     :   0 ] ram_plug_wb_slave_0_tag_i;
 	wire			 ram_plug_wb_slave_0_we_i;

 	wire			 aeMB_plug_clk_0_clk_i;
 	wire			 aeMB_plug_wb_master_1_ack_i;
 	wire	[ 31:0 ] aeMB_plug_wb_master_1_adr_o;
 	wire			 aeMB_plug_wb_master_1_cyc_o;
 	wire	[ 31:0 ] aeMB_plug_wb_master_1_dat_i;
 	wire	[ 31:0 ] aeMB_plug_wb_master_1_dat_o;
 	wire			 aeMB_plug_wb_master_1_err_i;
 	wire			 aeMB_plug_wb_master_1_rty_i;
 	wire	[ 3:0 ] aeMB_plug_wb_master_1_sel_o;
 	wire			 aeMB_plug_wb_master_1_stb_o;
 	wire	[ 2:0 ] aeMB_plug_wb_master_1_tag_o;
 	wire			 aeMB_plug_wb_master_1_we_o;
 	wire			 aeMB_plug_wb_master_0_ack_i;
 	wire	[ 31:0 ] aeMB_plug_wb_master_0_adr_o;
 	wire			 aeMB_plug_wb_master_0_cyc_o;
 	wire	[ 31:0 ] aeMB_plug_wb_master_0_dat_i;
 	wire	[ 31:0 ] aeMB_plug_wb_master_0_dat_o;
 	wire			 aeMB_plug_wb_master_0_err_i;
 	wire			 aeMB_plug_wb_master_0_rty_i;
 	wire	[ 3:0 ] aeMB_plug_wb_master_0_sel_o;
 	wire			 aeMB_plug_wb_master_0_stb_o;
 	wire	[ 2:0 ] aeMB_plug_wb_master_0_tag_o;
 	wire			 aeMB_plug_wb_master_0_we_o;
 	wire			 aeMB_plug_reset_0_reset_i;
 	wire			 aeMB_plug_interrupt_cpu_0_int_i;

 	wire			 ss_socket_clk_0_clk_o;
 	wire			 ss_socket_reset_0_reset_o;

 	wire			 gcd_plug_clk_0_clk_i;
 	wire			 gcd_plug_reset_0_reset_i;
 	wire			 gcd_plug_wb_slave_0_ack_o;
 	wire	[ gcd_Aw-1       :   0 ] gcd_plug_wb_slave_0_adr_i;
 	wire			 gcd_plug_wb_slave_0_cyc_i;
 	wire	[ gcd_Dw-1       :   0 ] gcd_plug_wb_slave_0_dat_i;
 	wire	[ gcd_Dw-1       :   0 ] gcd_plug_wb_slave_0_dat_o;
 	wire			 gcd_plug_wb_slave_0_err_o;
 	wire			 gcd_plug_wb_slave_0_rty_o;
 	wire	[ gcd_SELw-1     :   0 ] gcd_plug_wb_slave_0_sel_i;
 	wire			 gcd_plug_wb_slave_0_stb_i;
 	wire	[ gcd_TAGw-1     :   0 ] gcd_plug_wb_slave_0_tag_i;
 	wire			 gcd_plug_wb_slave_0_we_i;

 	wire			 display_plug_clk_0_clk_i;
 	wire			 display_plug_reset_0_reset_i;
 	wire			 display_plug_wb_slave_0_ack_o;
 	wire	[ display_Aw-1       :   0 ] display_plug_wb_slave_0_adr_i;
 	wire			 display_plug_wb_slave_0_cyc_i;
 	wire	[ display_Dw-1       :   0 ] display_plug_wb_slave_0_dat_i;
 	wire	[ display_Dw-1       :   0 ] display_plug_wb_slave_0_dat_o;
 	wire			 display_plug_wb_slave_0_err_o;
 	wire			 display_plug_wb_slave_0_rty_o;
 	wire	[ display_SELw-1     :   0 ] display_plug_wb_slave_0_sel_i;
 	wire			 display_plug_wb_slave_0_stb_i;
 	wire	[ display_TAGw-1     :   0 ] display_plug_wb_slave_0_tag_i;
 	wire			 display_plug_wb_slave_0_we_i;

 	wire			 bus_plug_clk_0_clk_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_ack_o;
 	wire			 bus_socket_wb_master_1_ack_o;
 	wire			 bus_socket_wb_master_0_ack_o;
 	wire	[ (bus_Aw*bus_M)-1      :   0 ] bus_socket_wb_master_array_adr_i;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_master_1_adr_i;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_master_0_adr_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_cyc_i;
 	wire			 bus_socket_wb_master_1_cyc_i;
 	wire			 bus_socket_wb_master_0_cyc_i;
 	wire	[ (bus_Dw*bus_M)-1      :   0 ] bus_socket_wb_master_array_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_1_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_0_dat_i;
 	wire	[ (bus_Dw*bus_M)-1      :   0 ] bus_socket_wb_master_array_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_1_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_0_dat_o;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_err_o;
 	wire			 bus_socket_wb_master_1_err_o;
 	wire			 bus_socket_wb_master_0_err_o;
 	wire	[ bus_Aw-1       :   0 ] bus_socket_wb_addr_map_0_grant_addr;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_rty_o;
 	wire			 bus_socket_wb_master_1_rty_o;
 	wire			 bus_socket_wb_master_0_rty_o;
 	wire	[ (bus_SELw*bus_M)-1    :   0 ] bus_socket_wb_master_array_sel_i;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_master_1_sel_i;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_master_0_sel_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_stb_i;
 	wire			 bus_socket_wb_master_1_stb_i;
 	wire			 bus_socket_wb_master_0_stb_i;
 	wire	[ (bus_TAGw*bus_M)-1    :   0 ] bus_socket_wb_master_array_tag_i;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_master_1_tag_i;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_master_0_tag_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_we_i;
 	wire			 bus_socket_wb_master_1_we_i;
 	wire			 bus_socket_wb_master_0_we_i;
 	wire			 bus_plug_reset_0_reset_i;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_ack_i;
 	wire			 bus_socket_wb_slave_2_ack_i;
 	wire			 bus_socket_wb_slave_1_ack_i;
 	wire			 bus_socket_wb_slave_0_ack_i;
 	wire	[ (bus_Aw*bus_S)-1      :   0 ] bus_socket_wb_slave_array_adr_o;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_slave_2_adr_o;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_slave_1_adr_o;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_slave_0_adr_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_cyc_o;
 	wire			 bus_socket_wb_slave_2_cyc_o;
 	wire			 bus_socket_wb_slave_1_cyc_o;
 	wire			 bus_socket_wb_slave_0_cyc_o;
 	wire	[ (bus_Dw*bus_S)-1      :   0 ] bus_socket_wb_slave_array_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_2_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_1_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_0_dat_i;
 	wire	[ (bus_Dw*bus_S)-1      :   0 ] bus_socket_wb_slave_array_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_2_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_1_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_0_dat_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_err_i;
 	wire			 bus_socket_wb_slave_2_err_i;
 	wire			 bus_socket_wb_slave_1_err_i;
 	wire			 bus_socket_wb_slave_0_err_i;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_rty_i;
 	wire			 bus_socket_wb_slave_2_rty_i;
 	wire			 bus_socket_wb_slave_1_rty_i;
 	wire			 bus_socket_wb_slave_0_rty_i;
 	wire	[ (bus_SELw*bus_S)-1    :   0 ] bus_socket_wb_slave_array_sel_o;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_slave_2_sel_o;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_slave_1_sel_o;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_slave_0_sel_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_addr_map_0_sel_one_hot;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_stb_o;
 	wire			 bus_socket_wb_slave_2_stb_o;
 	wire			 bus_socket_wb_slave_1_stb_o;
 	wire			 bus_socket_wb_slave_0_stb_o;
 	wire	[ (bus_TAGw*bus_S)-1    :   0 ] bus_socket_wb_slave_array_tag_o;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_slave_2_tag_o;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_slave_1_tag_o;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_slave_0_tag_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_we_o;
 	wire			 bus_socket_wb_slave_2_we_o;
 	wire			 bus_socket_wb_slave_1_we_o;
 	wire			 bus_socket_wb_slave_0_we_o;

 prog_ram_single_port #(
 		.Aw(ram_Aw),
		.Dw(ram_Dw),
		.FPGA_FAMILY(ram_FPGA_FAMILY),
		.RAM_TAG_STRING(ram_RAM_TAG_STRING),
		.SELw(ram_SELw),
		.TAGw(ram_TAGw)

	)  ram 	(
		.clk(ram_plug_clk_0_clk_i),
		.reset(ram_plug_reset_0_reset_i),
		.sa_ack_o(ram_plug_wb_slave_0_ack_o),
		.sa_addr_i(ram_plug_wb_slave_0_adr_i),
		.sa_cyc_i(ram_plug_wb_slave_0_cyc_i),
		.sa_dat_i(ram_plug_wb_slave_0_dat_i),
		.sa_dat_o(ram_plug_wb_slave_0_dat_o),
		.sa_err_o(ram_plug_wb_slave_0_err_o),
		.sa_rty_o(ram_plug_wb_slave_0_rty_o),
		.sa_sel_i(ram_plug_wb_slave_0_sel_i),
		.sa_stb_i(ram_plug_wb_slave_0_stb_i),
		.sa_tag_i(ram_plug_wb_slave_0_tag_i),
		.sa_we_i(ram_plug_wb_slave_0_we_i)
	);
 aeMB_top #(
 		.AEMB_BSF(aeMB_AEMB_BSF),
		.AEMB_DWB(aeMB_AEMB_DWB),
		.AEMB_ICH(aeMB_AEMB_ICH),
		.AEMB_IDX(aeMB_AEMB_IDX),
		.AEMB_IWB(aeMB_AEMB_IWB),
		.AEMB_MUL(aeMB_AEMB_MUL),
		.AEMB_XWB(aeMB_AEMB_XWB)

	)  aeMB 	(
		.clk(aeMB_plug_clk_0_clk_i),
		.dwb_ack_i(aeMB_plug_wb_master_1_ack_i),
		.dwb_adr_o(aeMB_plug_wb_master_1_adr_o),
		.dwb_cyc_o(aeMB_plug_wb_master_1_cyc_o),
		.dwb_dat_i(aeMB_plug_wb_master_1_dat_i),
		.dwb_dat_o(aeMB_plug_wb_master_1_dat_o),
		.dwb_err_i(aeMB_plug_wb_master_1_err_i),
		.dwb_rty_i(aeMB_plug_wb_master_1_rty_i),
		.dwb_sel_o(aeMB_plug_wb_master_1_sel_o),
		.dwb_stb_o(aeMB_plug_wb_master_1_stb_o),
		.dwb_tag_o(aeMB_plug_wb_master_1_tag_o),
		.dwb_wre_o(aeMB_plug_wb_master_1_we_o),
		.iwb_ack_i(aeMB_plug_wb_master_0_ack_i),
		.iwb_adr_o(aeMB_plug_wb_master_0_adr_o),
		.iwb_cyc_o(aeMB_plug_wb_master_0_cyc_o),
		.iwb_dat_i(aeMB_plug_wb_master_0_dat_i),
		.iwb_dat_o(aeMB_plug_wb_master_0_dat_o),
		.iwb_err_i(aeMB_plug_wb_master_0_err_i),
		.iwb_rty_i(aeMB_plug_wb_master_0_rty_i),
		.iwb_sel_o(aeMB_plug_wb_master_0_sel_o),
		.iwb_stb_o(aeMB_plug_wb_master_0_stb_o),
		.iwb_tag_o(aeMB_plug_wb_master_0_tag_o),
		.iwb_wre_o(aeMB_plug_wb_master_0_we_o),
		.reset(aeMB_plug_reset_0_reset_i),
		.sys_ena_i(aeMB_sys_ena_i),
		.sys_int_i(aeMB_plug_interrupt_cpu_0_int_i)
	);
 clk_source  ss 	(
		.clk_in(ss_clk_in),
		.clk_out(ss_socket_clk_0_clk_o),
		.reset_in(ss_reset_in),
		.reset_out(ss_socket_reset_0_reset_o)
	);
 gcd_top #(
 		.Aw(gcd_Aw),
		.Dw(gcd_Dw),
		.SELw(gcd_SELw),
		.TAGw(gcd_TAGw)

	)  gcd 	(
		.clk(gcd_plug_clk_0_clk_i),
		.reset(gcd_plug_reset_0_reset_i),
		.s_ack_o(gcd_plug_wb_slave_0_ack_o),
		.s_addr_i(gcd_plug_wb_slave_0_adr_i),
		.s_cyc_i(gcd_plug_wb_slave_0_cyc_i),
		.s_dat_i(gcd_plug_wb_slave_0_dat_i),
		.s_dat_o(gcd_plug_wb_slave_0_dat_o),
		.s_err_o(gcd_plug_wb_slave_0_err_o),
		.s_rty_o(gcd_plug_wb_slave_0_rty_o),
		.s_sel_i(gcd_plug_wb_slave_0_sel_i),
		.s_stb_i(gcd_plug_wb_slave_0_stb_i),
		.s_tag_i(gcd_plug_wb_slave_0_tag_i),
		.s_we_i(gcd_plug_wb_slave_0_we_i)
	);
 gpo #(
 		.Aw(display_Aw),
		.Dw(display_Dw),
		.PORT_WIDTH(display_PORT_WIDTH),
		.SELw(display_SELw),
		.TAGw(display_TAGw)

	)  display 	(
		.clk(display_plug_clk_0_clk_i),
		.port_o(display_port_o),
		.reset(display_plug_reset_0_reset_i),
		.sa_ack_o(display_plug_wb_slave_0_ack_o),
		.sa_addr_i(display_plug_wb_slave_0_adr_i),
		.sa_cyc_i(display_plug_wb_slave_0_cyc_i),
		.sa_dat_i(display_plug_wb_slave_0_dat_i),
		.sa_dat_o(display_plug_wb_slave_0_dat_o),
		.sa_err_o(display_plug_wb_slave_0_err_o),
		.sa_rty_o(display_plug_wb_slave_0_rty_o),
		.sa_sel_i(display_plug_wb_slave_0_sel_i),
		.sa_stb_i(display_plug_wb_slave_0_stb_i),
		.sa_tag_i(display_plug_wb_slave_0_tag_i),
		.sa_we_i(display_plug_wb_slave_0_we_i)
	);
 wishbone_bus #(
 		.Aw(bus_Aw),
		.Dw(bus_Dw),
		.M(bus_M),
		.S(bus_S),
		.SELw(bus_SELw),
		.TAGw(bus_TAGw)

	)  bus 	(
		.clk(bus_plug_clk_0_clk_i),
		.m_ack_o_all(bus_socket_wb_master_array_ack_o),
		.m_adr_i_all(bus_socket_wb_master_array_adr_i),
		.m_cyc_i_all(bus_socket_wb_master_array_cyc_i),
		.m_dat_i_all(bus_socket_wb_master_array_dat_i),
		.m_dat_o_all(bus_socket_wb_master_array_dat_o),
		.m_err_o_all(bus_socket_wb_master_array_err_o),
		.m_grant_addr(bus_socket_wb_addr_map_0_grant_addr),
		.m_rty_o_all(bus_socket_wb_master_array_rty_o),
		.m_sel_i_all(bus_socket_wb_master_array_sel_i),
		.m_stb_i_all(bus_socket_wb_master_array_stb_i),
		.m_tag_i_all(bus_socket_wb_master_array_tag_i),
		.m_we_i_all(bus_socket_wb_master_array_we_i),
		.reset(bus_plug_reset_0_reset_i),
		.s_ack_i_all(bus_socket_wb_slave_array_ack_i),
		.s_adr_o_all(bus_socket_wb_slave_array_adr_o),
		.s_cyc_o_all(bus_socket_wb_slave_array_cyc_o),
		.s_dat_i_all(bus_socket_wb_slave_array_dat_i),
		.s_dat_o_all(bus_socket_wb_slave_array_dat_o),
		.s_err_i_all(bus_socket_wb_slave_array_err_i),
		.s_rty_i_all(bus_socket_wb_slave_array_rty_i),
		.s_sel_o_all(bus_socket_wb_slave_array_sel_o),
		.s_sel_one_hot(bus_socket_wb_addr_map_0_sel_one_hot),
		.s_stb_o_all(bus_socket_wb_slave_array_stb_o),
		.s_tag_o_all(bus_socket_wb_slave_array_tag_o),
		.s_we_o_all(bus_socket_wb_slave_array_we_o)
	);
 
 	assign  ram_plug_clk_0_clk_i = ss_socket_clk_0_clk_o;
 	assign  ram_plug_reset_0_reset_i = ss_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_0_ack_i  = ram_plug_wb_slave_0_ack_o;
 	assign  ram_plug_wb_slave_0_adr_i = bus_socket_wb_slave_0_adr_o;
 	assign  ram_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_0_cyc_o;
 	assign  ram_plug_wb_slave_0_dat_i = bus_socket_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_0_dat_i  = ram_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_0_err_i  = ram_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_0_rty_i  = ram_plug_wb_slave_0_rty_o;
 	assign  ram_plug_wb_slave_0_sel_i = bus_socket_wb_slave_0_sel_o;
 	assign  ram_plug_wb_slave_0_stb_i = bus_socket_wb_slave_0_stb_o;
 	assign  ram_plug_wb_slave_0_tag_i = bus_socket_wb_slave_0_tag_o;
 	assign  ram_plug_wb_slave_0_we_i = bus_socket_wb_slave_0_we_o;

 
 	assign  aeMB_plug_clk_0_clk_i = ss_socket_clk_0_clk_o;
 	assign  aeMB_plug_wb_master_1_ack_i = bus_socket_wb_master_1_ack_o;
 	assign  bus_socket_wb_master_1_adr_i  = aeMB_plug_wb_master_1_adr_o;
 	assign  bus_socket_wb_master_1_cyc_i  = aeMB_plug_wb_master_1_cyc_o;
 	assign  aeMB_plug_wb_master_1_dat_i = bus_socket_wb_master_1_dat_o;
 	assign  bus_socket_wb_master_1_dat_i  = aeMB_plug_wb_master_1_dat_o;
 	assign  aeMB_plug_wb_master_1_err_i = bus_socket_wb_master_1_err_o;
 	assign  aeMB_plug_wb_master_1_rty_i = bus_socket_wb_master_1_rty_o;
 	assign  bus_socket_wb_master_1_sel_i  = aeMB_plug_wb_master_1_sel_o;
 	assign  bus_socket_wb_master_1_stb_i  = aeMB_plug_wb_master_1_stb_o;
 	assign  bus_socket_wb_master_1_tag_i  = aeMB_plug_wb_master_1_tag_o;
 	assign  bus_socket_wb_master_1_we_i  = aeMB_plug_wb_master_1_we_o;
 	assign  aeMB_plug_wb_master_0_ack_i = bus_socket_wb_master_0_ack_o;
 	assign  bus_socket_wb_master_0_adr_i  = aeMB_plug_wb_master_0_adr_o;
 	assign  bus_socket_wb_master_0_cyc_i  = aeMB_plug_wb_master_0_cyc_o;
 	assign  aeMB_plug_wb_master_0_dat_i = bus_socket_wb_master_0_dat_o;
 	assign  bus_socket_wb_master_0_dat_i  = aeMB_plug_wb_master_0_dat_o;
 	assign  aeMB_plug_wb_master_0_err_i = bus_socket_wb_master_0_err_o;
 	assign  aeMB_plug_wb_master_0_rty_i = bus_socket_wb_master_0_rty_o;
 	assign  bus_socket_wb_master_0_sel_i  = aeMB_plug_wb_master_0_sel_o;
 	assign  bus_socket_wb_master_0_stb_i  = aeMB_plug_wb_master_0_stb_o;
 	assign  bus_socket_wb_master_0_tag_i  = aeMB_plug_wb_master_0_tag_o;
 	assign  bus_socket_wb_master_0_we_i  = aeMB_plug_wb_master_0_we_o;
 	assign  aeMB_plug_reset_0_reset_i = ss_socket_reset_0_reset_o;

 

 
 	assign  gcd_plug_clk_0_clk_i = ss_socket_clk_0_clk_o;
 	assign  gcd_plug_reset_0_reset_i = ss_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_1_ack_i  = gcd_plug_wb_slave_0_ack_o;
 	assign  gcd_plug_wb_slave_0_adr_i = bus_socket_wb_slave_1_adr_o;
 	assign  gcd_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_1_cyc_o;
 	assign  gcd_plug_wb_slave_0_dat_i = bus_socket_wb_slave_1_dat_o;
 	assign  bus_socket_wb_slave_1_dat_i  = gcd_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_1_err_i  = gcd_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_1_rty_i  = gcd_plug_wb_slave_0_rty_o;
 	assign  gcd_plug_wb_slave_0_sel_i = bus_socket_wb_slave_1_sel_o;
 	assign  gcd_plug_wb_slave_0_stb_i = bus_socket_wb_slave_1_stb_o;
 	assign  gcd_plug_wb_slave_0_tag_i = bus_socket_wb_slave_1_tag_o;
 	assign  gcd_plug_wb_slave_0_we_i = bus_socket_wb_slave_1_we_o;

 
 	assign  display_plug_clk_0_clk_i = ss_socket_clk_0_clk_o;
 	assign  display_plug_reset_0_reset_i = ss_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_2_ack_i  = display_plug_wb_slave_0_ack_o;
 	assign  display_plug_wb_slave_0_adr_i = bus_socket_wb_slave_2_adr_o;
 	assign  display_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_2_cyc_o;
 	assign  display_plug_wb_slave_0_dat_i = bus_socket_wb_slave_2_dat_o;
 	assign  bus_socket_wb_slave_2_dat_i  = display_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_2_err_i  = display_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_2_rty_i  = display_plug_wb_slave_0_rty_o;
 	assign  display_plug_wb_slave_0_sel_i = bus_socket_wb_slave_2_sel_o;
 	assign  display_plug_wb_slave_0_stb_i = bus_socket_wb_slave_2_stb_o;
 	assign  display_plug_wb_slave_0_tag_i = bus_socket_wb_slave_2_tag_o;
 	assign  display_plug_wb_slave_0_we_i = bus_socket_wb_slave_2_we_o;

 
 	assign  bus_plug_clk_0_clk_i = ss_socket_clk_0_clk_o;
 	assign  bus_plug_reset_0_reset_i = ss_socket_reset_0_reset_o;

 	assign {bus_socket_wb_master_1_ack_o ,bus_socket_wb_master_0_ack_o} =bus_socket_wb_master_array_ack_o;
 	assign bus_socket_wb_master_array_adr_i ={bus_socket_wb_master_1_adr_i ,bus_socket_wb_master_0_adr_i};
 	assign bus_socket_wb_master_array_cyc_i ={bus_socket_wb_master_1_cyc_i ,bus_socket_wb_master_0_cyc_i};
 	assign bus_socket_wb_master_array_dat_i ={bus_socket_wb_master_1_dat_i ,bus_socket_wb_master_0_dat_i};
 	assign {bus_socket_wb_master_1_dat_o ,bus_socket_wb_master_0_dat_o} =bus_socket_wb_master_array_dat_o;
 	assign {bus_socket_wb_master_1_err_o ,bus_socket_wb_master_0_err_o} =bus_socket_wb_master_array_err_o;
 	assign {bus_socket_wb_master_1_rty_o ,bus_socket_wb_master_0_rty_o} =bus_socket_wb_master_array_rty_o;
 	assign bus_socket_wb_master_array_sel_i ={bus_socket_wb_master_1_sel_i ,bus_socket_wb_master_0_sel_i};
 	assign bus_socket_wb_master_array_stb_i ={bus_socket_wb_master_1_stb_i ,bus_socket_wb_master_0_stb_i};
 	assign bus_socket_wb_master_array_tag_i ={bus_socket_wb_master_1_tag_i ,bus_socket_wb_master_0_tag_i};
 	assign bus_socket_wb_master_array_we_i ={bus_socket_wb_master_1_we_i ,bus_socket_wb_master_0_we_i};
 	assign bus_socket_wb_slave_array_ack_i ={bus_socket_wb_slave_2_ack_i ,bus_socket_wb_slave_1_ack_i ,bus_socket_wb_slave_0_ack_i};
 	assign {bus_socket_wb_slave_2_adr_o ,bus_socket_wb_slave_1_adr_o ,bus_socket_wb_slave_0_adr_o} =bus_socket_wb_slave_array_adr_o;
 	assign {bus_socket_wb_slave_2_cyc_o ,bus_socket_wb_slave_1_cyc_o ,bus_socket_wb_slave_0_cyc_o} =bus_socket_wb_slave_array_cyc_o;
 	assign bus_socket_wb_slave_array_dat_i ={bus_socket_wb_slave_2_dat_i ,bus_socket_wb_slave_1_dat_i ,bus_socket_wb_slave_0_dat_i};
 	assign {bus_socket_wb_slave_2_dat_o ,bus_socket_wb_slave_1_dat_o ,bus_socket_wb_slave_0_dat_o} =bus_socket_wb_slave_array_dat_o;
 	assign bus_socket_wb_slave_array_err_i ={bus_socket_wb_slave_2_err_i ,bus_socket_wb_slave_1_err_i ,bus_socket_wb_slave_0_err_i};
 	assign bus_socket_wb_slave_array_rty_i ={bus_socket_wb_slave_2_rty_i ,bus_socket_wb_slave_1_rty_i ,bus_socket_wb_slave_0_rty_i};
 	assign {bus_socket_wb_slave_2_sel_o ,bus_socket_wb_slave_1_sel_o ,bus_socket_wb_slave_0_sel_o} =bus_socket_wb_slave_array_sel_o;
 	assign {bus_socket_wb_slave_2_stb_o ,bus_socket_wb_slave_1_stb_o ,bus_socket_wb_slave_0_stb_o} =bus_socket_wb_slave_array_stb_o;
 	assign {bus_socket_wb_slave_2_tag_o ,bus_socket_wb_slave_1_tag_o ,bus_socket_wb_slave_0_tag_o} =bus_socket_wb_slave_array_tag_o;
 	assign {bus_socket_wb_slave_2_we_o ,bus_socket_wb_slave_1_we_o ,bus_socket_wb_slave_0_we_o} =bus_socket_wb_slave_array_we_o;

 
//Wishbone slave address match
 	assign bus_socket_wb_addr_map_0_sel_one_hot[0]= ((bus_socket_wb_addr_map_0_grant_addr >= 32'h00000000)   & (bus_socket_wb_addr_map_0_grant_addr< 32'h00003fff));
 	assign bus_socket_wb_addr_map_0_sel_one_hot[1]= ((bus_socket_wb_addr_map_0_grant_addr >= 32'h2e000000)   & (bus_socket_wb_addr_map_0_grant_addr< 32'h2e000007));
 	assign bus_socket_wb_addr_map_0_sel_one_hot[2]= ((bus_socket_wb_addr_map_0_grant_addr >= 32'h24400000)   & (bus_socket_wb_addr_map_0_grant_addr< 32'h24400007));
 endmodule

