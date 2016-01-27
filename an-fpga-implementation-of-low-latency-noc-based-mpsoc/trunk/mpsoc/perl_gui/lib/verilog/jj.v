module jj #(
    	parameter	aeMB0_AEMB_MUL= 1 ,
	parameter	aeMB0_AEMB_BSF= 1 ,
	parameter	aeMB2_AEMB_MUL= 1 ,
	parameter	aeMB2_AEMB_BSF= 1 ,
	parameter	gpi0_PORT_WIDTH=   1
)(
	aeMB0_clk, 
	aeMB0_dwb_ack_i, 
	aeMB0_dwb_adr_o, 
	aeMB0_dwb_cyc_o, 
	aeMB0_dwb_dat_i, 
	aeMB0_dwb_dat_o, 
	aeMB0_dwb_err_i, 
	aeMB0_dwb_rty_i, 
	aeMB0_dwb_sel_o, 
	aeMB0_dwb_stb_o, 
	aeMB0_dwb_tag_o, 
	aeMB0_dwb_wre_o, 
	aeMB0_iwb_ack_i, 
	aeMB0_iwb_adr_o, 
	aeMB0_iwb_cyc_o, 
	aeMB0_iwb_dat_i, 
	aeMB0_iwb_dat_o, 
	aeMB0_iwb_err_i, 
	aeMB0_iwb_rty_i, 
	aeMB0_iwb_sel_o, 
	aeMB0_iwb_stb_o, 
	aeMB0_iwb_tag_o, 
	aeMB0_iwb_wre_o, 
	aeMB0_reset, 
	aeMB0_sys_ena_i, 
	aeMB0_sys_int_i, 
	aeMB2_clk, 
	aeMB2_dwb_ack_i, 
	aeMB2_dwb_adr_o, 
	aeMB2_dwb_cyc_o, 
	aeMB2_dwb_dat_i, 
	aeMB2_dwb_dat_o, 
	aeMB2_dwb_err_i, 
	aeMB2_dwb_rty_i, 
	aeMB2_dwb_sel_o, 
	aeMB2_dwb_stb_o, 
	aeMB2_dwb_tag_o, 
	aeMB2_dwb_wre_o, 
	aeMB2_iwb_ack_i, 
	aeMB2_iwb_adr_o, 
	aeMB2_iwb_cyc_o, 
	aeMB2_iwb_dat_i, 
	aeMB2_iwb_dat_o, 
	aeMB2_iwb_err_i, 
	aeMB2_iwb_rty_i, 
	aeMB2_iwb_sel_o, 
	aeMB2_iwb_stb_o, 
	aeMB2_iwb_tag_o, 
	aeMB2_iwb_wre_o, 
	aeMB2_reset, 
	aeMB2_sys_ena_i, 
	aeMB2_sys_int_i, 
	gpi0_clk, 
	gpi0_port_i, 
	gpi0_reset, 
	gpi0_sa_ack_o, 
	gpi0_sa_addr_i, 
	gpi0_sa_cyc_i, 
	gpi0_sa_dat_i, 
	gpi0_sa_dat_o, 
	gpi0_sa_err_o, 
	gpi0_sa_rty_o, 
	gpi0_sa_sel_i, 
	gpi0_sa_stb_i, 
	gpi0_sa_tag_i, 
	gpi0_sa_we_i
);
  
  	function integer log2;
  		input integer number; begin	
          	log2=0;	
          	while(2**log2<number) begin	
        		  	log2=log2+1;	
         		end	
        		end	
     	endfunction // log2 
  	localparam	aeMB0_AEMB_XWB= 7;
	localparam	aeMB0_AEMB_IDX= 6;
	localparam	aeMB0_AEMB_IWB= 32;
	localparam	aeMB0_AEMB_ICH= 11;
	localparam	aeMB0_AEMB_DWB= 32;

 	localparam	aeMB2_AEMB_XWB= 7;
	localparam	aeMB2_AEMB_IDX= 6;
	localparam	aeMB2_AEMB_IWB= 32;
	localparam	aeMB2_AEMB_ICH= 11;
	localparam	aeMB2_AEMB_DWB= 32;

 	localparam	gpi0_Dw=   32;
	localparam	gpi0_Aw=   2;
	localparam	gpi0_TAGw=   3;
	localparam	gpi0_SELw=   4;

 
//Wishbone slave base address based on instance name
 
 
//Wishbone slave base address based on module name. 
 
 	input			aeMB0_clk;
 	input			aeMB0_dwb_ack_i;
 	output	 [ 31:0    ] aeMB0_dwb_adr_o;
 	output			aeMB0_dwb_cyc_o;
 	input	 [ 31:0    ] aeMB0_dwb_dat_i;
 	output	 [ 31:0    ] aeMB0_dwb_dat_o;
 	input			aeMB0_dwb_err_i;
 	input			aeMB0_dwb_rty_i;
 	output	 [ 3:0    ] aeMB0_dwb_sel_o;
 	output			aeMB0_dwb_stb_o;
 	output	 [ 2:0    ] aeMB0_dwb_tag_o;
 	output			aeMB0_dwb_wre_o;
 	input			aeMB0_iwb_ack_i;
 	output	 [ 31:0    ] aeMB0_iwb_adr_o;
 	output			aeMB0_iwb_cyc_o;
 	input	 [ 31:0    ] aeMB0_iwb_dat_i;
 	output	 [ 31:0    ] aeMB0_iwb_dat_o;
 	input			aeMB0_iwb_err_i;
 	input			aeMB0_iwb_rty_i;
 	output	 [ 3:0    ] aeMB0_iwb_sel_o;
 	output			aeMB0_iwb_stb_o;
 	output	 [ 2:0    ] aeMB0_iwb_tag_o;
 	output			aeMB0_iwb_wre_o;
 	input			aeMB0_reset;
 	input			aeMB0_sys_ena_i;
 	input			aeMB0_sys_int_i;

 	input			aeMB2_clk;
 	input			aeMB2_dwb_ack_i;
 	output	 [ 31:0    ] aeMB2_dwb_adr_o;
 	output			aeMB2_dwb_cyc_o;
 	input	 [ 31:0    ] aeMB2_dwb_dat_i;
 	output	 [ 31:0    ] aeMB2_dwb_dat_o;
 	input			aeMB2_dwb_err_i;
 	input			aeMB2_dwb_rty_i;
 	output	 [ 3:0    ] aeMB2_dwb_sel_o;
 	output			aeMB2_dwb_stb_o;
 	output	 [ 2:0    ] aeMB2_dwb_tag_o;
 	output			aeMB2_dwb_wre_o;
 	input			aeMB2_iwb_ack_i;
 	output	 [ 31:0    ] aeMB2_iwb_adr_o;
 	output			aeMB2_iwb_cyc_o;
 	input	 [ 31:0    ] aeMB2_iwb_dat_i;
 	output	 [ 31:0    ] aeMB2_iwb_dat_o;
 	input			aeMB2_iwb_err_i;
 	input			aeMB2_iwb_rty_i;
 	output	 [ 3:0    ] aeMB2_iwb_sel_o;
 	output			aeMB2_iwb_stb_o;
 	output	 [ 2:0    ] aeMB2_iwb_tag_o;
 	output			aeMB2_iwb_wre_o;
 	input			aeMB2_reset;
 	input			aeMB2_sys_ena_i;
 	input			aeMB2_sys_int_i;

 	input			gpi0_clk;
 	input	 [ gpi0_PORT_WIDTH-1     :   0    ] gpi0_port_i;
 	input			gpi0_reset;
 	output			gpi0_sa_ack_o;
 	input	 [ gpi0_Aw-1       :   0    ] gpi0_sa_addr_i;
 	input			gpi0_sa_cyc_i;
 	input	 [ gpi0_Dw-1       :   0    ] gpi0_sa_dat_i;
 	output	 [ gpi0_Dw-1       :   0    ] gpi0_sa_dat_o;
 	output			gpi0_sa_err_o;
 	output			gpi0_sa_rty_o;
 	input	 [ gpi0_SELw-1     :   0    ] gpi0_sa_sel_i;
 	input			gpi0_sa_stb_i;
 	input	 [ gpi0_TAGw-1     :   0    ] gpi0_sa_tag_i;
 	input			gpi0_sa_we_i;

 aeMB_top #(
 		.AEMB_XWB(aeMB0_AEMB_XWB),
		.AEMB_IDX(aeMB0_AEMB_IDX),
		.AEMB_MUL(aeMB0_AEMB_MUL),
		.AEMB_IWB(aeMB0_AEMB_IWB),
		.AEMB_BSF(aeMB0_AEMB_BSF),
		.AEMB_ICH(aeMB0_AEMB_ICH),
		.AEMB_DWB(aeMB0_AEMB_DWB)
	)  aeMB0 	(
		.clk(aeMB0_clk),
		.dwb_ack_i(aeMB0_dwb_ack_i),
		.dwb_adr_o(aeMB0_dwb_adr_o),
		.dwb_cyc_o(aeMB0_dwb_cyc_o),
		.dwb_dat_i(aeMB0_dwb_dat_i),
		.dwb_dat_o(aeMB0_dwb_dat_o),
		.dwb_err_i(aeMB0_dwb_err_i),
		.dwb_rty_i(aeMB0_dwb_rty_i),
		.dwb_sel_o(aeMB0_dwb_sel_o),
		.dwb_stb_o(aeMB0_dwb_stb_o),
		.dwb_tag_o(aeMB0_dwb_tag_o),
		.dwb_wre_o(aeMB0_dwb_wre_o),
		.iwb_ack_i(aeMB0_iwb_ack_i),
		.iwb_adr_o(aeMB0_iwb_adr_o),
		.iwb_cyc_o(aeMB0_iwb_cyc_o),
		.iwb_dat_i(aeMB0_iwb_dat_i),
		.iwb_dat_o(aeMB0_iwb_dat_o),
		.iwb_err_i(aeMB0_iwb_err_i),
		.iwb_rty_i(aeMB0_iwb_rty_i),
		.iwb_sel_o(aeMB0_iwb_sel_o),
		.iwb_stb_o(aeMB0_iwb_stb_o),
		.iwb_tag_o(aeMB0_iwb_tag_o),
		.iwb_wre_o(aeMB0_iwb_wre_o),
		.reset(aeMB0_reset),
		.sys_ena_i(aeMB0_sys_ena_i),
		.sys_int_i(aeMB0_sys_int_i)
	);
 aeMB_top #(
 		.AEMB_XWB(aeMB2_AEMB_XWB),
		.AEMB_IDX(aeMB2_AEMB_IDX),
		.AEMB_MUL(aeMB2_AEMB_MUL),
		.AEMB_IWB(aeMB2_AEMB_IWB),
		.AEMB_BSF(aeMB2_AEMB_BSF),
		.AEMB_ICH(aeMB2_AEMB_ICH),
		.AEMB_DWB(aeMB2_AEMB_DWB)
	)  aeMB2 	(
		.clk(aeMB2_clk),
		.dwb_ack_i(aeMB2_dwb_ack_i),
		.dwb_adr_o(aeMB2_dwb_adr_o),
		.dwb_cyc_o(aeMB2_dwb_cyc_o),
		.dwb_dat_i(aeMB2_dwb_dat_i),
		.dwb_dat_o(aeMB2_dwb_dat_o),
		.dwb_err_i(aeMB2_dwb_err_i),
		.dwb_rty_i(aeMB2_dwb_rty_i),
		.dwb_sel_o(aeMB2_dwb_sel_o),
		.dwb_stb_o(aeMB2_dwb_stb_o),
		.dwb_tag_o(aeMB2_dwb_tag_o),
		.dwb_wre_o(aeMB2_dwb_wre_o),
		.iwb_ack_i(aeMB2_iwb_ack_i),
		.iwb_adr_o(aeMB2_iwb_adr_o),
		.iwb_cyc_o(aeMB2_iwb_cyc_o),
		.iwb_dat_i(aeMB2_iwb_dat_i),
		.iwb_dat_o(aeMB2_iwb_dat_o),
		.iwb_err_i(aeMB2_iwb_err_i),
		.iwb_rty_i(aeMB2_iwb_rty_i),
		.iwb_sel_o(aeMB2_iwb_sel_o),
		.iwb_stb_o(aeMB2_iwb_stb_o),
		.iwb_tag_o(aeMB2_iwb_tag_o),
		.iwb_wre_o(aeMB2_iwb_wre_o),
		.reset(aeMB2_reset),
		.sys_ena_i(aeMB2_sys_ena_i),
		.sys_int_i(aeMB2_sys_int_i)
	);
 gpi #(
 		.PORT_WIDTH(gpi0_PORT_WIDTH),
		.Dw(gpi0_Dw),
		.Aw(gpi0_Aw),
		.TAGw(gpi0_TAGw),
		.SELw(gpi0_SELw)
	)  gpi0 	(
		.clk(gpi0_clk),
		.port_i(gpi0_port_i),
		.reset(gpi0_reset),
		.sa_ack_o(gpi0_sa_ack_o),
		.sa_addr_i(gpi0_sa_addr_i),
		.sa_cyc_i(gpi0_sa_cyc_i),
		.sa_dat_i(gpi0_sa_dat_i),
		.sa_dat_o(gpi0_sa_dat_o),
		.sa_err_o(gpi0_sa_err_o),
		.sa_rty_o(gpi0_sa_rty_o),
		.sa_sel_i(gpi0_sa_sel_i),
		.sa_stb_i(gpi0_sa_stb_i),
		.sa_tag_i(gpi0_sa_tag_i),
		.sa_we_i(gpi0_sa_we_i)
	);
 

 

 

 
//Wishbone slave address match
 endmodule

