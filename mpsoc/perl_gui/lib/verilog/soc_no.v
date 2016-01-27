module soc_no #(
 	parameter	CORE_ID=0 ,
	parameter	aeMB0_AEMB_MUL= 1 ,
	parameter	aeMB0_AEMB_BSF= 1 ,
	parameter	gpo0_PORT_WIDTH=   1 ,
	parameter	ni0_NY= 2 ,
	parameter	ni0_NX= 2 ,
	parameter	ni0_V= 4 ,
	parameter	ni0_B= 4 ,
	parameter	ni0_DEBUG_EN=   1 ,
	parameter	ni0_ROUTE_NAME="XY"      ,
	parameter	ni0_TOPOLOGY=    "MESH"
)(
	aeMB0_sys_ena_i, 
	clk_source0_clk_in, 
	clk_source0_reset_in, 
	gpo0_port_o, 
	ni0_credit_in, 
	ni0_credit_out, 
	ni0_current_x, 
	ni0_current_y, 
	ni0_flit_in, 
	ni0_flit_in_wr, 
	ni0_flit_out, 
	ni0_flit_out_wr
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
  	localparam	Altera_ram0_Aw=13;
	localparam	Altera_ram0_FPGA_FAMILY="ALTERA";
	localparam	Altera_ram0_RAM_TAG_STRING="00";
	localparam	Altera_ram0_TAGw=3;
	localparam	Altera_ram0_Dw=32;
	localparam	Altera_ram0_SELw=4;

 	localparam	aeMB0_AEMB_XWB= 7;
	localparam	aeMB0_AEMB_IDX= 6;
	localparam	aeMB0_AEMB_IWB= 32;
	localparam	aeMB0_AEMB_ICH= 11;
	localparam	aeMB0_AEMB_DWB= 32;

 
 	localparam	gpo0_Dw=    32;
	localparam	gpo0_Aw=    2;
	localparam	gpo0_TAGw=    3;
	localparam	gpo0_SELw=    4;

 	localparam	int_ctrl0_INT_NUM=2;
	localparam	int_ctrl0_Dw=    32;
	localparam	int_ctrl0_Aw= 3;
	localparam	int_ctrl0_SELw= 4    ;

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

 	localparam	timer0_CNTw=32     ;
	localparam	timer0_Dw=	32;
	localparam	timer0_Aw= 3;
	localparam	timer0_TAGw=3;
	localparam	timer0_SELw=	4;

 	localparam	bus_S=5;
	localparam	bus_M=	4;
	localparam	bus_Aw=	32;
	localparam	bus_TAGw=	3    ;
	localparam	bus_SELw=	4;
	localparam	bus_Dw=	32;

 
//Wishbone slave base address based on instance name
 	localparam 	Altera_ram0_BASE_ADDR	=	32'h00000000;
 	localparam 	Altera_ram0_END_ADDR	=	32'h00003fff;
 	localparam 	gpo0_BASE_ADDR	=	32'h24400000;
 	localparam 	gpo0_END_ADDR	=	32'h24400007;
 	localparam 	int_ctrl0_BASE_ADDR	=	32'h27800000;
 	localparam 	int_ctrl0_END_ADDR	=	32'h27800007;
 	localparam 	ni0_BASE_ADDR	=	32'h2e000000;
 	localparam 	ni0_END_ADDR	=	32'h2e000007;
 	localparam 	timer0_BASE_ADDR	=	32'h25800000;
 	localparam 	timer0_END_ADDR	=	32'h25800007;
 
 
//Wishbone slave base address based on module name. 
 
 	input			aeMB0_sys_ena_i;

 	input			clk_source0_clk_in;
 	input			clk_source0_reset_in;

 	output	 [ gpo0_PORT_WIDTH-1     :   0    ] gpo0_port_o;

 	input	 [ ni0_V-1    :   0    ] ni0_credit_in;
 	output	 [ ni0_V-1:   0    ] ni0_credit_out;
 	input	 [ ni0_Xw-1   :   0    ] ni0_current_x;
 	input	 [ ni0_Yw-1   :   0    ] ni0_current_y;
 	input	 [ ni0_Fw-1   :   0    ] ni0_flit_in;
 	input			ni0_flit_in_wr;
 	output	 [ ni0_Fw-1   :   0    ] ni0_flit_out;
 	output			ni0_flit_out_wr;

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
 	wire			 aeMB0_plug_interrupt_cpu_0_int_i;

 	wire			 clk_source0_socket_clk_0_clk_o;
 	wire			 clk_source0_socket_reset_0_reset_o;

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

 	wire			 int_ctrl0_plug_clk_0_clk_i;
 	wire	[ int_ctrl0_INT_NUM-1  :   0 ] int_ctrl0_socket_interrupt_peripheral_array_int_i;
 	wire			 int_ctrl0_socket_interrupt_peripheral_1_int_i;
 	wire			 int_ctrl0_socket_interrupt_peripheral_0_int_i;
 	wire			 int_ctrl0_socket_interrupt_cpu_0_int_o;
 	wire			 int_ctrl0_plug_reset_0_reset_i;
 	wire			 int_ctrl0_plug_wb_slave_0_ack_o;
 	wire	[ int_ctrl0_Aw-1       :   0 ] int_ctrl0_plug_wb_slave_0_adr_i;
 	wire	[ int_ctrl0_Dw-1       :   0 ] int_ctrl0_plug_wb_slave_0_dat_i;
 	wire	[ int_ctrl0_Dw-1       :   0 ] int_ctrl0_plug_wb_slave_0_dat_o;
 	wire			 int_ctrl0_plug_wb_slave_0_err_o;
 	wire			 int_ctrl0_plug_wb_slave_0_rty_o;
 	wire	[ int_ctrl0_SELw-1     :   0 ] int_ctrl0_plug_wb_slave_0_sel_i;
 	wire			 int_ctrl0_plug_wb_slave_0_stb_i;
 	wire			 int_ctrl0_plug_wb_slave_0_we_i;

 	wire			 ni0_plug_clk_0_clk_i;
 	wire			 ni0_plug_interrupt_peripheral_0_int_o;
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

 	wire			 timer0_plug_clk_0_clk_i;
 	wire			 timer0_plug_interrupt_peripheral_0_int_o;
 	wire			 timer0_plug_reset_0_reset_i;
 	wire			 timer0_plug_wb_slave_0_ack_o;
 	wire	[ timer0_Aw-1       :   0 ] timer0_plug_wb_slave_0_adr_i;
 	wire			 timer0_plug_wb_slave_0_cyc_i;
 	wire	[ timer0_Dw-1       :   0 ] timer0_plug_wb_slave_0_dat_i;
 	wire	[ timer0_Dw-1       :   0 ] timer0_plug_wb_slave_0_dat_o;
 	wire			 timer0_plug_wb_slave_0_err_o;
 	wire			 timer0_plug_wb_slave_0_rty_o;
 	wire	[ timer0_SELw-1     :   0 ] timer0_plug_wb_slave_0_sel_i;
 	wire			 timer0_plug_wb_slave_0_stb_i;
 	wire	[ timer0_TAGw-1     :   0 ] timer0_plug_wb_slave_0_tag_i;
 	wire			 timer0_plug_wb_slave_0_we_i;

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
		.sys_int_i(aeMB0_plug_interrupt_cpu_0_int_i)
	);
 clk_source  clk_source0 	(
		.clk_in(clk_source0_clk_in),
		.clk_out(clk_source0_socket_clk_0_clk_o),
		.reset_in(clk_source0_reset_in),
		.reset_out(clk_source0_socket_reset_0_reset_o)
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
 int_ctrl #(
 		.INT_NUM(int_ctrl0_INT_NUM),
		.Dw(int_ctrl0_Dw),
		.Aw(int_ctrl0_Aw),
		.SELw(int_ctrl0_SELw)
	)  int_ctrl0 	(
		.clk(int_ctrl0_plug_clk_0_clk_i),
		.int_i(int_ctrl0_socket_interrupt_peripheral_array_int_i),
		.int_o(int_ctrl0_socket_interrupt_cpu_0_int_o),
		.reset(int_ctrl0_plug_reset_0_reset_i),
		.sa_ack_o(int_ctrl0_plug_wb_slave_0_ack_o),
		.sa_addr_i(int_ctrl0_plug_wb_slave_0_adr_i),
		.sa_dat_i(int_ctrl0_plug_wb_slave_0_dat_i),
		.sa_dat_o(int_ctrl0_plug_wb_slave_0_dat_o),
		.sa_err_o(int_ctrl0_plug_wb_slave_0_err_o),
		.sa_rty_o(int_ctrl0_plug_wb_slave_0_rty_o),
		.sa_sel_i(int_ctrl0_plug_wb_slave_0_sel_i),
		.sa_stb_i(int_ctrl0_plug_wb_slave_0_stb_i),
		.sa_we_i(int_ctrl0_plug_wb_slave_0_we_i)
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
		.irq(ni0_plug_interrupt_peripheral_0_int_o),
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
 timer #(
 		.CNTw(timer0_CNTw),
		.Dw(timer0_Dw),
		.Aw(timer0_Aw),
		.TAGw(timer0_TAGw),
		.SELw(timer0_SELw)
	)  timer0 	(
		.clk(timer0_plug_clk_0_clk_i),
		.irq(timer0_plug_interrupt_peripheral_0_int_o),
		.reset(timer0_plug_reset_0_reset_i),
		.sa_ack_o(timer0_plug_wb_slave_0_ack_o),
		.sa_addr_i(timer0_plug_wb_slave_0_adr_i),
		.sa_cyc_i(timer0_plug_wb_slave_0_cyc_i),
		.sa_dat_i(timer0_plug_wb_slave_0_dat_i),
		.sa_dat_o(timer0_plug_wb_slave_0_dat_o),
		.sa_err_o(timer0_plug_wb_slave_0_err_o),
		.sa_rty_o(timer0_plug_wb_slave_0_rty_o),
		.sa_sel_i(timer0_plug_wb_slave_0_sel_i),
		.sa_stb_i(timer0_plug_wb_slave_0_stb_i),
		.sa_tag_i(timer0_plug_wb_slave_0_tag_i),
		.sa_we_i(timer0_plug_wb_slave_0_we_i)
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
 	assign  aeMB0_plug_interrupt_cpu_0_int_i = int_ctrl0_socket_interrupt_cpu_0_int_o;

 

 
 	assign  gpo0_plug_clk_0_clk_i = clk_source0_socket_clk_0_clk_o;
 	assign  gpo0_plug_reset_0_reset_i = clk_source0_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_1_ack_i  = gpo0_plug_wb_slave_0_ack_o;
 	assign  gpo0_plug_wb_slave_0_adr_i = bus_socket_wb_slave_1_adr_o;
 	assign  gpo0_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_1_cyc_o;
 	assign  gpo0_plug_wb_slave_0_dat_i = bus_socket_wb_slave_1_dat_o;
 	assign  bus_socket_wb_slave_1_dat_i  = gpo0_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_1_err_i  = gpo0_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_1_rty_i  = gpo0_plug_wb_slave_0_rty_o;
 	assign  gpo0_plug_wb_slave_0_sel_i = bus_socket_wb_slave_1_sel_o;
 	assign  gpo0_plug_wb_slave_0_stb_i = bus_socket_wb_slave_1_stb_o;
 	assign  gpo0_plug_wb_slave_0_tag_i = bus_socket_wb_slave_1_tag_o;
 	assign  gpo0_plug_wb_slave_0_we_i = bus_socket_wb_slave_1_we_o;

 
 	assign  int_ctrl0_plug_clk_0_clk_i = clk_source0_socket_clk_0_clk_o;
 	assign  int_ctrl0_plug_reset_0_reset_i = clk_source0_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_4_ack_i  = int_ctrl0_plug_wb_slave_0_ack_o;
 	assign  int_ctrl0_plug_wb_slave_0_adr_i = bus_socket_wb_slave_4_adr_o;
 	assign  int_ctrl0_plug_wb_slave_0_dat_i = bus_socket_wb_slave_4_dat_o;
 	assign  bus_socket_wb_slave_4_dat_i  = int_ctrl0_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_4_err_i  = int_ctrl0_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_4_rty_i  = int_ctrl0_plug_wb_slave_0_rty_o;
 	assign  int_ctrl0_plug_wb_slave_0_sel_i = bus_socket_wb_slave_4_sel_o;
 	assign  int_ctrl0_plug_wb_slave_0_stb_i = bus_socket_wb_slave_4_stb_o;
 	assign  int_ctrl0_plug_wb_slave_0_we_i = bus_socket_wb_slave_4_we_o;

 
 	assign  ni0_plug_clk_0_clk_i = clk_source0_socket_clk_0_clk_o;
 	assign  int_ctrl0_socket_interrupt_peripheral_1_int_i  = ni0_plug_interrupt_peripheral_0_int_o;
 	assign  ni0_plug_wb_master_0_ack_i = bus_socket_wb_master_2_ack_o;
 	assign  bus_socket_wb_master_2_adr_i  = ni0_plug_wb_master_0_adr_o;
 	assign  bus_socket_wb_master_2_cyc_i  = ni0_plug_wb_master_0_cyc_o;
 	assign  ni0_plug_wb_master_0_dat_i = bus_socket_wb_master_2_dat_o;
 	assign  bus_socket_wb_master_2_dat_i  = ni0_plug_wb_master_0_dat_o;
 	assign  ni0_plug_wb_master_0_err_i = bus_socket_wb_master_2_err_o;
 	assign  ni0_plug_wb_master_0_rty_i = bus_socket_wb_master_2_rty_o;
 	assign  bus_socket_wb_master_2_sel_i  = ni0_plug_wb_master_0_sel_o;
 	assign  bus_socket_wb_master_2_stb_i  = ni0_plug_wb_master_0_stb_o;
 	assign  bus_socket_wb_master_2_tag_i  = ni0_plug_wb_master_0_tag_o;
 	assign  bus_socket_wb_master_2_we_i  = ni0_plug_wb_master_0_we_o;
 	assign  ni0_plug_reset_0_reset_i = clk_source0_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_0_ack_i  = ni0_plug_wb_slave_0_ack_o;
 	assign  ni0_plug_wb_slave_0_adr_i = bus_socket_wb_slave_0_adr_o;
 	assign  ni0_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_0_cyc_o;
 	assign  ni0_plug_wb_slave_0_dat_i = bus_socket_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_0_dat_i  = ni0_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_0_err_i  = ni0_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_0_rty_i  = ni0_plug_wb_slave_0_rty_o;
 	assign  ni0_plug_wb_slave_0_sel_i = bus_socket_wb_slave_0_sel_o;
 	assign  ni0_plug_wb_slave_0_stb_i = bus_socket_wb_slave_0_stb_o;
 	assign  ni0_plug_wb_slave_0_tag_i = bus_socket_wb_slave_0_tag_o;
 	assign  ni0_plug_wb_slave_0_we_i = bus_socket_wb_slave_0_we_o;

 
 	assign  timer0_plug_clk_0_clk_i = clk_source0_socket_clk_0_clk_o;
 	assign  int_ctrl0_socket_interrupt_peripheral_0_int_i  = timer0_plug_interrupt_peripheral_0_int_o;
 	assign  timer0_plug_reset_0_reset_i = clk_source0_socket_reset_0_reset_o;
 	assign  bus_socket_wb_slave_3_ack_i  = timer0_plug_wb_slave_0_ack_o;
 	assign  timer0_plug_wb_slave_0_adr_i = bus_socket_wb_slave_3_adr_o;
 	assign  timer0_plug_wb_slave_0_cyc_i = bus_socket_wb_slave_3_cyc_o;
 	assign  timer0_plug_wb_slave_0_dat_i = bus_socket_wb_slave_3_dat_o;
 	assign  bus_socket_wb_slave_3_dat_i  = timer0_plug_wb_slave_0_dat_o;
 	assign  bus_socket_wb_slave_3_err_i  = timer0_plug_wb_slave_0_err_o;
 	assign  bus_socket_wb_slave_3_rty_i  = timer0_plug_wb_slave_0_rty_o;
 	assign  timer0_plug_wb_slave_0_sel_i = bus_socket_wb_slave_3_sel_o;
 	assign  timer0_plug_wb_slave_0_stb_i = bus_socket_wb_slave_3_stb_o;
 	assign  timer0_plug_wb_slave_0_tag_i = bus_socket_wb_slave_3_tag_o;
 	assign  timer0_plug_wb_slave_0_we_i = bus_socket_wb_slave_3_we_o;

 
 	assign  bus_plug_clk_0_clk_i = clk_source0_socket_clk_0_clk_o;
 	assign  bus_plug_reset_0_reset_i = clk_source0_socket_reset_0_reset_o;

 	assign int_ctrl0_socket_interrupt_peripheral_array_int_i ={int_ctrl0_socket_interrupt_peripheral_1_int_i ,int_ctrl0_socket_interrupt_peripheral_0_int_i};

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
 /* gpo0 wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[1]= ((bus_socket_wb_addr_map_0_grant_addr >= gpo0_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< gpo0_END_ADDR));
 /* int_ctrl0 wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[4]= ((bus_socket_wb_addr_map_0_grant_addr >= int_ctrl0_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< int_ctrl0_END_ADDR));
 /* ni0 wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[0]= ((bus_socket_wb_addr_map_0_grant_addr >= ni0_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< ni0_END_ADDR));
 /* timer0 wb_slave 0 */
 	assign bus_socket_wb_addr_map_0_sel_one_hot[3]= ((bus_socket_wb_addr_map_0_grant_addr >= timer0_BASE_ADDR)   & (bus_socket_wb_addr_map_0_grant_addr< timer0_END_ADDR));
 endmodule

