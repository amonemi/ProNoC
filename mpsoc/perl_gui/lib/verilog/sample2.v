module sample2 #(
    	parameter	Altera_ram0_Aw=13 ,
	parameter	Altera_ram0_RAM_TAG_STRING="00" ,
	parameter	aeMB0_AEMB_MUL= 1 ,
	parameter	aeMB0_AEMB_BSF= 1 ,
	parameter	gpi0_PORT_WIDTH=   1 ,
	parameter	gpo0_PORT_WIDTH=   1 ,
	parameter	jtag_intfc0_WR_RAMw=8 ,
	parameter	ni0_NY= 2 ,
	parameter	ni0_NX= 2 ,
	parameter	ni0_V= 4 ,
	parameter	ni0_B= 4 ,
	parameter	ni0_DEBUG_EN=   1 ,
	parameter	ni0_ROUTE_NAME="XY"      ,
	parameter	ni0_TOPOLOGY=    "MESH"
)(
	aeMB0_sys_ena_i, 
	aeMB0_sys_int_i, 
	clk_source0_clk_in, 
	clk_source0_reset_in, 
	gpi0_port_i, 
	gpo0_port_o, 
	jtag_intfc0_irq, 
	jtag_intfc0_reset_all_o, 
	jtag_intfc0_reset_cpus_o, 
	ni0_credit_in, 
	ni0_credit_out, 
	ni0_current_x, 
	ni0_current_y, 
	ni0_flit_in, 
	ni0_flit_in_wr, 
	ni0_flit_out, 
	ni0_flit_out_wr, 
	ni0_irq
);
  
  	function integer log2;
  		input integer number; begin	
          	log2=0;	
          	while(2**log2<number) begin	
        		  	log2=log2+1;	
         		end	
        		end	
     	endfunction // log2 
  	localparam	Altera_ram0_FPGA_FAMILY="ALTERA";
	localparam	Altera_ram0_TAGw=3;
	localparam	Altera_ram0_Dw=32;
	localparam	Altera_ram0_SELw=4;

 	localparam	aeMB0_AEMB_XWB= 7;
	localparam	aeMB0_AEMB_IDX= 6;
	localparam	aeMB0_AEMB_IWB= 32;
	localparam	aeMB0_AEMB_ICH= 11;
	localparam	aeMB0_AEMB_DWB= 32;

 
 	localparam	gpi0_Dw=   32;
	localparam	gpi0_Aw=   2;
	localparam	gpi0_TAGw=   3;
	localparam	gpi0_SELw=   4;

 	localparam	gpo0_Dw=    32;
	localparam	gpo0_Aw=    2;
	localparam	gpo0_TAGw=    3;
	localparam	gpo0_SELw=    4;

 	localparam	jtag_intfc0_NI_BASE_ADDR=ni0_BASE_ADDR;
	localparam	jtag_intfc0_JTAG_BASE_ADDR=jtag_intfc0_BASE_ADDR;
	localparam	jtag_intfc0_WR_RAM_TAG="J_WR";
	localparam	jtag_intfc0_RD_RAM_TAG="J_RD";
	localparam	jtag_intfc0_Dw=32;
	localparam	jtag_intfc0_S_Aw=jtag_intfc0_WR_RAMw+1;
	localparam	jtag_intfc0_M_Aw=32;
	localparam	jtag_intfc0_TAGw=3;
	localparam	jtag_intfc0_SELw=4;

 	localparam	ni0_Dw=32;
	localparam	ni0_TAGw=   3;
	localparam	ni0_M_Aw=32;
	localparam	ni0_Fpay= 32;
	localparam	ni0_SELw=   4    ;
	localparam	ni0_ROUTE_TYPE=   (ni0_ROUTE_NAME == "XY" || ni0_ROUTE_NAME == "TRANC_XY" )?    "DETERMINISTIC" : 
			            (ni0_ROUTE_NAME == "DUATO" || ni0_ROUTE_NAME == "TRANC_DUATO" )?   "FULL_ADAPTIVE": "PAR_ADAPTIVE" ;
	localparam	ni0_P= 5;
	localparam	ni0_S_Aw=   3;
	localparam	ni0_Fw=2 + ni0_V + ni0_Fpay;
	localparam	ni0_Xw=log2( ni0_NX );
	localparam	ni0_Yw=log2( ni0_NY );

 	localparam	bus_S=5;
	localparam	bus_M=	4;
	localparam	bus_Aw=	32;
	localparam	bus_TAGw=	3    ;
	localparam	bus_SELw=	4;
	localparam	bus_Dw=	32;

 
//Wishbone slave base address based on instance name
 	localparam 	Altera_ram0_BASE_ADDR	=	32'h00000000;
 	localparam 	Altera_ram0_END_ADDR	=	32'h00003fff;
 	localparam 	gpi0_BASE_ADDR	=	32'h24400000;
 	localparam 	gpi0_END_ADDR	=	32'h24400007;
 	localparam 	gpo0_BASE_ADDR	=	32'h24400008;
 	localparam 	gpo0_END_ADDR	=	32'h2440000f;
 	localparam 	jtag_intfc0_BASE_ADDR	=	32'h24000000;
 	localparam 	jtag_intfc0_END_ADDR	=	32'h240003ff;
 	localparam 	ni0_BASE_ADDR	=	32'h2e000000;
 	localparam 	ni0_END_ADDR	=	32'h2e000007;
 
 
//Wishbone slave base address based on module name. 
 
 	input			aeMB0_sys_ena_i;
 	input			aeMB0_sys_int_i;

 	input			clk_source0_clk_in;
 	input			clk_source0_reset_in;

 	input	 [ gpi0_PORT_WIDTH-1     :   0    ] gpi0_port_i;

 	output	 [ gpo0_PORT_WIDTH-1     :   0    ] gpo0_port_o;

 	output			jtag_intfc0_irq;
 	output			jtag_intfc0_reset_all_o;
 	output			jtag_intfc0_reset_cpus_o;

 	input	 [ ni0_V-1    :   0    ] ni0_credit_in;
 	output	 [ ni0_V-1:   0    ] ni0_credit_out;
 	input	 [ ni0_Xw-1   :   0    ] ni0_current_x;
 	input	 [ ni0_Yw-1   :   0    ] ni0_current_y;
 	input	 [ ni0_Fw-1   :   0    ] ni0_flit_in;
 	input			ni0_flit_in_wr;
 	output	 [ ni0_Fw-1   :   0    ] ni0_flit_out;
 	output			ni0_flit_out_wr;
 	output			ni0_irq;

 	wire			 Altera_ram0_plug_clk_0_clk_i;
 	wire			 Altera_ram0_plug_reset_0_reset_i;
 	wire			 Altera_ram0_plug_wb_slave_0_ack_o;
 	wire	[ Altera_ram0_Aw-1       :   0 ] Altera_ram0_plug_wb_slave_0_adr_i;
 	wire			 Altera_ram0_plug_wb_slave_0_cyc_i;
 	wire	[ Altera_ram0_Dw-1       :   0 ] Altera_ram0_plug_wb_slave_0_dat_i;
 	wire	[ Altera_ram0_Dw-1       :   0 ] Altera_ram0_plug_wb_slave_0_dat_o;
 	wire			 Altera_ram0_plug_wb_slave_0_err_o;
 	wire			 Altera_ram0_plug_wb_slave_0_rty_o;
 	wire	[ Altera_ram0_SELw-1     :   0 ] Altera_ram0_plug_wb_slave_0_sel_i;
 	wire			 Altera_ram0_plug_wb_slave_0_stb_i;
 	wire	[ Altera_ram0_TAGw-1     :   0 ] Altera_ram0_plug_wb_slave_0_tag_i;
 	wire			 Altera_ram0_plug_wb_slave_0_we_i;

 	wire			 aeMB0_plug_clk_0_clk_i;
 	wire			 aeMB0_plug_wb_master_1_ack_i;
 	wire	[ 31:0 ] aeMB0_plug_wb_master_1_adr_o;
 	wire			 aeMB0_plug_wb_master_1_cyc_o;
 	wire	[ 31:0 ] aeMB0_plug_wb_master_1_dat_i;
 	wire	[ 31:0 ] aeMB0_plug_wb_master_1_dat_o;
 	wire			 aeMB0_plug_wb_master_1_err_i;
 	wire			 aeMB0_plug_wb_master_1_rty_i;
 	wire	[ 3:0 ] aeMB0_plug_wb_master_1_sel_o;
 	wire			 aeMB0_plug_wb_master_1_stb_o;
 	wire	[ 2:0 ] aeMB0_plug_wb_master_1_tag_o;
 	wire			 aeMB0_plug_wb_master_1_we_o;
 	wire			 aeMB0_plug_wb_master_0_ack_i;
 	wire	[ 31:0 ] aeMB0_plug_wb_master_0_adr_o;
 	wire			 aeMB0_plug_wb_master_0_cyc_o;
 	wire	[ 31:0 ] aeMB0_plug_wb_master_0_dat_i;
 	wire	[ 31:0 ] aeMB0_plug_wb_master_0_dat_o;
 	wire			 aeMB0_plug_wb_master_0_err_i;
 	wire			 aeMB0_plug_wb_master_0_rty_i;
 	wire	[ 3:0 ] aeMB0_plug_wb_master_0_sel_o;
 	wire			 aeMB0_plug_wb_master_0_stb_o;
 	wire	[ 2:0 ] aeMB0_plug_wb_master_0_tag_o;
 	wire			 aeMB0_plug_wb_master_0_we_o;
 	wire			 aeMB0_plug_reset_0_reset_i;

 	wire			 clk_source0_socket_clk_0_clk_o;
 	wire			 clk_source0_socket_reset_0_reset_o;

 	wire			 gpi0_plug_clk_0_clk_i;
 	wire			 gpi0_plug_reset_0_reset_i;
 	wire			 gpi0_plug_wb_slave_0_ack_o;
 	wire	[ gpi0_Aw-1       :   0 ] gpi0_plug_wb_slave_0_adr_i;
 	wire			 gpi0_plug_wb_slave_0_cyc_i;
 	wire	[ gpi0_Dw-1       :   0 ] gpi0_plug_wb_slave_0_dat_i;
 	wire	[ gpi0_Dw-1       :   0 ] gpi0_plug_wb_slave_0_dat_o;
 	wire			 gpi0_plug_wb_slave_0_err_o;
 	wire			 gpi0_plug_wb_slave_0_rty_o;
 	wire	[ gpi0_SELw-1     :   0 ] gpi0_plug_wb_slave_0_sel_i;
 	wire			 gpi0_plug_wb_slave_0_stb_i;
 	wire	[ gpi0_TAGw-1     :   0 ] gpi0_plug_wb_slave_0_tag_i;
 	wire			 gpi0_plug_wb_slave_0_we_i;

 	wire			 gpo0_plug_clk_0_clk_i;
 	wire			 gpo0_plug_reset_0_reset_i;
 	wire			 gpo0_plug_wb_slave_0_ack_o;
 	wire	[ gpo0_Aw-1       :   0 ] gpo0_plug_wb_slave_0_adr_i;
 	wire			 gpo0_plug_wb_slave_0_cyc_i;
 	wire	[ gpo0_Dw-1       :   0 ] gpo0_plug_wb_slave_0_dat_i;
 	wire	[ gpo0_Dw-1       :   0 ] gpo0_plug_wb_slave_0_dat_o;
 	wire			 gpo0_plug_wb_slave_0_err_o;
 	wire			 gpo0_plug_wb_slave_0_rty_o;
 	wire	[ gpo0_SELw-1     :   0 ] gpo0_plug_wb_slave_0_sel_i;
 	wire			 gpo0_plug_wb_slave_0_stb_i;
 	wire	[ gpo0_TAGw-1     :   0 ] gpo0_plug_wb_slave_0_tag_i;
 	wire			 gpo0_plug_wb_slave_0_we_i;

 	wire			 jtag_intfc0_plug_clk_0_clk_i;
 	wire			 jtag_intfc0_plug_wb_master_0_ack_i;
 	wire	[ jtag_intfc0_M_Aw-1          :   0 ] jtag_intfc0_plug_wb_master_0_adr_o;
 	wire			 jtag_intfc0_plug_wb_master_0_cyc_o;
 	wire	[ jtag_intfc0_Dw-1           :  0 ] jtag_intfc0_plug_wb_master_0_dat_i;
 	wire	[ jtag_intfc0_Dw-1            :   0 ] jtag_intfc0_plug_wb_master_0_dat_o;
 	wire			 jtag_intfc0_plug_wb_master_0_err_i;
 	wire			 jtag_intfc0_plug_wb_master_0_rty_i;
 	wire	[ jtag_intfc0_SELw-1          :   0 ] jtag_intfc0_plug_wb_master_0_sel_o;
 	wire			 jtag_intfc0_plug_wb_master_0_stb_o;
 	wire	[ jtag_intfc0_TAGw-1          :   0 ] jtag_intfc0_plug_wb_master_0_tag_o;
 	wire			 jtag_intfc0_plug_wb_master_0_we_o;
 	wire			 jtag_intfc0_plug_reset_0_reset_i;
 	wire			 jtag_intfc0_plug_wb_slave_0_ack_o;
 	wire	[ jtag_intfc0_S_Aw-1     :   0 ] jtag_intfc0_plug_wb_slave_0_adr_i;
 	wire			 jtag_intfc0_plug_wb_slave_0_cyc_i;
 	wire	[ jtag_intfc0_Dw-1       :   0 ] jtag_intfc0_plug_wb_slave_0_dat_i;
 	wire	[ jtag_intfc0_Dw-1       :   0 ] jtag_intfc0_plug_wb_slave_0_dat_o;
 	wire			 jtag_intfc0_plug_wb_slave_0_err_o;
 	wire			 jtag_intfc0_plug_wb_slave_0_rty_o;
 	wire	[ jtag_intfc0_SELw-1     :   0 ] jtag_intfc0_plug_wb_slave_0_sel_i;
 	wire			 jtag_intfc0_plug_wb_slave_0_stb_i;
 	wire	[ jtag_intfc0_TAGw-1     :   0 ] jtag_intfc0_plug_wb_slave_0_tag_i;
 	wire			 jtag_intfc0_plug_wb_slave_0_we_i;

 	wire			 ni0_plug_clk_0_clk_i;
 	wire			 ni0_plug_wb_master_0_ack_i;
 	wire	[ ni0_M_Aw-1          :   0 ] ni0_plug_wb_master_0_adr_o;
 	wire			 ni0_plug_wb_master_0_cyc_o;
 	wire	[ ni0_Dw-1           :  0 ] ni0_plug_wb_master_0_dat_i;
 	wire	[ ni0_Dw-1            :   0 ] ni0_plug_wb_master_0_dat_o;
 	wire			 ni0_plug_wb_master_0_err_i;
 	wire			 ni0_plug_wb_master_0_rty_i;
 	wire	[ ni0_SELw-1          :   0 ] ni0_plug_wb_master_0_sel_o;
 	wire			 ni0_plug_wb_master_0_stb_o;
 	wire	[ ni0_TAGw-1          :   0 ] ni0_plug_wb_master_0_tag_o;
 	wire			 ni0_plug_wb_master_0_we_o;
 	wire			 ni0_plug_reset_0_reset_i;
 	wire			 ni0_plug_wb_slave_0_ack_o;
 	wire	[ ni0_S_Aw-1     :   0 ] ni0_plug_wb_slave_0_adr_i;
 	wire			 ni0_plug_wb_slave_0_cyc_i;
 	wire	[ ni0_Dw-1       :   0 ] ni0_plug_wb_slave_0_dat_i;
 	wire	[ ni0_Dw-1       :   0 ] ni0_plug_wb_slave_0_dat_o;
 	wire			 ni0_plug_wb_slave_0_err_o;
 	wire			 ni0_plug_wb_slave_0_rty_o;
 	wire	[ ni0_SELw-1     :   0 ] ni0_plug_wb_slave_0_sel_i;
 	wire			 ni0_plug_wb_slave_0_stb_i;
 	wire	[ ni0_TAGw-1     :   0 ] ni0_plug_wb_slave_0_tag_i;
 	wire			 ni0_plug_wb_slave_0_we_i;

 	wire			 bus_plug_clk_0_clk_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_ack_o;
 	wire			 bus_socket_wb_master_3_ack_o;
 	wire			 bus_socket_wb_master_2_ack_o;
 	wire			 bus_socket_wb_master_1_ack_o;
 	wire			 bus_socket_wb_master_0_ack_o;
 	wire	[ (bus_Aw*bus_M)-1      :   0 ] bus_socket_wb_master_array_adr_i;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_master_3_adr_i;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_master_2_adr_i;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_master_1_adr_i;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_master_0_adr_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_cyc_i;
 	wire			 bus_socket_wb_master_3_cyc_i;
 	wire			 bus_socket_wb_master_2_cyc_i;
 	wire			 bus_socket_wb_master_1_cyc_i;
 	wire			 bus_socket_wb_master_0_cyc_i;
 	wire	[ (bus_Dw*bus_M)-1      :   0 ] bus_socket_wb_master_array_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_3_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_2_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_1_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_0_dat_i;
 	wire	[ (bus_Dw*bus_M)-1      :   0 ] bus_socket_wb_master_array_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_3_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_2_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_1_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_0_dat_o;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_err_o;
 	wire			 bus_socket_wb_master_3_err_o;
 	wire			 bus_socket_wb_master_2_err_o;
 	wire			 bus_socket_wb_master_1_err_o;
 	wire			 bus_socket_wb_master_0_err_o;
 	wire	[ bus_Aw-1       :   0 ] bus_socket_wb_addr_map_0_grant_addr;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_rty_o;
 	wire			 bus_socket_wb_master_3_rty_o;
 	wire			 bus_socket_wb_master_2_rty_o;
 	wire			 bus_socket_wb_master_1_rty_o;
 	wire			 bus_socket_wb_master_0_rty_o;
 	wire	[ (bus_SELw*bus_M)-1    :   0 ] bus_socket_wb_master_array_sel_i;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_master_3_sel_i;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_master_2_sel_i;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_master_1_sel_i;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_master_0_sel_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_stb_i;
 	wire			 bus_socket_wb_master_3_stb_i;
 	wire			 bus_socket_wb_master_2_stb_i;
 	wire			 bus_socket_wb_master_1_stb_i;
 	wire			 bus_socket_wb_master_0_stb_i;
 	wire	[ (bus_TAGw*bus_M)-1    :   0 ] bus_socket_wb_master_array_tag_i;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_master_3_tag_i;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_master_2_tag_i;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_master_1_tag_i;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_master_0_tag_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_we_i;
 	wire			 bus_socket_wb_master_3_we_i;
 	wire			 bus_socket_wb_master_2_we_i;
 	wire			 bus_socket_wb_master_1_we_i;
 	wire			 bus_socket_wb_master_0_we_i;
 	wire			 bus_plug_reset_0_reset_i;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_ack_i;
 	wire			 bus_socket_wb_slave_4_ack_i;
 	wire			 bus_socket_wb_slave_3_ack_i;
 	wire			 bus_socket_wb_slave_2_ack_i;
 	wire			 bus_socket_wb_slave_1_ack_i;
 	wire			 bus_socket_wb_slave_0_ack_i;
 	wire	[ (bus_Aw*bus_S)-1      :   0 ] bus_socket_wb_slave_array_adr_o;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_slave_4_adr_o;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_slave_3_adr_o;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_slave_2_adr_o;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_slave_1_adr_o;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_slave_0_adr_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_cyc_o;
 	wire			 bus_socket_wb_slave_4_cyc_o;
 	wire			 bus_socket_wb_slave_3_cyc_o;
 	wire			 bus_socket_wb_slave_2_cyc_o;
 	wire			 bus_socket_wb_slave_1_cyc_o;
 	wire			 bus_socket_wb_slave_0_cyc_o;
 	wire	[ (bus_Dw*bus_S)-1      :   0 ] bus_socket_wb_slave_array_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_4_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_3_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_2_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_1_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_0_dat_i;
 	wire	[ (bus_Dw*bus_S)-1      :   0 ] bus_socket_wb_slave_array_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_4_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_3_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_2_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_1_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_slave_0_dat_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_err_i;
 	wire			 bus_socket_wb_slave_4_err_i;
 	wire			 bus_socket_wb_slave_3_err_i;
 	wire			 bus_socket_wb_slave_2_err_i;
 	wire			 bus_socket_wb_slave_1_err_i;
 	wire			 bus_socket_wb_slave_0_err_i;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_rty_i;
 	wire			 bus_socket_wb_slave_4_rty_i;
 	wire			 bus_socket_wb_slave_3_rty_i;
 	wire			 bus_socket_wb_slave_2_rty_i;
 	wire			 bus_socket_wb_slave_1_rty_i;
 	wire			 bus_socket_wb_slave_0_rty_i;
 	wire	[ (bus_SELw*bus_S)-1    :   0 ] bus_socket_wb_slave_array_sel_o;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_slave_4_sel_o;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_slave_3_sel_o;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_slave_2_sel_o;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_slave_1_sel_o;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_slave_0_sel_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_addr_map_0_sel_one_hot;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_stb_o;
 	wire			 bus_socket_wb_slave_4_stb_o;
 	wire			 bus_socket_wb_slave_3_stb_o;
 	wire			 bus_socket_wb_slave_2_stb_o;
 	wire			 bus_socket_wb_slave_1_stb_o;
 	wire			 bus_socket_wb_slave_0_stb_o;
 	wire	[ (bus_TAGw*bus_S)-1    :   0 ] bus_socket_wb_slave_array_tag_o;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_slave_4_tag_o;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_slave_3_tag_o;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_slave_2_tag_o;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_slave_1_tag_o;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_slave_0_tag_o;
 	wire	[ bus_S-1        :   0 ] bus_socket_wb_slave_array_we_o;
 	wire			 bus_socket_wb_slave_4_we_o;
 	wire			 bus_socket_wb_slave_3_we_o;
 	wire			 bus_socket_wb_slave_2_we_o;
 	wire			 bus_socket_wb_slave_1_we_o;
 	wire			 bus_socket_wb_slave_0_we_o;

 prog_ram_single_port #(
 		.Aw(Altera_ram0_Aw),
		.FPGA_FAMILY(Altera_ram0_FPGA_FAMILY),
		.RAM_TAG_STRING(Altera_ram0_RAM_TAG_STRING),
		.TAGw(Altera_ram0_TAGw),
		.Dw(Altera_ram0_Dw),
		.SELw(Altera_ram0_SELw)
	)  Altera_ram0 	(
		.clk(Altera_ram0_plug_clk_0_clk_i),
		.reset(Altera_ram0_plug_reset_0_reset_i),
		.sa_ack_o(Altera_ram0_plug_wb_slave_0_ack_o),
		.sa_addr_i(Altera_ram0_plug_wb_slave_0_adr_i),
		.sa_cyc_i(Altera_ram0_plug_wb_slave_0_cyc_i),
		.sa_dat_i(Altera_ram0_plug_wb_slave_0_dat_i),
		.sa_dat_o(Altera_ram0_plug_wb_slave_0_dat_o),
		.sa_err_o(Altera_ram0_plug_wb_slave_0_err_o),
		.sa_rty_o(Altera_ram0_plug_wb_slave_0_rty_o),
		.sa_sel_i(Altera_ram0_plug_wb_slave_0_sel_i),
		.sa_stb_i(Altera_ram0_plug_wb_slave_0_stb_i),
		.sa_tag_i(Altera_ram0_plug_wb_slave_0_tag_i),
		.sa_we_i(Altera_ram0_plug_wb_slave_0_we_i)
	);
 aeMB_top #(
 		.AEMB_XWB(aeMB0_AEMB_XWB),
		.AEMB_IDX(aeMB0_AEMB_IDX),
		.AEMB_MUL(aeMB0_AEMB_MUL),
		.AEMB_IWB(aeMB0_AEMB_IWB),
		.AEMB_BSF(aeMB0_AEMB_BSF),
		.AEMB_ICH(aeMB0_AEMB_ICH),
		.AEMB_DWB(aeMB0_AEMB_DWB)
	)  aeMB0 	(
		.clk(aeMB0_plug_clk_0_clk_i),
		.dwb_ack_i(aeMB0_plug_wb_master_1_ack_i),
		.dwb_adr_o(aeMB0_plug_wb_master_1_adr_o),
		.dwb_cyc_o(aeMB0_plug_wb_master_1_cyc_o),
		.dwb_dat_i(aeMB0_plug_wb_master_1_dat_i),
		.dwb_dat_o(aeMB0_plug_wb_master_1_dat_o),
		.dwb_err_i(aeMB0_plug_wb_master_1_err_i),
		.dwb_rty_i(aeMB0_plug_wb_master_1_rty_i),
		.dwb_sel_o(aeMB0_plug_wb_master_1_sel_o),
		.dwb_stb_o(aeMB0_plug_wb_master_1_stb_o),
		.dwb_tag_o(aeMB0_plug_wb_master_1_tag_o),
		.dwb_wre_o(aeMB0_plug_wb_master_1_we_o),
		.iwb_ack_i(aeMB0_plug_wb_master_0_ack_i),
		.iwb_adr_o(aeMB0_plug_wb_master_0_adr_o),
		.iwb_cyc_o(aeMB0_plug_wb_master_0_cyc_o),
		.iwb_dat_i(aeMB0_plug_wb_master_0_dat_i),
		.iwb_dat_o(aeMB0_plug_wb_master_0_dat_o),
		.iwb_err_i(aeMB0_plug_wb_master_0_err_i),
		.iwb_rty_i(aeMB0_plug_wb_master_0_rty_i),
		.iwb_sel_o(aeMB0_plug_wb_master_0_sel_o),
		.iwb_stb_o(aeMB0_plug_wb_master_0_stb_o),
		.iwb_tag_o(aeMB0_plug_wb_master_0_tag_o),
		.iwb_wre_o(aeMB0_plug_wb_master_0_we_o),
		.reset(aeMB0_plug_reset_0_reset_i),
		.sys_ena_i(aeMB0_sys_ena_i),
		.sys_int_i(aeMB0_sys_int_i)
	);
 clk_source  clk_source0 	(
		.clk_in(clk_source0_clk_in),
		.clk_out(clk_source0_socket_clk_0_clk_o),
		.reset_in(clk_source0_reset_in),
		.reset_out(clk_source0_socket_reset_0_reset_o)
	);
 gpi #(
 		.PORT_WIDTH(gpi0_PORT_WIDTH),
		.Dw(gpi0_Dw),
		.Aw(gpi0_Aw),
		.TAGw(gpi0_TAGw),
		.SELw(gpi0_SELw)
	)  gpi0 	(
		.clk(gpi0_plug_clk_0_clk_i),
		.port_i(gpi0_port_i),
		.reset(gpi0_plug_reset_0_reset_i),
		.sa_ack_o(gpi0_plug_wb_slave_0_ack_o),
		.sa_addr_i(gpi0_plug_wb_slave_0_adr_i),
		.sa_cyc_i(gpi0_plug_wb_slave_0_cyc_i),
		.sa_dat_i(gpi0_plug_wb_slave_0_dat_i),
		.sa_dat_o(gpi0_plug_wb_slave_0_dat_o),
		.sa_err_o(gpi0_plug_wb_slave_0_err_o),
		.sa_rty_o(gpi0_plug_wb_slave_0_rty_o),
		.sa_sel_i(gpi0_plug_wb_slave_0_sel_i),
		.sa_stb_i(gpi0_plug_wb_slave_0_stb_i),
		.sa_tag_i(gpi0_plug_wb_slave_0_tag_i),
		.sa_we_i(gpi0_plug_wb_slave_0_we_i)
	);
 gpo #(
 		.PORT_WIDTH(gpo0_PORT_WIDTH),
		.Dw(gpo0_Dw),
		.Aw(gpo0_Aw),
		.TAGw(gpo0_TAGw),
		.SELw(gpo0_SELw)
	)  gpo0 	(
		.clk(gpo0_plug_clk_0_clk_i),
		.port_o(gpo0_port_o),
		.reset(gpo0_plug_reset_0_reset_i),
		.sa_ack_o(gpo0_plug_wb_slave_0_ack_o),
		.sa_addr_i(gpo0_plug_wb_slave_0_adr_i),
		.sa_cyc_i(gpo0_plug_wb_slave_0_cyc_i),
		.sa_dat_i(gpo0_plug_wb_slave_0_dat_i),
		.sa_dat_o(gpo0_plug_wb_slave_0_dat_o),
		.sa_err_o(gpo0_plug_wb_slave_0_err_o),
		.sa_rty_o(gpo0_plug_wb_slave_0_rty_o),
		.sa_sel_i(gpo0_plug_wb_slave_0_sel_i),
		.sa_stb_i(gpo0_plug_wb_slave_0_stb_i),
		.sa_tag_i(gpo0_plug_wb_slave_0_tag_i),
		.sa_we_i(gpo0_plug_wb_slave_0_we_i)
	);
 jtag_intfc #(
 		.NI_BASE_ADDR(jtag_intfc0_NI_BASE_ADDR),
		.JTAG_BASE_ADDR(jtag_intfc0_JTAG_BASE_ADDR),
		.WR_RAM_TAG(jtag_intfc0_WR_RAM_TAG),
		.RD_RAM_TAG(jtag_intfc0_RD_RAM_TAG),
		.WR_RAMw(jtag_intfc0_WR_RAMw),
		.Dw(jtag_intfc0_Dw),
		.S_Aw(jtag_intfc0_S_Aw),
		.M_Aw(jtag_intfc0_M_Aw),
		.TAGw(jtag_intfc0_TAGw),
		.SELw(jtag_intfc0_SELw)
	)  jtag_intfc0 	(
		.clk(jtag_intfc0_plug_clk_0_clk_i),
		.irq(jtag_intfc0_irq),
		.m_ack_i(jtag_intfc0_plug_wb_master_0_ack_i),
		.m_addr_o(jtag_intfc0_plug_wb_master_0_adr_o),
		.m_cyc_o(jtag_intfc0_plug_wb_master_0_cyc_o),
		.m_dat_i(jtag_intfc0_plug_wb_master_0_dat_i),
		.m_dat_o(jtag_intfc0_plug_wb_master_0_dat_o),
		.m_err_i(jtag_intfc0_plug_wb_master_0_err_i),
		.m_rty_i(jtag_intfc0_plug_wb_master_0_rty_i),
		.m_sel_o(jtag_intfc0_plug_wb_master_0_sel_o),
		.m_stb_o(jtag_intfc0_plug_wb_master_0_stb_o),
		.m_tag_o(jtag_intfc0_plug_wb_master_0_tag_o),
		.m_we_o(jtag_intfc0_plug_wb_master_0_we_o),
		.reset(jtag_intfc0_plug_reset_0_reset_i),
		.reset_all_o(jtag_intfc0_reset_all_o),
		.reset_cpus_o(jtag_intfc0_reset_cpus_o),
		.s_ack_o(jtag_intfc0_plug_wb_slave_0_ack_o),
		.s_addr_i(jtag_intfc0_plug_wb_slave_0_adr_i),
		.s_cyc_i(jtag_intfc0_plug_wb_slave_0_cyc_i),
		.s_dat_i(jtag_intfc0_plug_wb_slave_0_dat_i),
		.s_dat_o(jtag_intfc0_plug_wb_slave_0_dat_o),
		.s_err_o(jtag_intfc0_plug_wb_slave_0_err_o),
		.s_rty_o(jtag_intfc0_plug_wb_slave_0_rty_o),
		.s_sel_i(jtag_intfc0_plug_wb_slave_0_sel_i),
		.s_stb_i(jtag_intfc0_plug_wb_slave_0_stb_i),
		.s_tag_i(jtag_intfc0_plug_wb_slave_0_tag_i),
		.s_we_i(jtag_intfc0_plug_wb_slave_0_we_i)
	);
 ni #(
 		.NY(ni0_NY),
		.NX(ni0_NX),
		.V(ni0_V),
		.B(ni0_B),
		.Dw(ni0_Dw),
		.DEBUG_EN(ni0_DEBUG_EN),
		.TAGw(ni0_TAGw),
		.M_Aw(ni0_M_Aw),
		.ROUTE_NAME(ni0_ROUTE_NAME),
		.Fpay(ni0_Fpay),
		.SELw(ni0_SELw),
		.ROUTE_TYPE(ni0_ROUTE_TYPE),
		.P(ni0_P),
		.S_Aw(ni0_S_Aw),
		.TOPOLOGY(ni0_TOPOLOGY)
	)  ni0 	(
		.clk(ni0_plug_clk_0_clk_i),
		.credit_in(ni0_credit_in),
		.credit_out(ni0_credit_out),
		.current_x(ni0_current_x),
		.current_y(ni0_current_y),
		.flit_in(ni0_flit_in),
		.flit_in_wr(ni0_flit_in_wr),
		.flit_out(ni0_flit_out),
		.flit_out_wr(ni0_flit_out_wr),
		.irq(ni0_irq),
		.m_ack_i(ni0_plug_wb_master_0_ack_i),
		.m_addr_o(ni0_plug_wb_master_0_adr_o),
		.m_cyc_o(ni0_plug_wb_master_0_cyc_o),
		.m_dat_i(ni0_plug_wb_master_0_dat_i),
		.m_dat_o(ni0_plug_wb_master_0_dat_o),
		.m_err_i(ni0_plug_wb_master_0_err_i),
		.m_rty_i(ni0_plug_wb_master_0_rty_i),
		.m_sel_o(ni0_plug_wb_master_0_sel_o),
		.m_stb_o(ni0_plug_wb_master_0_stb_o),
		.m_tag_o(ni0_plug_wb_master_0_tag_o),
		.m_we_o(ni0_plug_wb_master_0_we_o),
		.reset(ni0_plug_reset_0_reset_i),
		.s_ack_o(ni0_plug_wb_slave_0_ack_o),
		.s_addr_i(ni0_plug_wb_slave_0_adr_i),
		.s_cyc_i(ni0_plug_wb_slave_0_cyc_i),
		.s_dat_i(ni0_plug_wb_slave_0_dat_i),
		.s_dat_o(ni0_plug_wb_slave_0_dat_o),
		.s_err_o(ni0_plug_wb_slave_0_err_o),
		.s_rty_o(ni0_plug_wb_slave_0_rty_o),
		.s_sel_i(ni0_plug_wb_slave_0_sel_i),
		.s_stb_i(ni0_plug_wb_slave_0_stb_i),
		.s_tag_i(ni0_plug_wb_slave_0_tag_i),
		.s_we_i(ni0_plug_wb_slave_0_we_i)
	);
 wishbone_bus #(
 		.S(bus_S),
		.M(bus_M),
		.Aw(bus_Aw),
		.TAGw(bus_TAGw),
		.SELw(bus_SELw),
		.Dw(bus_Dw)
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
 
 	assign  Altera_ram0_plug_clk_0_clk_i = clk_source0_socket_clk_0_clk_o;
 	assign  Altera_ram0_plug_reset_0_reset_i = clk_source0_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_2_ack_i  = Altera_ram0_plug_wb_slave_0_ack_o;
 	assign  Altera_ram0_plug_wb_slave_0_adr_i = bus_socket_wb_slave_2_adr_o;
 	assign  Altera_ram0_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_2_cyc_o;
 	assign  Altera_ram0_plug_wb_slave_0_dat_i = bus_socket_wb_slave_2_dat_o;
 	assign  bus_socket_wb_slave_2_dat_i  = Altera_ram0_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_2_err_i  = Altera_ram0_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_2_rty_i  = Altera_ram0_plug_wb_slave_0_rty_o;
 	assign  Altera_ram0_plug_wb_slave_0_sel_i = bus_socket_wb_slave_2_sel_o;
 	assign  Altera_ram0_plug_wb_slave_0_stb_i = bus_socket_wb_slave_2_stb_o;
 	assign  Altera_ram0_plug_wb_slave_0_tag_i = bus_socket_wb_slave_2_tag_o;
 	assign  Altera_ram0_plug_wb_slave_0_we_i = bus_socket_wb_slave_2_we_o;

 
 	assign  aeMB0_plug_clk_0_clk_i = clk_source0_socket_clk_0_clk_o;
 	assign  aeMB0_plug_wb_master_1_ack_i = bus_socket_wb_master_1_ack_o;
 	assign  bus_socket_wb_master_1_adr_i  = aeMB0_plug_wb_master_1_adr_o;
 	assign  bus_socket_wb_master_1_cyc_i  = aeMB0_plug_wb_master_1_cyc_o;
 	assign  aeMB0_plug_wb_master_1_dat_i = bus_socket_wb_master_1_dat_o;
 	assign  bus_socket_wb_master_1_dat_i  = aeMB0_plug_wb_master_1_dat_o;
 	assign  aeMB0_plug_wb_master_1_err_i = bus_socket_wb_master_1_err_o;
 	assign  aeMB0_plug_wb_master_1_rty_i = bus_socket_wb_master_1_rty_o;
 	assign  bus_socket_wb_master_1_sel_i  = aeMB0_plug_wb_master_1_sel_o;
 	assign  bus_socket_wb_master_1_stb_i  = aeMB0_plug_wb_master_1_stb_o;
 	assign  bus_socket_wb_master_1_tag_i  = aeMB0_plug_wb_master_1_tag_o;
 	assign  bus_socket_wb_master_1_we_i  = aeMB0_plug_wb_master_1_we_o;
 	assign  aeMB0_plug_wb_master_0_ack_i = bus_socket_wb_master_0_ack_o;
 	assign  bus_socket_wb_master_0_adr_i  = aeMB0_plug_wb_master_0_adr_o;
 	assign  bus_socket_wb_master_0_cyc_i  = aeMB0_plug_wb_master_0_cyc_o;
 	assign  aeMB0_plug_wb_master_0_dat_i = bus_socket_wb_master_0_dat_o;
 	assign  bus_socket_wb_master_0_dat_i  = aeMB0_plug_wb_master_0_dat_o;
 	assign  aeMB0_plug_wb_master_0_err_i = bus_socket_wb_master_0_err_o;
 	assign  aeMB0_plug_wb_master_0_rty_i = bus_socket_wb_master_0_rty_o;
 	assign  bus_socket_wb_master_0_sel_i  = aeMB0_plug_wb_master_0_sel_o;
 	assign  bus_socket_wb_master_0_stb_i  = aeMB0_plug_wb_master_0_stb_o;
 	assign  bus_socket_wb_master_0_tag_i  = aeMB0_plug_wb_master_0_tag_o;
 	assign  bus_socket_wb_master_0_we_i  = aeMB0_plug_wb_master_0_we_o;
 	assign  aeMB0_plug_reset_0_reset_i = clk_source0_socket_reset_0_reset_o;

 

 
 	assign  gpi0_plug_clk_0_clk_i = clk_source0_socket_clk_0_clk_o;
 	assign  gpi0_plug_reset_0_reset_i = clk_source0_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_1_ack_i  = gpi0_plug_wb_slave_0_ack_o;
 	assign  gpi0_plug_wb_slave_0_adr_i = bus_socket_wb_slave_1_adr_o;
 	assign  gpi0_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_1_cyc_o;
 	assign  gpi0_plug_wb_slave_0_dat_i = bus_socket_wb_slave_1_dat_o;
 	assign  bus_socket_wb_slave_1_dat_i  = gpi0_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_1_err_i  = gpi0_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_1_rty_i  = gpi0_plug_wb_slave_0_rty_o;
 	assign  gpi0_plug_wb_slave_0_sel_i = bus_socket_wb_slave_1_sel_o;
 	assign  gpi0_plug_wb_slave_0_stb_i = bus_socket_wb_slave_1_stb_o;
 	assign  gpi0_plug_wb_slave_0_tag_i = bus_socket_wb_slave_1_tag_o;
 	assign  gpi0_plug_wb_slave_0_we_i = bus_socket_wb_slave_1_we_o;

 
 	assign  gpo0_plug_clk_0_clk_i = clk_source0_socket_clk_0_clk_o;
 	assign  gpo0_plug_reset_0_reset_i = clk_source0_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_3_ack_i  = gpo0_plug_wb_slave_0_ack_o;
 	assign  gpo0_plug_wb_slave_0_adr_i = bus_socket_wb_slave_3_adr_o;
 	assign  gpo0_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_3_cyc_o;
 	assign  gpo0_plug_wb_slave_0_dat_i = bus_socket_wb_slave_3_dat_o;
 	assign  bus_socket_wb_slave_3_dat_i  = gpo0_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_3_err_i  = gpo0_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_3_rty_i  = gpo0_plug_wb_slave_0_rty_o;
 	assign  gpo0_plug_wb_slave_0_sel_i = bus_socket_wb_slave_3_sel_o;
 	assign  gpo0_plug_wb_slave_0_stb_i = bus_socket_wb_slave_3_stb_o;
 	assign  gpo0_plug_wb_slave_0_tag_i = bus_socket_wb_slave_3_tag_o;
 	assign  gpo0_plug_wb_slave_0_we_i = bus_socket_wb_slave_3_we_o;

 
 	assign  jtag_intfc0_plug_clk_0_clk_i = clk_source0_socket_clk_0_clk_o;
 	assign  jtag_intfc0_plug_wb_master_0_ack_i = bus_socket_wb_master_2_ack_o;
 	assign  bus_socket_wb_master_2_adr_i  = jtag_intfc0_plug_wb_master_0_adr_o;
 	assign  bus_socket_wb_master_2_cyc_i  = jtag_intfc0_plug_wb_master_0_cyc_o;
 	assign  jtag_intfc0_plug_wb_master_0_dat_i = bus_socket_wb_master_2_dat_o;
 	assign  bus_socket_wb_master_2_dat_i  = jtag_intfc0_plug_wb_master_0_dat_o;
 	assign  jtag_intfc0_plug_wb_master_0_err_i = bus_socket_wb_master_2_err_o;
 	assign  jtag_intfc0_plug_wb_master_0_rty_i = bus_socket_wb_master_2_rty_o;
 	assign  bus_socket_wb_master_2_sel_i  = jtag_intfc0_plug_wb_master_0_sel_o;
 	assign  bus_socket_wb_master_2_stb_i  = jtag_intfc0_plug_wb_master_0_stb_o;
 	assign  bus_socket_wb_master_2_tag_i  = jtag_intfc0_plug_wb_master_0_tag_o;
 	assign  bus_socket_wb_master_2_we_i  = jtag_intfc0_plug_wb_master_0_we_o;
 	assign  jtag_intfc0_plug_reset_0_reset_i = clk_source0_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_0_ack_i  = jtag_intfc0_plug_wb_slave_0_ack_o;
 	assign  jtag_intfc0_plug_wb_slave_0_adr_i = bus_socket_wb_slave_0_adr_o;
 	assign  jtag_intfc0_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_0_cyc_o;
 	assign  jtag_intfc0_plug_wb_slave_0_dat_i = bus_socket_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_0_dat_i  = jtag_intfc0_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_0_err_i  = jtag_intfc0_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_0_rty_i  = jtag_intfc0_plug_wb_slave_0_rty_o;
 	assign  jtag_intfc0_plug_wb_slave_0_sel_i = bus_socket_wb_slave_0_sel_o;
 	assign  jtag_intfc0_plug_wb_slave_0_stb_i = bus_socket_wb_slave_0_stb_o;
 	assign  jtag_intfc0_plug_wb_slave_0_tag_i = bus_socket_wb_slave_0_tag_o;
 	assign  jtag_intfc0_plug_wb_slave_0_we_i = bus_socket_wb_slave_0_we_o;

 
 	assign  ni0_plug_clk_0_clk_i = clk_source0_socket_clk_0_clk_o;
 	assign  ni0_plug_wb_master_0_ack_i = bus_socket_wb_master_3_ack_o;
 	assign  bus_socket_wb_master_3_adr_i  = ni0_plug_wb_master_0_adr_o;
 	assign  bus_socket_wb_master_3_cyc_i  = ni0_plug_wb_master_0_cyc_o;
 	assign  ni0_plug_wb_master_0_dat_i = bus_socket_wb_master_3_dat_o;
 	assign  bus_socket_wb_master_3_dat_i  = ni0_plug_wb_master_0_dat_o;
 	assign  ni0_plug_wb_master_0_err_i = bus_socket_wb_master_3_err_o;
 	assign  ni0_plug_wb_master_0_rty_i = bus_socket_wb_master_3_rty_o;
 	assign  bus_socket_wb_master_3_sel_i  = ni0_plug_wb_master_0_sel_o;
 	assign  bus_socket_wb_master_3_stb_i  = ni0_plug_wb_master_0_stb_o;
 	assign  bus_socket_wb_master_3_tag_i  = ni0_plug_wb_master_0_tag_o;
 	assign  bus_socket_wb_master_3_we_i  = ni0_plug_wb_master_0_we_o;
 	assign  ni0_plug_reset_0_reset_i = clk_source0_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_4_ack_i  = ni0_plug_wb_slave_0_ack_o;
 	assign  ni0_plug_wb_slave_0_adr_i = bus_socket_wb_slave_4_adr_o;
 	assign  ni0_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_4_cyc_o;
 	assign  ni0_plug_wb_slave_0_dat_i = bus_socket_wb_slave_4_dat_o;
 	assign  bus_socket_wb_slave_4_dat_i  = ni0_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_4_err_i  = ni0_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_4_rty_i  = ni0_plug_wb_slave_0_rty_o;
 	assign  ni0_plug_wb_slave_0_sel_i = bus_socket_wb_slave_4_sel_o;
 	assign  ni0_plug_wb_slave_0_stb_i = bus_socket_wb_slave_4_stb_o;
 	assign  ni0_plug_wb_slave_0_tag_i = bus_socket_wb_slave_4_tag_o;
 	assign  ni0_plug_wb_slave_0_we_i = bus_socket_wb_slave_4_we_o;

 
 	assign  bus_plug_clk_0_clk_i = clk_source0_socket_clk_0_clk_o;
 	assign  bus_plug_reset_0_reset_i = clk_source0_socket_reset_0_reset_o;

 	assign {bus_socket_wb_master_3_ack_o ,bus_socket_wb_master_2_ack_o ,bus_socket_wb_master_1_ack_o ,bus_socket_wb_master_0_ack_o} =bus_socket_wb_master_array_ack_o;
 	assign bus_socket_wb_master_array_adr_i ={bus_socket_wb_master_3_adr_i ,bus_socket_wb_master_2_adr_i ,bus_socket_wb_master_1_adr_i ,bus_socket_wb_master_0_adr_i};
 	assign bus_socket_wb_master_array_cyc_i ={bus_socket_wb_master_3_cyc_i ,bus_socket_wb_master_2_cyc_i ,bus_socket_wb_master_1_cyc_i ,bus_socket_wb_master_0_cyc_i};
 	assign bus_socket_wb_master_array_dat_i ={bus_socket_wb_master_3_dat_i ,bus_socket_wb_master_2_dat_i ,bus_socket_wb_master_1_dat_i ,bus_socket_wb_master_0_dat_i};
 	assign {bus_socket_wb_master_3_dat_o ,bus_socket_wb_master_2_dat_o ,bus_socket_wb_master_1_dat_o ,bus_socket_wb_master_0_dat_o} =bus_socket_wb_master_array_dat_o;
 	assign {bus_socket_wb_master_3_err_o ,bus_socket_wb_master_2_err_o ,bus_socket_wb_master_1_err_o ,bus_socket_wb_master_0_err_o} =bus_socket_wb_master_array_err_o;
 	assign {bus_socket_wb_master_3_rty_o ,bus_socket_wb_master_2_rty_o ,bus_socket_wb_master_1_rty_o ,bus_socket_wb_master_0_rty_o} =bus_socket_wb_master_array_rty_o;
 	assign bus_socket_wb_master_array_sel_i ={bus_socket_wb_master_3_sel_i ,bus_socket_wb_master_2_sel_i ,bus_socket_wb_master_1_sel_i ,bus_socket_wb_master_0_sel_i};
 	assign bus_socket_wb_master_array_stb_i ={bus_socket_wb_master_3_stb_i ,bus_socket_wb_master_2_stb_i ,bus_socket_wb_master_1_stb_i ,bus_socket_wb_master_0_stb_i};
 	assign bus_socket_wb_master_array_tag_i ={bus_socket_wb_master_3_tag_i ,bus_socket_wb_master_2_tag_i ,bus_socket_wb_master_1_tag_i ,bus_socket_wb_master_0_tag_i};
 	assign bus_socket_wb_master_array_we_i ={bus_socket_wb_master_3_we_i ,bus_socket_wb_master_2_we_i ,bus_socket_wb_master_1_we_i ,bus_socket_wb_master_0_we_i};
 	assign bus_socket_wb_slave_array_ack_i ={bus_socket_wb_slave_4_ack_i ,bus_socket_wb_slave_3_ack_i ,bus_socket_wb_slave_2_ack_i ,bus_socket_wb_slave_1_ack_i ,bus_socket_wb_slave_0_ack_i};
 	assign {bus_socket_wb_slave_4_adr_o ,bus_socket_wb_slave_3_adr_o ,bus_socket_wb_slave_2_adr_o ,bus_socket_wb_slave_1_adr_o ,bus_socket_wb_slave_0_adr_o} =bus_socket_wb_slave_array_adr_o;
 	assign {bus_socket_wb_slave_4_cyc_o ,bus_socket_wb_slave_3_cyc_o ,bus_socket_wb_slave_2_cyc_o ,bus_socket_wb_slave_1_cyc_o ,bus_socket_wb_slave_0_cyc_o} =bus_socket_wb_slave_array_cyc_o;
 	assign bus_socket_wb_slave_array_dat_i ={bus_socket_wb_slave_4_dat_i ,bus_socket_wb_slave_3_dat_i ,bus_socket_wb_slave_2_dat_i ,bus_socket_wb_slave_1_dat_i ,bus_socket_wb_slave_0_dat_i};
 	assign {bus_socket_wb_slave_4_dat_o ,bus_socket_wb_slave_3_dat_o ,bus_socket_wb_slave_2_dat_o ,bus_socket_wb_slave_1_dat_o ,bus_socket_wb_slave_0_dat_o} =bus_socket_wb_slave_array_dat_o;
 	assign bus_socket_wb_slave_array_err_i ={bus_socket_wb_slave_4_err_i ,bus_socket_wb_slave_3_err_i ,bus_socket_wb_slave_2_err_i ,bus_socket_wb_slave_1_err_i ,bus_socket_wb_slave_0_err_i};
 	assign bus_socket_wb_slave_array_rty_i ={bus_socket_wb_slave_4_rty_i ,bus_socket_wb_slave_3_rty_i ,bus_socket_wb_slave_2_rty_i ,bus_socket_wb_slave_1_rty_i ,bus_socket_wb_slave_0_rty_i};
 	assign {bus_socket_wb_slave_4_sel_o ,bus_socket_wb_slave_3_sel_o ,bus_socket_wb_slave_2_sel_o ,bus_socket_wb_slave_1_sel_o ,bus_socket_wb_slave_0_sel_o} =bus_socket_wb_slave_array_sel_o;
 	assign {bus_socket_wb_slave_4_stb_o ,bus_socket_wb_slave_3_stb_o ,bus_socket_wb_slave_2_stb_o ,bus_socket_wb_slave_1_stb_o ,bus_socket_wb_slave_0_stb_o} =bus_socket_wb_slave_array_stb_o;
 	assign {bus_socket_wb_slave_4_tag_o ,bus_socket_wb_slave_3_tag_o ,bus_socket_wb_slave_2_tag_o ,bus_socket_wb_slave_1_tag_o ,bus_socket_wb_slave_0_tag_o} =bus_socket_wb_slave_array_tag_o;
 	assign {bus_socket_wb_slave_4_we_o ,bus_socket_wb_slave_3_we_o ,bus_socket_wb_slave_2_we_o ,bus_socket_wb_slave_1_we_o ,bus_socket_wb_slave_0_we_o} =bus_socket_wb_slave_array_we_o;

 
//Wishbone slave address match
 /* Altera_ram0 wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[2]= ((bus_socket_wb_addr_map_0_grant_addr >= Altera_ram0_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< Altera_ram0_END_ADDR));
 /* gpi0 wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[1]= ((bus_socket_wb_addr_map_0_grant_addr >= gpi0_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< gpi0_END_ADDR));
 /* gpo0 wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[3]= ((bus_socket_wb_addr_map_0_grant_addr >= gpo0_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< gpo0_END_ADDR));
 /* jtag_intfc0 wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[0]= ((bus_socket_wb_addr_map_0_grant_addr >= jtag_intfc0_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< jtag_intfc0_END_ADDR));
 /* ni0 wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[4]= ((bus_socket_wb_addr_map_0_grant_addr >= ni0_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< ni0_END_ADDR));
 endmodule

