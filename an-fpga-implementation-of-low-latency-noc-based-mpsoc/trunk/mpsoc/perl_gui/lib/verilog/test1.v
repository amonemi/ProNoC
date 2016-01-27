module test1 #(
 	parameter	CORE_ID=0 ,
	parameter	Altera_single_port_ram0_Dw=32 ,
	parameter	Altera_single_port_ram0_Aw=10 ,
	parameter	aeMB0_AEMB_MUL= 1 ,
	parameter	aeMB0_AEMB_BSF= 1 ,
	parameter	gpi_PORT_WIDTH=   1 ,
	parameter	ni_NY= 2 ,
	parameter	ni_NX= 2 ,
	parameter	ni_V= 4 ,
	parameter	ni_B= 4 ,
	parameter	ni_DEBUG_EN=   1 ,
	parameter	ni_ROUTE_NAME="XY"      ,
	parameter	ni_TOPOLOGY=    "MESH"
)(
	aeMB0_sys_ena_i, 
	clk_source0_clk_in, 
	clk_source0_reset_in, 
	gpi_port_i, 
	ni_credit_in, 
	ni_credit_out, 
	ni_current_x, 
	ni_current_y, 
	ni_flit_in, 
	ni_flit_in_wr, 
	ni_flit_out, 
	ni_flit_out_wr
);
  
  	function integer log2;
  		input integer number; begin	
          	log2=0;	
          	while(2**log2<number) begin	
        		  	log2=log2+1;	
         		end	
        		end	
     	endfunction // log2 
     	
     	function   [15:0]i2s;   
          input   integer c;  integer i;  integer tmp; begin 
              tmp =0; 
              for (i=0; i<2; i=i+1'b1) begin 
              tmp =  tmp +    (((c % 10)   + 6'd48) << i*8); 
                  c       =   c/10; 
              end 
              i2s = tmp[15:0];
          end     
     endfunction //i2s
  	localparam	Altera_single_port_ram0_TAGw=3;
	localparam	Altera_single_port_ram0_SELw=4;
	localparam	Altera_single_port_ram0_RAM_TAG_STRING= i2s(CORE_ID);
	localparam	Altera_single_port_ram0_WB_Aw=Altera_single_port_ram0_Aw+2;

 	localparam	aeMB0_AEMB_XWB= 7;
	localparam	aeMB0_AEMB_IDX= 6;
	localparam	aeMB0_AEMB_IWB= 32;
	localparam	aeMB0_AEMB_ICH= 11;
	localparam	aeMB0_AEMB_DWB= 32;

 
 	localparam	gpi_Dw=   32;
	localparam	gpi_Aw=   2;
	localparam	gpi_TAGw=   3;
	localparam	gpi_SELw=   4;

 	localparam	ni_Dw=32;
	localparam	ni_TAGw=   3;
	localparam	ni_M_Aw=32;
	localparam	ni_Fpay= 32;
	localparam	ni_SELw=   4    ;
	localparam	ni_ROUTE_TYPE=   (ni_ROUTE_NAME == "XY" || ni_ROUTE_NAME == "TRANC_XY" )?    "DETERMINISTIC" : 
			            (ni_ROUTE_NAME == "DUATO" || ni_ROUTE_NAME == "TRANC_DUATO" )?   "FULL_ADAPTIVE": "PAR_ADAPTIVE" ;
	localparam	ni_P= 5;
	localparam	ni_S_Aw=   3;
	localparam	ni_Fw=2 + ni_V + ni_Fpay;
	localparam	ni_Xw=log2( ni_NX );
	localparam	ni_Yw=log2( ni_NY );

 	localparam	bus_S=3;
	localparam	bus_M=3;
	localparam	bus_Aw=	32;
	localparam	bus_TAGw=	3    ;
	localparam	bus_SELw=	4;
	localparam	bus_Dw=	32;

 
//Wishbone slave base address based on instance name
 	localparam 	Altera_single_port_ram0_BASE_ADDR	=	32'h00000000;
 	localparam 	Altera_single_port_ram0_END_ADDR	=	32'h000003ff;
 	localparam 	gpi_BASE_ADDR	=	32'h24400000;
 	localparam 	gpi_END_ADDR	=	32'h24400007;
 	localparam 	ni_BASE_ADDR	=	32'h2e000000;
 	localparam 	ni_END_ADDR	=	32'h2e000007;
 
 
//Wishbone slave base address based on module name. 
 	localparam 	gpi0_BASE_ADDR	=	32'h24400000;
 	localparam 	gpi0_END_ADDR	=	32'h24400007;
 	localparam 	ni0_BASE_ADDR	=	32'h2e000000;
 	localparam 	ni0_END_ADDR	=	32'h2e000007;
 
 	input			aeMB0_sys_ena_i;

 	input			clk_source0_clk_in;
 	input			clk_source0_reset_in;

 	input	 [ gpi_PORT_WIDTH-1     :   0    ] gpi_port_i;

 	input	 [ ni_V-1    :   0    ] ni_credit_in;
 	output	 [ ni_V-1:   0    ] ni_credit_out;
 	input	 [ ni_Xw-1   :   0    ] ni_current_x;
 	input	 [ ni_Yw-1   :   0    ] ni_current_y;
 	input	 [ ni_Fw-1   :   0    ] ni_flit_in;
 	input			ni_flit_in_wr;
 	output	 [ ni_Fw-1   :   0    ] ni_flit_out;
 	output			ni_flit_out_wr;

 	wire			 Altera_single_port_ram0_plug_clk_0_clk_i;
 	wire			 Altera_single_port_ram0_plug_reset_0_reset_i;
 	wire			 Altera_single_port_ram0_plug_wb_slave_0_ack_o;
 	wire	[ Altera_single_port_ram0_Aw-1       :   0 ] Altera_single_port_ram0_plug_wb_slave_0_adr_i;
 	wire			 Altera_single_port_ram0_plug_wb_slave_0_cyc_i;
 	wire	[ Altera_single_port_ram0_Dw-1       :   0 ] Altera_single_port_ram0_plug_wb_slave_0_dat_i;
 	wire	[ Altera_single_port_ram0_Dw-1       :   0 ] Altera_single_port_ram0_plug_wb_slave_0_dat_o;
 	wire			 Altera_single_port_ram0_plug_wb_slave_0_err_o;
 	wire			 Altera_single_port_ram0_plug_wb_slave_0_rty_o;
 	wire	[ Altera_single_port_ram0_SELw-1     :   0 ] Altera_single_port_ram0_plug_wb_slave_0_sel_i;
 	wire			 Altera_single_port_ram0_plug_wb_slave_0_stb_i;
 	wire	[ Altera_single_port_ram0_TAGw-1     :   0 ] Altera_single_port_ram0_plug_wb_slave_0_tag_i;
 	wire			 Altera_single_port_ram0_plug_wb_slave_0_we_i;

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

 	wire			 gpi_plug_clk_0_clk_i;
 	wire			 gpi_plug_reset_0_reset_i;
 	wire			 gpi_plug_wb_slave_0_ack_o;
 	wire	[ gpi_Aw-1       :   0 ] gpi_plug_wb_slave_0_adr_i;
 	wire			 gpi_plug_wb_slave_0_cyc_i;
 	wire	[ gpi_Dw-1       :   0 ] gpi_plug_wb_slave_0_dat_i;
 	wire	[ gpi_Dw-1       :   0 ] gpi_plug_wb_slave_0_dat_o;
 	wire			 gpi_plug_wb_slave_0_err_o;
 	wire			 gpi_plug_wb_slave_0_rty_o;
 	wire	[ gpi_SELw-1     :   0 ] gpi_plug_wb_slave_0_sel_i;
 	wire			 gpi_plug_wb_slave_0_stb_i;
 	wire	[ gpi_TAGw-1     :   0 ] gpi_plug_wb_slave_0_tag_i;
 	wire			 gpi_plug_wb_slave_0_we_i;

 	wire			 ni_plug_clk_0_clk_i;
 	wire			 ni_plug_wb_master_0_ack_i;
 	wire	[ ni_M_Aw-1          :   0 ] ni_plug_wb_master_0_adr_o;
 	wire			 ni_plug_wb_master_0_cyc_o;
 	wire	[ ni_Dw-1           :  0 ] ni_plug_wb_master_0_dat_i;
 	wire	[ ni_Dw-1            :   0 ] ni_plug_wb_master_0_dat_o;
 	wire			 ni_plug_wb_master_0_err_i;
 	wire			 ni_plug_wb_master_0_rty_i;
 	wire	[ ni_SELw-1          :   0 ] ni_plug_wb_master_0_sel_o;
 	wire			 ni_plug_wb_master_0_stb_o;
 	wire	[ ni_TAGw-1          :   0 ] ni_plug_wb_master_0_tag_o;
 	wire			 ni_plug_wb_master_0_we_o;
 	wire			 ni_plug_reset_0_reset_i;
 	wire			 ni_plug_wb_slave_0_ack_o;
 	wire	[ ni_S_Aw-1     :   0 ] ni_plug_wb_slave_0_adr_i;
 	wire			 ni_plug_wb_slave_0_cyc_i;
 	wire	[ ni_Dw-1       :   0 ] ni_plug_wb_slave_0_dat_i;
 	wire	[ ni_Dw-1       :   0 ] ni_plug_wb_slave_0_dat_o;
 	wire			 ni_plug_wb_slave_0_err_o;
 	wire			 ni_plug_wb_slave_0_rty_o;
 	wire	[ ni_SELw-1     :   0 ] ni_plug_wb_slave_0_sel_i;
 	wire			 ni_plug_wb_slave_0_stb_i;
 	wire	[ ni_TAGw-1     :   0 ] ni_plug_wb_slave_0_tag_i;
 	wire			 ni_plug_wb_slave_0_we_i;

 	wire			 bus_plug_clk_0_clk_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_ack_o;
 	wire			 bus_socket_wb_master_2_ack_o;
 	wire			 bus_socket_wb_master_1_ack_o;
 	wire			 bus_socket_wb_master_0_ack_o;
 	wire	[ (bus_Aw*bus_M)-1      :   0 ] bus_socket_wb_master_array_adr_i;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_master_2_adr_i;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_master_1_adr_i;
 	wire	[ bus_Aw-1      :   0 ] bus_socket_wb_master_0_adr_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_cyc_i;
 	wire			 bus_socket_wb_master_2_cyc_i;
 	wire			 bus_socket_wb_master_1_cyc_i;
 	wire			 bus_socket_wb_master_0_cyc_i;
 	wire	[ (bus_Dw*bus_M)-1      :   0 ] bus_socket_wb_master_array_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_2_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_1_dat_i;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_0_dat_i;
 	wire	[ (bus_Dw*bus_M)-1      :   0 ] bus_socket_wb_master_array_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_2_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_1_dat_o;
 	wire	[ bus_Dw-1      :   0 ] bus_socket_wb_master_0_dat_o;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_err_o;
 	wire			 bus_socket_wb_master_2_err_o;
 	wire			 bus_socket_wb_master_1_err_o;
 	wire			 bus_socket_wb_master_0_err_o;
 	wire	[ bus_Aw-1       :   0 ] bus_socket_wb_addr_map_0_grant_addr;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_rty_o;
 	wire			 bus_socket_wb_master_2_rty_o;
 	wire			 bus_socket_wb_master_1_rty_o;
 	wire			 bus_socket_wb_master_0_rty_o;
 	wire	[ (bus_SELw*bus_M)-1    :   0 ] bus_socket_wb_master_array_sel_i;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_master_2_sel_i;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_master_1_sel_i;
 	wire	[ bus_SELw-1    :   0 ] bus_socket_wb_master_0_sel_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_stb_i;
 	wire			 bus_socket_wb_master_2_stb_i;
 	wire			 bus_socket_wb_master_1_stb_i;
 	wire			 bus_socket_wb_master_0_stb_i;
 	wire	[ (bus_TAGw*bus_M)-1    :   0 ] bus_socket_wb_master_array_tag_i;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_master_2_tag_i;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_master_1_tag_i;
 	wire	[ bus_TAGw-1    :   0 ] bus_socket_wb_master_0_tag_i;
 	wire	[ bus_M-1        :   0 ] bus_socket_wb_master_array_we_i;
 	wire			 bus_socket_wb_master_2_we_i;
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

 Altera_single_port_ram #(
 		.Dw(Altera_single_port_ram0_Dw),
		.Aw(Altera_single_port_ram0_Aw),
		.TAGw(Altera_single_port_ram0_TAGw),
		.SELw(Altera_single_port_ram0_SELw),
		.RAM_TAG_STRING(Altera_single_port_ram0_RAM_TAG_STRING)
	)  Altera_single_port_ram0 	(
		.clk(Altera_single_port_ram0_plug_clk_0_clk_i),
		.reset(Altera_single_port_ram0_plug_reset_0_reset_i),
		.sa_ack_o(Altera_single_port_ram0_plug_wb_slave_0_ack_o),
		.sa_addr_i(Altera_single_port_ram0_plug_wb_slave_0_adr_i),
		.sa_cyc_i(Altera_single_port_ram0_plug_wb_slave_0_cyc_i),
		.sa_dat_i(Altera_single_port_ram0_plug_wb_slave_0_dat_i),
		.sa_dat_o(Altera_single_port_ram0_plug_wb_slave_0_dat_o),
		.sa_err_o(Altera_single_port_ram0_plug_wb_slave_0_err_o),
		.sa_rty_o(Altera_single_port_ram0_plug_wb_slave_0_rty_o),
		.sa_sel_i(Altera_single_port_ram0_plug_wb_slave_0_sel_i),
		.sa_stb_i(Altera_single_port_ram0_plug_wb_slave_0_stb_i),
		.sa_tag_i(Altera_single_port_ram0_plug_wb_slave_0_tag_i),
		.sa_we_i(Altera_single_port_ram0_plug_wb_slave_0_we_i)
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
		.sys_int_i()
	);
 clk_source  clk_source0 	(
		.clk_in(clk_source0_clk_in),
		.clk_out(clk_source0_socket_clk_0_clk_o),
		.reset_in(clk_source0_reset_in),
		.reset_out(clk_source0_socket_reset_0_reset_o)
	);
 gpi #(
 		.PORT_WIDTH(gpi_PORT_WIDTH),
		.Dw(gpi_Dw),
		.Aw(gpi_Aw),
		.TAGw(gpi_TAGw),
		.SELw(gpi_SELw)
	)  gpi 	(
		.clk(gpi_plug_clk_0_clk_i),
		.port_i(gpi_port_i),
		.reset(gpi_plug_reset_0_reset_i),
		.sa_ack_o(gpi_plug_wb_slave_0_ack_o),
		.sa_addr_i(gpi_plug_wb_slave_0_adr_i),
		.sa_cyc_i(gpi_plug_wb_slave_0_cyc_i),
		.sa_dat_i(gpi_plug_wb_slave_0_dat_i),
		.sa_dat_o(gpi_plug_wb_slave_0_dat_o),
		.sa_err_o(gpi_plug_wb_slave_0_err_o),
		.sa_rty_o(gpi_plug_wb_slave_0_rty_o),
		.sa_sel_i(gpi_plug_wb_slave_0_sel_i),
		.sa_stb_i(gpi_plug_wb_slave_0_stb_i),
		.sa_tag_i(gpi_plug_wb_slave_0_tag_i),
		.sa_we_i(gpi_plug_wb_slave_0_we_i)
	);
 ni #(
 		.NY(ni_NY),
		.NX(ni_NX),
		.V(ni_V),
		.B(ni_B),
		.Dw(ni_Dw),
		.DEBUG_EN(ni_DEBUG_EN),
		.TAGw(ni_TAGw),
		.M_Aw(ni_M_Aw),
		.ROUTE_NAME(ni_ROUTE_NAME),
		.Fpay(ni_Fpay),
		.SELw(ni_SELw),
		.ROUTE_TYPE(ni_ROUTE_TYPE),
		.P(ni_P),
		.S_Aw(ni_S_Aw),
		.TOPOLOGY(ni_TOPOLOGY)
	)  ni 	(
		.clk(ni_plug_clk_0_clk_i),
		.credit_in(ni_credit_in),
		.credit_out(ni_credit_out),
		.current_x(ni_current_x),
		.current_y(ni_current_y),
		.flit_in(ni_flit_in),
		.flit_in_wr(ni_flit_in_wr),
		.flit_out(ni_flit_out),
		.flit_out_wr(ni_flit_out_wr),
		.irq(),
		.m_ack_i(ni_plug_wb_master_0_ack_i),
		.m_addr_o(ni_plug_wb_master_0_adr_o),
		.m_cyc_o(ni_plug_wb_master_0_cyc_o),
		.m_dat_i(ni_plug_wb_master_0_dat_i),
		.m_dat_o(ni_plug_wb_master_0_dat_o),
		.m_err_i(ni_plug_wb_master_0_err_i),
		.m_rty_i(ni_plug_wb_master_0_rty_i),
		.m_sel_o(ni_plug_wb_master_0_sel_o),
		.m_stb_o(ni_plug_wb_master_0_stb_o),
		.m_tag_o(ni_plug_wb_master_0_tag_o),
		.m_we_o(ni_plug_wb_master_0_we_o),
		.reset(ni_plug_reset_0_reset_i),
		.s_ack_o(ni_plug_wb_slave_0_ack_o),
		.s_addr_i(ni_plug_wb_slave_0_adr_i),
		.s_cyc_i(ni_plug_wb_slave_0_cyc_i),
		.s_dat_i(ni_plug_wb_slave_0_dat_i),
		.s_dat_o(ni_plug_wb_slave_0_dat_o),
		.s_err_o(ni_plug_wb_slave_0_err_o),
		.s_rty_o(ni_plug_wb_slave_0_rty_o),
		.s_sel_i(ni_plug_wb_slave_0_sel_i),
		.s_stb_i(ni_plug_wb_slave_0_stb_i),
		.s_tag_i(ni_plug_wb_slave_0_tag_i),
		.s_we_i(ni_plug_wb_slave_0_we_i)
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
 
 	assign  Altera_single_port_ram0_plug_clk_0_clk_i = clk_source0_socket_clk_0_clk_o;
 	assign  Altera_single_port_ram0_plug_reset_0_reset_i = clk_source0_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_2_ack_i  = Altera_single_port_ram0_plug_wb_slave_0_ack_o;
 	assign  Altera_single_port_ram0_plug_wb_slave_0_adr_i = bus_socket_wb_slave_2_adr_o[Altera_single_port_ram0_Aw-1       :   0];
 	assign  Altera_single_port_ram0_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_2_cyc_o;
 	assign  Altera_single_port_ram0_plug_wb_slave_0_dat_i = bus_socket_wb_slave_2_dat_o[Altera_single_port_ram0_Dw-1       :   0];
 	assign  bus_socket_wb_slave_2_dat_i  = Altera_single_port_ram0_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_2_err_i  = Altera_single_port_ram0_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_2_rty_i  = Altera_single_port_ram0_plug_wb_slave_0_rty_o;
 	assign  Altera_single_port_ram0_plug_wb_slave_0_sel_i = bus_socket_wb_slave_2_sel_o[Altera_single_port_ram0_SELw-1     :   0];
 	assign  Altera_single_port_ram0_plug_wb_slave_0_stb_i = bus_socket_wb_slave_2_stb_o;
 	assign  Altera_single_port_ram0_plug_wb_slave_0_tag_i = bus_socket_wb_slave_2_tag_o[Altera_single_port_ram0_TAGw-1     :   0];
 	assign  Altera_single_port_ram0_plug_wb_slave_0_we_i = bus_socket_wb_slave_2_we_o;

 
 	assign  aeMB0_plug_clk_0_clk_i = clk_source0_socket_clk_0_clk_o;
 	assign  aeMB0_plug_wb_master_1_ack_i = bus_socket_wb_master_2_ack_o;
 	assign  bus_socket_wb_master_2_adr_i  = aeMB0_plug_wb_master_1_adr_o;
 	assign  bus_socket_wb_master_2_cyc_i  = aeMB0_plug_wb_master_1_cyc_o;
 	assign  aeMB0_plug_wb_master_1_dat_i = bus_socket_wb_master_2_dat_o[31:0];
 	assign  bus_socket_wb_master_2_dat_i  = aeMB0_plug_wb_master_1_dat_o;
 	assign  aeMB0_plug_wb_master_1_err_i = bus_socket_wb_master_2_err_o;
 	assign  aeMB0_plug_wb_master_1_rty_i = bus_socket_wb_master_2_rty_o;
 	assign  bus_socket_wb_master_2_sel_i  = aeMB0_plug_wb_master_1_sel_o;
 	assign  bus_socket_wb_master_2_stb_i  = aeMB0_plug_wb_master_1_stb_o;
 	assign  bus_socket_wb_master_2_tag_i  = aeMB0_plug_wb_master_1_tag_o;
 	assign  bus_socket_wb_master_2_we_i  = aeMB0_plug_wb_master_1_we_o;
 	assign  aeMB0_plug_wb_master_0_ack_i = bus_socket_wb_master_1_ack_o;
 	assign  bus_socket_wb_master_1_adr_i  = aeMB0_plug_wb_master_0_adr_o;
 	assign  bus_socket_wb_master_1_cyc_i  = aeMB0_plug_wb_master_0_cyc_o;
 	assign  aeMB0_plug_wb_master_0_dat_i = bus_socket_wb_master_1_dat_o[31:0];
 	assign  bus_socket_wb_master_1_dat_i  = aeMB0_plug_wb_master_0_dat_o;
 	assign  aeMB0_plug_wb_master_0_err_i = bus_socket_wb_master_1_err_o;
 	assign  aeMB0_plug_wb_master_0_rty_i = bus_socket_wb_master_1_rty_o;
 	assign  bus_socket_wb_master_1_sel_i  = aeMB0_plug_wb_master_0_sel_o;
 	assign  bus_socket_wb_master_1_stb_i  = aeMB0_plug_wb_master_0_stb_o;
 	assign  bus_socket_wb_master_1_tag_i  = aeMB0_plug_wb_master_0_tag_o;
 	assign  bus_socket_wb_master_1_we_i  = aeMB0_plug_wb_master_0_we_o;
 	assign  aeMB0_plug_reset_0_reset_i = clk_source0_socket_reset_0_reset_o;

 

 
 	assign  gpi_plug_clk_0_clk_i = clk_source0_socket_clk_0_clk_o;
 	assign  gpi_plug_reset_0_reset_i = clk_source0_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_0_ack_i  = gpi_plug_wb_slave_0_ack_o;
 	assign  gpi_plug_wb_slave_0_adr_i = bus_socket_wb_slave_0_adr_o[gpi_Aw-1       :   0];
 	assign  gpi_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_0_cyc_o;
 	assign  gpi_plug_wb_slave_0_dat_i = bus_socket_wb_slave_0_dat_o[gpi_Dw-1       :   0];
 	assign  bus_socket_wb_slave_0_dat_i  = gpi_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_0_err_i  = gpi_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_0_rty_i  = gpi_plug_wb_slave_0_rty_o;
 	assign  gpi_plug_wb_slave_0_sel_i = bus_socket_wb_slave_0_sel_o[gpi_SELw-1     :   0];
 	assign  gpi_plug_wb_slave_0_stb_i = bus_socket_wb_slave_0_stb_o;
 	assign  gpi_plug_wb_slave_0_tag_i = bus_socket_wb_slave_0_tag_o[gpi_TAGw-1     :   0];
 	assign  gpi_plug_wb_slave_0_we_i = bus_socket_wb_slave_0_we_o;

 
 	assign  ni_plug_clk_0_clk_i = clk_source0_socket_clk_0_clk_o;
 	assign  ni_plug_wb_master_0_ack_i = bus_socket_wb_master_0_ack_o;
 	assign  bus_socket_wb_master_0_adr_i  = ni_plug_wb_master_0_adr_o;
 	assign  bus_socket_wb_master_0_cyc_i  = ni_plug_wb_master_0_cyc_o;
 	assign  ni_plug_wb_master_0_dat_i = bus_socket_wb_master_0_dat_o[ni_Dw-1           :  0];
 	assign  bus_socket_wb_master_0_dat_i  = ni_plug_wb_master_0_dat_o;
 	assign  ni_plug_wb_master_0_err_i = bus_socket_wb_master_0_err_o;
 	assign  ni_plug_wb_master_0_rty_i = bus_socket_wb_master_0_rty_o;
 	assign  bus_socket_wb_master_0_sel_i  = ni_plug_wb_master_0_sel_o;
 	assign  bus_socket_wb_master_0_stb_i  = ni_plug_wb_master_0_stb_o;
 	assign  bus_socket_wb_master_0_tag_i  = ni_plug_wb_master_0_tag_o;
 	assign  bus_socket_wb_master_0_we_i  = ni_plug_wb_master_0_we_o;
 	assign  ni_plug_reset_0_reset_i = clk_source0_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_1_ack_i  = ni_plug_wb_slave_0_ack_o;
 	assign  ni_plug_wb_slave_0_adr_i = bus_socket_wb_slave_1_adr_o[ni_S_Aw-1     :   0];
 	assign  ni_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_1_cyc_o;
 	assign  ni_plug_wb_slave_0_dat_i = bus_socket_wb_slave_1_dat_o[ni_Dw-1       :   0];
 	assign  bus_socket_wb_slave_1_dat_i  = ni_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_1_err_i  = ni_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_1_rty_i  = ni_plug_wb_slave_0_rty_o;
 	assign  ni_plug_wb_slave_0_sel_i = bus_socket_wb_slave_1_sel_o[ni_SELw-1     :   0];
 	assign  ni_plug_wb_slave_0_stb_i = bus_socket_wb_slave_1_stb_o;
 	assign  ni_plug_wb_slave_0_tag_i = bus_socket_wb_slave_1_tag_o[ni_TAGw-1     :   0];
 	assign  ni_plug_wb_slave_0_we_i = bus_socket_wb_slave_1_we_o;

 
 	assign  bus_plug_clk_0_clk_i = clk_source0_socket_clk_0_clk_o;
 	assign  bus_plug_reset_0_reset_i = clk_source0_socket_reset_0_reset_o;

 	assign {bus_socket_wb_master_2_ack_o ,bus_socket_wb_master_1_ack_o ,bus_socket_wb_master_0_ack_o} =bus_socket_wb_master_array_ack_o;
 	assign bus_socket_wb_master_array_adr_i ={bus_socket_wb_master_2_adr_i ,bus_socket_wb_master_1_adr_i ,bus_socket_wb_master_0_adr_i};
 	assign bus_socket_wb_master_array_cyc_i ={bus_socket_wb_master_2_cyc_i ,bus_socket_wb_master_1_cyc_i ,bus_socket_wb_master_0_cyc_i};
 	assign bus_socket_wb_master_array_dat_i ={bus_socket_wb_master_2_dat_i ,bus_socket_wb_master_1_dat_i ,bus_socket_wb_master_0_dat_i};
 	assign {bus_socket_wb_master_2_dat_o ,bus_socket_wb_master_1_dat_o ,bus_socket_wb_master_0_dat_o} =bus_socket_wb_master_array_dat_o;
 	assign {bus_socket_wb_master_2_err_o ,bus_socket_wb_master_1_err_o ,bus_socket_wb_master_0_err_o} =bus_socket_wb_master_array_err_o;
 	assign {bus_socket_wb_master_2_rty_o ,bus_socket_wb_master_1_rty_o ,bus_socket_wb_master_0_rty_o} =bus_socket_wb_master_array_rty_o;
 	assign bus_socket_wb_master_array_sel_i ={bus_socket_wb_master_2_sel_i ,bus_socket_wb_master_1_sel_i ,bus_socket_wb_master_0_sel_i};
 	assign bus_socket_wb_master_array_stb_i ={bus_socket_wb_master_2_stb_i ,bus_socket_wb_master_1_stb_i ,bus_socket_wb_master_0_stb_i};
 	assign bus_socket_wb_master_array_tag_i ={bus_socket_wb_master_2_tag_i ,bus_socket_wb_master_1_tag_i ,bus_socket_wb_master_0_tag_i};
 	assign bus_socket_wb_master_array_we_i ={bus_socket_wb_master_2_we_i ,bus_socket_wb_master_1_we_i ,bus_socket_wb_master_0_we_i};
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
 /* Altera_single_port_ram0 wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[2]= ((bus_socket_wb_addr_map_0_grant_addr >= Altera_single_port_ram0_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< Altera_single_port_ram0_END_ADDR));
 /* gpi wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[0]= ((bus_socket_wb_addr_map_0_grant_addr >= gpi_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< gpi_END_ADDR));
 /* ni wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[1]= ((bus_socket_wb_addr_map_0_grant_addr >= ni_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< ni_END_ADDR));
 endmodule

