module ALI #(
    	parameter	Altera_ram0_Aw=13 ,
	parameter	Altera_ram0_RAM_TAG_STRING="00" ,
	parameter	aeMB0_AEMB_MUL= 1 ,
	parameter	aeMB0_AEMB_BSF= 1
)(
	Altera_ram0_clk, 
	Altera_ram0_reset, 
	Altera_ram0_sa_ack_o, 
	Altera_ram0_sa_addr_i, 
	Altera_ram0_sa_cyc_i, 
	Altera_ram0_sa_dat_i, 
	Altera_ram0_sa_dat_o, 
	Altera_ram0_sa_err_o, 
	Altera_ram0_sa_rty_o, 
	Altera_ram0_sa_sel_i, 
	Altera_ram0_sa_stb_i, 
	Altera_ram0_sa_tag_i, 
	Altera_ram0_sa_we_i, 
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
	aeMB0_sys_int_i
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

 
//Wishbone slave base address based on instance name
 
 
//Wishbone slave base address based on module name. 
 
 	input			Altera_ram0_clk;
 	input			Altera_ram0_reset;
 	output			Altera_ram0_sa_ack_o;
 	input	 [ Altera_ram0_Aw-1       :   0    ] Altera_ram0_sa_addr_i;
 	input			Altera_ram0_sa_cyc_i;
 	input	 [ Altera_ram0_Dw-1       :   0    ] Altera_ram0_sa_dat_i;
 	output	 [ Altera_ram0_Dw-1       :   0    ] Altera_ram0_sa_dat_o;
 	output			Altera_ram0_sa_err_o;
 	output			Altera_ram0_sa_rty_o;
 	input	 [ Altera_ram0_SELw-1     :   0    ] Altera_ram0_sa_sel_i;
 	input			Altera_ram0_sa_stb_i;
 	input	 [ Altera_ram0_TAGw-1     :   0    ] Altera_ram0_sa_tag_i;
 	input			Altera_ram0_sa_we_i;

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

 prog_ram_single_port #(
 		.Aw(Altera_ram0_Aw),
		.FPGA_FAMILY(Altera_ram0_FPGA_FAMILY),
		.RAM_TAG_STRING(Altera_ram0_RAM_TAG_STRING),
		.TAGw(Altera_ram0_TAGw),
		.Dw(Altera_ram0_Dw),
		.SELw(Altera_ram0_SELw)
	)  Altera_ram0 	(
		.clk(Altera_ram0_clk),
		.reset(Altera_ram0_reset),
		.sa_ack_o(Altera_ram0_sa_ack_o),
		.sa_addr_i(Altera_ram0_sa_addr_i),
		.sa_cyc_i(Altera_ram0_sa_cyc_i),
		.sa_dat_i(Altera_ram0_sa_dat_i),
		.sa_dat_o(Altera_ram0_sa_dat_o),
		.sa_err_o(Altera_ram0_sa_err_o),
		.sa_rty_o(Altera_ram0_sa_rty_o),
		.sa_sel_i(Altera_ram0_sa_sel_i),
		.sa_stb_i(Altera_ram0_sa_stb_i),
		.sa_tag_i(Altera_ram0_sa_tag_i),
		.sa_we_i(Altera_ram0_sa_we_i)
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
 

 

 
//Wishbone slave address match
 endmodule

