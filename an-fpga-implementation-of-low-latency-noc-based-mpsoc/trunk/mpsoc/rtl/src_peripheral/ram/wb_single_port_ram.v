/**********************************************************************
**	File:  wb_dual_port_ram.v
**	   
**    
**	Copyright (C) 2014-2017  Alireza Monemi
**    
**	This file is part of ProNoC 
**
**	ProNoC ( stands for Prototype Network-on-chip)  is free software: 
**	you can redistribute it and/or modify it under the terms of the GNU
**	Lesser General Public License as published by the Free Software Foundation,
**	either version 2 of the License, or (at your option) any later version.
**
** 	ProNoC is distributed in the hope that it will be useful, but WITHOUT
** 	ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
** 	or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General
** 	Public License for more details.
**
** 	You should have received a copy of the GNU Lesser General Public
** 	License along with ProNoC. If not, see <http:**www.gnu.org/licenses/>.
**
**
**	Description: 
**	wishbone based single port ram 
**	
**
*******************************************************************/ 


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on




module wb_single_port_ram #(
    parameter Dw=32, //RAM data_width in bits
    parameter Aw=10, //RAM address width
    parameter BYTE_WR_EN= "YES",//"YES","NO"
    parameter FPGA_VENDOR= "ALTERA",//"XILINX",ALTERA","GENERIC"
    parameter JTAG_CONNECT= "ALTERA_JTAG_WB",//"DISABLED","XILINX_JTAG_WB", "ALTERA_JTAG_WB" , "ALTERA_IMCE", if not disabled then the actual memory implements as a dual port RAM with the second port is connected either to In-System Memory Content Editor or Jtag_to_wb  
    parameter JTAG_INDEX= 0,
    parameter INITIAL_EN= "NO",
    parameter MEM_CONTENT_FILE_NAME= "ram0",// ram initial file name
    parameter INIT_FILE_PATH = "path_to/sw", // The sw folder path. It will be used for finding initial file. The path will be rewriten by the top module. 
    parameter CORE_NUM=0,
    // wishbon bus param
    parameter BURST_MODE= "DISABLED", // "DISABLED" , "ENABLED" wisbone bus burst mode 
    parameter TAGw   =   3,
    parameter SELw   =   Dw/8,
    parameter CTIw   =   3,
    parameter BTEw   =   2,    
    //jtag to wishbobe interface
    parameter JDw =Dw,// should be a fixed value for all IPs coneccting to JTAG
    parameter JAw=32, // should be a fixed value for all IPs coneccting to JTAG
    parameter JINDEXw=8,
    parameter JSTATUSw=8,
/* verilator lint_off WIDTH */
    parameter J2WBw = (JTAG_CONNECT== "XILINX_JTAG_WB") ? 1+1+JDw+JAw : 1,
    parameter WB2Jw= (JTAG_CONNECT== "XILINX_JTAG_WB") ? 1+JSTATUSw+JINDEXw+1+JDw  : 1,
/* verilator lint_on WIDTH */
	parameter WB_Aw= 20 // Wishbon bus reserved address with range. WB_Aw >=Aw
    )
    (
        clk,
        reset,
    
        //wishbone bus interface
        sa_dat_i,
        sa_sel_i,
        sa_addr_i,  
        sa_tag_i,
        sa_cti_i,
        sa_bte_i,
        sa_stb_i,
        sa_cyc_i,
        sa_we_i,    
        sa_dat_o,
        sa_ack_o,
        sa_err_o,
        sa_rty_o,
        
        //jtag o wb interface. Valid only for XILINX_JTAG_WB 
        jtag_to_wb, 
        wb_to_jtag 
        
    );

// synthesis translate_off 
     initial begin 
		if(WB_Aw<Aw)begin
			$display("Error: The wishbon bus reserved address range width (%d) should be larger than ram width (%d): %m",WB_Aw,Aw);  
			$stop;
		end
	 end
// synthesis translate_on

    input                  clk;
    input                  reset;
    
     
   
    
     //wishbone bus interface
    input       [Dw-1       :   0]      sa_dat_i;
    input       [SELw-1     :   0]      sa_sel_i;
    input       [Aw-1       :   0]      sa_addr_i;  
    input       [TAGw-1     :   0]      sa_tag_i;
    input                               sa_stb_i;
    input                               sa_cyc_i;
    input                               sa_we_i;
    input       [CTIw-1     :   0]      sa_cti_i;
    input       [BTEw-1     :   0]      sa_bte_i;
    
    output      [Dw-1       :   0]      sa_dat_o;
    output                              sa_ack_o;
    output                              sa_err_o;
    output                              sa_rty_o;
    
    input  [J2WBw-1 : 0] jtag_to_wb;
    output [WB2Jw-1: 0] wb_to_jtag;
    
    wire [SELw-1 :   0]  byteena_a;
    wire [Dw-1   :   0]  d;
    wire [Aw-1   :   0]  addr;
    wire                 we;
    wire [Dw-1   :   0]  q;

`ifdef VERILATOR 
	// The verilator does not recognize altsyncram, use Generic Ram instead
	localparam FPGA_VENDOR_MDFY= "GENERIC";
`else 
    `ifdef MODEL_TECH
        localparam FPGA_VENDOR_MDFY= "GENERIC";
    `else
	   localparam FPGA_VENDOR_MDFY= FPGA_VENDOR;
	`endif
`endif

/* verilator lint_off WIDTH */
	localparam MEM_NAME =
       (FPGA_VENDOR_MDFY== "ALTERA")? {MEM_CONTENT_FILE_NAME,".mif"} : 
       (FPGA_VENDOR_MDFY== "XILINX")? {MEM_CONTENT_FILE_NAME,".mem"} : 
                            {MEM_CONTENT_FILE_NAME,".hex"}; //Generic

    
    localparam [7:0] N1 = (CORE_NUM%10) + 48;
    localparam [7:0] N2 = ((CORE_NUM/10)%10) + 48;
    localparam [7:0] N3 = ((CORE_NUM/100)%10) + 48;
    
    localparam NN = (CORE_NUM<10) ? N1 : (CORE_NUM<100)? {N2,N1} : {N3,N2,N1}; 
	

    localparam  INIT_FILE = 
       (FPGA_VENDOR_MDFY== "XILINX")? {"tile",NN,MEM_NAME}:
       {INIT_FILE_PATH,"/RAM/",MEM_NAME};

/* verilator lint_on WIDTH */ 

    wb_bram_ctrl #(
       	.Dw(Dw),
       	.Aw(Aw),
       	.BURST_MODE(BURST_MODE),
       	.SELw(SELw),
       	.CTIw(CTIw),
       	.BTEw(BTEw)
    )
   ctrl
   (
       	.clk(clk),
       	.reset(reset),
       	.d(d),
       	.addr(addr),
       	.we(we),
       	.q(q),
        .byteena_a(byteena_a),
       	.sa_dat_i(sa_dat_i),
       	.sa_sel_i(sa_sel_i),
       	.sa_addr_i(sa_addr_i),
       	.sa_stb_i(sa_stb_i),
       	.sa_cyc_i(sa_cyc_i),
       	.sa_we_i(sa_we_i),
       	.sa_cti_i(sa_cti_i),
       	.sa_bte_i(sa_bte_i),
       	.sa_dat_o(sa_dat_o),
       	.sa_ack_o(sa_ack_o),
       	.sa_err_o(sa_err_o),
       	.sa_rty_o(sa_rty_o)
   );



  

    single_port_ram_top #(
    	.Dw(Dw),
    	.Aw(Aw),
    	.BYTE_WR_EN(BYTE_WR_EN),
    	.FPGA_VENDOR(FPGA_VENDOR_MDFY),
    	.JTAG_CONNECT(JTAG_CONNECT),
    	.JTAG_INDEX(JTAG_INDEX),
        .INITIAL_EN(INITIAL_EN),
        .INIT_FILE(INIT_FILE),
        .JDw(JDw),
        .JAw(JAw),
        .JINDEXw(JINDEXw),
        .JSTATUSw(JSTATUSw),
        .J2WBw(J2WBw), 
        .WB2Jw(WB2Jw)
    )
    ram_top
    (
    	.reset(reset),
    	.clk(clk),
    	.data_a(d),
    	.addr_a(addr),
    	.we_a(we),
    	.q_a(q),
    	.byteena_a(byteena_a),
    	.jtag_to_wb(jtag_to_wb),
        .wb_to_jtag(wb_to_jtag)        
    );
  

endmodule







module single_port_ram_top #(
    parameter Dw=32, //RAM data_width in bits
    parameter Aw=10, //RAM address width
    parameter BYTE_WR_EN= "YES",//"YES","NO"
    parameter FPGA_VENDOR= "ALTERA",//"ALTERA","GENERIC"
    parameter JTAG_CONNECT= "ALTERA_JTAG_WB",//"DISABLED", "XILINX_JTAG_WB","ALTERA_JTAG_WB" , "ALTERA_IMCE", if not disabled then the actual memory implements as a dual port RAM with the second port is connected either to In-System Memory Content Editor or Jtag_to_wb  
    parameter JTAG_INDEX= 0,
    parameter INITIAL_EN= "NO",
    parameter INIT_FILE= "sw/ram/ram0.txt",// ram initial file 
     //jtag to wishbobe interface
    parameter JDw =Dw,// should be a fixed value for all IPs coneccting to JTAG
    parameter JAw=32, // should be a fixed value for all IPs coneccting to JTAG
    parameter JSTATUSw=8,
    parameter JINDEXw =8,
    parameter J2WBw = (JTAG_CONNECT== "XILINX_JTAG_WB") ? 1+1+JDw+JAw : 1,
    parameter WB2Jw = (JTAG_CONNECT== "XILINX_JTAG_WB") ? 1+JSTATUSw+JINDEXw+1+JDw : 1
    )
    (
        reset,
        clk,
        data_a,
        addr_a,
        byteena_a,
        we_a, 
        q_a,
        //jtag o wb interface. Valid only for XILINX_JTAG_WB 
        jtag_to_wb,
        wb_to_jtag
);
    /* verilator lint_off WIDTH */
    localparam  BYTE_ENw= ( BYTE_WR_EN == "YES")? Dw/8 : 1;
    localparam  XILINX_INIT_FILE = (INITIAL_EN == "NO") ? "none" : INIT_FILE;
    localparam  ALTERA_INIT_FILE = (INITIAL_EN == "NO") ? "UNUSED" : INIT_FILE;    
    /* verilator lint_on WIDTH */
  
    input                           clk,reset;
    input  [Dw-1   :   0]  data_a;
    input  [Aw-1   :   0]  addr_a;
    input                     we_a;
    input  [BYTE_ENw-1   :   0] byteena_a;
    output [Dw-1    :   0]  q_a;
    
    input  [J2WBw-1 : 0] jtag_to_wb;
    output [WB2Jw-1 : 0] wb_to_jtag;
    
    function   [15:0]i2s;   
        input   integer c;  integer i;  integer tmp; begin 
        tmp =0; 
        for (i=0; i<2; i=i+1) begin 
            tmp = tmp + (((c % 10)   + 48) << i*8); 
            c = c/10; 
        end 
        i2s = tmp[15:0];
        end     
    endfunction //i2s

    function integer log2;
        input integer number; begin   
        log2=0;    
        while(2**log2<number) begin    
             log2=log2+1;    
        end    
        end   
    endfunction // log2 
   
    wire            [Dw-1   :   0]   data_b;
    wire            [Aw-1   :   0]   addr_b;
    wire                             we_b;
    wire            [Dw-1   :   0]  q_b;
        


    
generate 
/***********************
 *  "ALTERA"
 * *********************/
 /* verilator lint_off WIDTH */
if(FPGA_VENDOR=="ALTERA")begin:altera_fpga
    localparam  RAM_TAG_STRING=i2s(JTAG_INDEX);  
    localparam  RAM_ID =(JTAG_CONNECT== "ALTERA_IMCE") ?  {"ENABLE_RUNTIME_MOD=YES,INSTANCE_NAME=",RAM_TAG_STRING}
                                        : {"ENABLE_RUNTIME_MOD=NO"};

    if(JTAG_CONNECT== "ALTERA_JTAG_WB")begin:dual_ram
/* verilator lint_on WIDTH */
 
// aletra dual port ram 
        altsyncram #(
            .operation_mode("BIDIR_DUAL_PORT"),
            .address_reg_b("CLOCK0"),
            .wrcontrol_wraddress_reg_b("CLOCK0"),
            .indata_reg_b("CLOCK0"),
            .outdata_reg_a("UNREGISTERED"),
            .outdata_reg_b("UNREGISTERED"),
            .width_a(Dw),
            .width_b(Dw),
            .lpm_hint(RAM_ID),
            .read_during_write_mode_mixed_ports("DONT_CARE"),
            .widthad_a(Aw),
            .widthad_b(Aw),
            .width_byteena_a(BYTE_ENw),
            .init_file(ALTERA_INIT_FILE)
    
        ) ram_inst(
            .clock0         (clk),
        
            .address_a      (addr_a),
            .wren_a         (we_a),
            .data_a         (data_a),
            .q_a            (q_a),
            .byteena_a      (byteena_a),      
        
        
            .address_b      (addr_b),
            .wren_b         (we_b),
            .data_b         (data_b),
            .q_b            (q_b),
            .byteena_b      (1'b1), 
        

            .rden_a         (1'b1),
            .rden_b         (1'b1),
            .clock1         (1'b1),
            .clocken0       (1'b1),
            .clocken1       (1'b1),
            .clocken2       (1'b1),
            .clocken3       (1'b1),
            .aclr0          (1'b0),
            .aclr1          (1'b0),     
            .addressstall_a     (1'b0),
            .addressstall_b     (1'b0),
            .eccstatus      (    )

        );

    // jtag_wb
    end else begin:  single_ram //JTAG_CONNECT= "DISABLED", "ALTERA_IMCE"
    
    

        altsyncram #(
            .operation_mode("SINGLE_PORT"),
            .width_a(Dw),
            .lpm_hint(RAM_ID),
            .read_during_write_mode_mixed_ports("DONT_CARE"),
            .widthad_a(Aw),
            .width_byteena_a(BYTE_ENw),
            .init_file(ALTERA_INIT_FILE)   
        )
        ram_inst
        (
            .clock0         (clk),
            .address_a      (addr_a),
            .wren_a         (we_a),
            .data_a         (data_a),
            .q_a            (q_a),
            .byteena_a      (byteena_a),
             
            .wren_b         (    ),
            .rden_a         (    ),
            .rden_b         (    ),
            .data_b         (    ),
            .address_b      (    ),
            .clock1         (    ),
            .clocken0       (    ),
            .clocken1       (    ),
            .clocken2       (    ),
            .clocken3       (    ),
            .aclr0          (    ),
            .aclr1          (    ),     
            .byteena_b      (    ),
            .addressstall_a (    ),
            .addressstall_b (    ),
            .q_b            (    ),
            .eccstatus      (    )
        );

    end// single_ram
end//altera_fpga 
/***********************
 *  "XILINX"
 * *********************/

/* verilator lint_off WIDTH */
else if (FPGA_VENDOR=="XILINX")begin:xilinx_fpga
/* verilator lint_on WIDTH */
 
    localparam MEMORY_SIZE = (2**Aw)*Dw;//total memory array size, in bits
    wire  [BYTE_ENw-1   :   0] xilinx_we_a = (we_a)? byteena_a : {BYTE_ENw{1'b0}};

    /* verilator lint_off WIDTH */ 
    if(JTAG_CONNECT == "XILINX_JTAG_WB")begin: xilinx_dual
    /* verilator lint_on WIDTH */
     
        wire [BYTE_ENw-1   :   0] xilinx_we_b = (we_b)? {BYTE_ENw{1'b1}} : {BYTE_ENw{1'b0}};
    // xpm_memory_tdpram: True Dual Port RAM
   // Xilinx Parameterized Macro, version 2019.1
   
   xpm_memory_tdpram #(
      .ADDR_WIDTH_A(Aw),               // DECIMAL
      .ADDR_WIDTH_B(Aw),               // DECIMAL
      .AUTO_SLEEP_TIME(0),            // DECIMAL
      .BYTE_WRITE_WIDTH_A(8),        // DECIMAL
      .BYTE_WRITE_WIDTH_B(8),        // DECIMAL
     // .CASCADE_HEIGHT(0),             // DECIMAL
      .CLOCKING_MODE("common_clock"), // String
      .ECC_MODE("no_ecc"),            // String
      .MEMORY_INIT_FILE(XILINX_INIT_FILE),      // String
      .MEMORY_INIT_PARAM(""),        // String
      .MEMORY_OPTIMIZATION("true"),   // String
      .MEMORY_PRIMITIVE("auto"),      // String
      .MEMORY_SIZE(MEMORY_SIZE),             // DECIMAL
      .MESSAGE_CONTROL(0),            // DECIMAL
      .READ_DATA_WIDTH_A(Dw),         // DECIMAL
      .READ_DATA_WIDTH_B(Dw),         // DECIMAL
      .READ_LATENCY_A(1),             // DECIMAL
      .READ_LATENCY_B(1),             // DECIMAL
      .READ_RESET_VALUE_A("0"),       // String
      .READ_RESET_VALUE_B("0"),       // String
      //.RST_MODE_A("SYNC"),            // String
      //.RST_MODE_B("SYNC"),            // String
     // .SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
      .USE_MEM_INIT(1),               // DECIMAL
      .WAKEUP_TIME("disable_sleep"),  // String
      .WRITE_DATA_WIDTH_A(Dw),        // DECIMAL
      .WRITE_DATA_WIDTH_B(Dw),        // DECIMAL
      .WRITE_MODE_A("no_change"),     // String
      .WRITE_MODE_B("no_change")      // String
   )
   xpm_memory_tdpram_inst 
   (
      .dbiterra( ),             // 1-bit output: Status signal to indicate double bit error occurrence
                                       // on the data output of port A.

      .dbiterrb( ),             // 1-bit output: Status signal to indicate double bit error occurrence
                                       // on the data output of port A.

      .douta(q_a),                   // READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
      .doutb(q_b),                   // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
      .sbiterra( ),             // 1-bit output: Status signal to indicate single bit error occurrence
                                       // on the data output of port A.

      .sbiterrb( ),             // 1-bit output: Status signal to indicate single bit error occurrence
                                       // on the data output of port B.

      .addra(addr_a),                   // ADDR_WIDTH_A-bit input: Address for port A write and read operations.
      .addrb(addr_b),                   // ADDR_WIDTH_B-bit input: Address for port B write and read operations.
      .clka(clk),                     // 1-bit input: Clock signal for port A. Also clocks port B when
                                       // parameter CLOCKING_MODE is "common_clock".

      .clkb(clk),                     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                       // "independent_clock". Unused when parameter CLOCKING_MODE is
                                       // "common_clock".

      .dina(data_a),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
      .dinb(data_b),                     // WRITE_DATA_WIDTH_B-bit input: Data input for port B write operations.
      .ena(1'b1),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
                                       // cycles when read or write operations are initiated. Pipelined
                                       // internally.

      .enb(1'b1),                       // 1-bit input: Memory enable signal for port B. Must be high on clock
                                       // cycles when read or write operations are initiated. Pipelined
                                       // internally.

      .injectdbiterra(1'b0), // 1-bit input: Controls double bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectdbiterrb(1'b0), // 1-bit input: Controls double bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectsbiterra(1'b0), // 1-bit input: Controls single bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectsbiterrb(1'b0), // 1-bit input: Controls single bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .regcea(1'b1),                 // 1-bit input: Clock Enable for the last register stage on the output
                                       // data path.

      .regceb(1'b1),                 // 1-bit input: Clock Enable for the last register stage on the output
                                       // data path.

      .rsta(1'b0),                     // 1-bit input: Reset signal for the final port A output register stage.
                                       // Synchronously resets output port douta to the value specified by
                                       // parameter READ_RESET_VALUE_A.

      .rstb(1'b0),                     // 1-bit input: Reset signal for the final port B output register stage.
                                       // Synchronously resets output port doutb to the value specified by
                                       // parameter READ_RESET_VALUE_B.

      .sleep(1'b0),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
      .wea(xilinx_we_a),                       // WRITE_DATA_WIDTH_A-bit input: Write enable vector for port A input
                                       // data port dina. 1 bit wide when word-wide writes are used. In
                                       // byte-wide write configurations, each bit controls the writing one
                                       // byte of dina to address addra. For example, to synchronously write
                                       // only bits [15-8] of dina when WRITE_DATA_WIDTH_A is 32, wea would be
                                       // 4'b0010.

      .web(xilinx_we_b)                        // WRITE_DATA_WIDTH_B-bit input: Write enable vector for port B input
                                       // data port dinb. 1 bit wide when word-wide writes are used. In
                                       // byte-wide write configurations, each bit controls the writing one
                                       // byte of dinb to address addrb. For example, to synchronously write
                                       // only bits [15-8] of dinb when WRITE_DATA_WIDTH_B is 32, web would be
                                       // 4'b0010.

   );

    
    
    end //   xilinx_dual
    else begin : xilinx_single
    
     
       
        xpm_memory_spram #(
          .ADDR_WIDTH_A(Aw),             // DECIMAL
          .AUTO_SLEEP_TIME(0),           // DECIMAL
          .BYTE_WRITE_WIDTH_A(8),        // DECIMAL
        //  .CASCADE_HEIGHT(0),            // DECIMAL
          .ECC_MODE("no_ecc"),           // String
          .MEMORY_INIT_FILE(XILINX_INIT_FILE),  // String
          .MEMORY_INIT_PARAM(""),       // String
          .MEMORY_OPTIMIZATION("true"),  // String
          .MEMORY_PRIMITIVE("auto"),     // String
          .MEMORY_SIZE(MEMORY_SIZE),     // DECIMAL
          .MESSAGE_CONTROL(0),           // DECIMAL
          .READ_DATA_WIDTH_A(Dw),        // DECIMAL
          .READ_LATENCY_A(1),            // DECIMAL
          .READ_RESET_VALUE_A("0"),      // String
         // .RST_MODE_A("SYNC"),           // String
         // .SIM_ASSERT_CHK(0),            // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
          .USE_MEM_INIT(1),              // DECIMAL
          .WAKEUP_TIME("disable_sleep"), // String
          .WRITE_DATA_WIDTH_A(Dw),       // DECIMAL
          .WRITE_MODE_A("read_first")    // String
    )
    xpm_memory_spram_inst 
    (
      .dbiterra( ),             // 1-bit output: Status signal to indicate double bit error occurrence
                                       // on the data output of port A.

      .douta(q_a),                   // READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
      .sbiterra( ),             // 1-bit output: Status signal to indicate single bit error occurrence
                                       // on the data output of port A.

      .addra(addr_a),                   // ADDR_WIDTH_A-bit input: Address for port A write and read operations.
      .clka(clk),                     // 1-bit input: Clock signal for port A.
      .dina(data_a),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
      .ena(1'b1),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
                                       // cycles when read or write operations are initiated. Pipelined
                                       // internally.

      .injectdbiterra(1'b0 ), // 1-bit input: Controls double bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectsbiterra(1'b0), // 1-bit input: Controls single bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .regcea(1'b1),                 // 1-bit input: Clock Enable for the last register stage on the output
                                       // data path.

      .rsta(1'b0),                     // 1-bit input: Reset signal for the final port A output register stage.
                                       // Synchronously resets output port douta to the value specified by
                                       // parameter READ_RESET_VALUE_A.

      .sleep(1'b0),                    // 1-bit input: sleep signal to enable the dynamic power saving feature.
      .wea(xilinx_we_a)                // WRITE_DATA_WIDTH_A-bit input: Write enable vector for port A input
                                       // data port dina. 1 bit wide when word-wide writes are used. In
                                       // byte-wide write configurations, each bit controls the writing one
                                       // byte of dina to address addra. For example, to synchronously write
                                       // only bits [15-8] of dina when WRITE_DATA_WIDTH_A is 32, wea would be
                                       // 4'b0010.

   );

    
    
    end// xilinx_simgle
end//xilinx_fpga


/***********************
 *  "GENERIC"
 * *********************/
/* verilator lint_off WIDTH */
else if(FPGA_VENDOR=="GENERIC")begin:generic_ram
    if(JTAG_CONNECT== "ALTERA_JTAG_WB" || JTAG_CONNECT=="XILINX_JTAG_WB" )begin:dual_ram
/* verilator lint_on WIDTH */        

        generic_dual_port_ram #(
            .Dw(Dw),
            .Aw(Aw),
            .BYTE_WR_EN(BYTE_WR_EN),
            .INITIAL_EN(INITIAL_EN),
            .INIT_FILE(INIT_FILE) 
        )
        ram_inst
        (
            .data_a     (data_a), 
            .data_b     (data_b),
            .addr_a     (addr_a),
            .addr_b     (addr_b),
            .byteena_a  (byteena_a ),
            .byteena_b  ({BYTE_ENw{1'b1}}),
            .we_a       (we_a),
            .we_b       (we_b),
            .clk        (clk),
            .q_a        (q_a),
            .q_b        (q_b)
            
        );


    end else begin

        

        generic_single_port_ram #(
            .Dw(Dw),
            .Aw(Aw),
            .BYTE_WR_EN(BYTE_WR_EN),
            .INITIAL_EN(INITIAL_EN),
            .INIT_FILE(INIT_FILE) 
        )
        ram_inst
        (
            .data     (data_a), 
            .addr     (addr_a),
            .byteen   (byteena_a),
            .we       (we_a),
            .clk      (clk),
            .q        (q_a)
            
        );

    end//jtag_wb
end //Generic

/* verilator lint_off WIDTH */
if(JTAG_CONNECT == "ALTERA_JTAG_WB")begin:altera_jwb
/* verilator lint_on WIDTH */
    reg jtag_ack;
    wire    jtag_we_o, jtag_stb_o;

    localparam Sw= log2(Aw+1);
    localparam [Sw-1    :   0] ST = Aw;
    vjtag_wb #(
        .VJTAG_INDEX(JTAG_INDEX),
        .DW(Dw),
        .AW(Aw),
        .SW(Sw),
    
        //wishbone port parameters
            .M_Aw(Aw),
            .TAGw(3)
    )
    vjtag_inst
    (
        .clk(clk),
        .reset(reset),  
        .status_i(ST), // Jtag can read memory size as status
         //wishbone master interface signals
        .m_sel_o(),
        .m_dat_o(data_b),
        .m_addr_o(addr_b),
        .m_cti_o(),
        .m_stb_o(jtag_stb_o),
        .m_cyc_o(),
        .m_we_o(jtag_we_o),
        .m_dat_i(q_b),
        .m_ack_i(jtag_ack)     
    
    );

    assign we_b = jtag_stb_o & jtag_we_o;

    always @(posedge clk )begin 
        jtag_ack<=jtag_stb_o;   
    end
    assign wb_to_jtag = clk;
    
end//altera_jwb

/* verilator lint_off WIDTH */
else if(JTAG_CONNECT == "XILINX_JTAG_WB")begin: xilinx_jwb 
/* verilator lint_on WIDTH */     
    
    localparam [JSTATUSw-1    :   0] ST1 = Aw;
    
    wire [JSTATUSw-1 : 0] wb_to_jtag_status;
    wire [JINDEXw-1 : 0] wb_to_jtag_index;
    wire [JDw-1 : 0] jtag_to_wb_dat;
    wire [JAw-1 : 0] jtag_to_wb_addr;
    wire jtag_to_wb_stb;
    wire jtag_to_wb_we;
    wire [JDw-1 : 0] wb_to_jtag_dat; 
    wire wb_to_jtag_ack;
    
    assign wb_to_jtag = {wb_to_jtag_status,wb_to_jtag_ack,wb_to_jtag_dat,wb_to_jtag_index,clk};
    assign {jtag_to_wb_addr,jtag_to_wb_stb,jtag_to_wb_we,jtag_to_wb_dat} = jtag_to_wb;
    
        
    reg ack_reg;
    assign wb_to_jtag_status = ST1;
    assign wb_to_jtag_index = JTAG_INDEX;
    assign data_b = jtag_to_wb_dat;
    assign addr_b = jtag_to_wb_addr[Aw-1:0];
    assign we_b = jtag_to_wb_stb & jtag_to_wb_we;
    assign wb_to_jtag_dat = q_b; 
    assign wb_to_jtag_ack = ack_reg;
    always @(posedge clk )begin 
        ack_reg<=jtag_to_wb_stb;   
    end
end else begin 
     assign wb_to_jtag = clk;
end

endgenerate



endmodule









