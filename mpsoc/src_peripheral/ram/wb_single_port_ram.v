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


`timescale 1ns / 1ps



module wb_single_port_ram #(
    parameter Dw=32, //RAM data_width in bits
    parameter Aw=10, //RAM address width
    parameter BYTE_WR_EN= "YES",//"YES","NO"
    parameter FPGA_VENDOR= "ALTERA",//"ALTERA","GENERIC"
    parameter JTAG_CONNECT= "JTAG_WB",//"DISABLED", "JTAG_WB" , "ALTERA_IMCE", if not disabled then the actual memory implements as a dual port RAM with the second port is connected either to In-System Memory Content Editor or Jtag_to_wb  
    parameter JTAG_INDEX= 0,
    parameter INITIAL_EN= "NO",
    parameter MEM_CONTENT_FILE_NAME= "ram0",// ram initial file name
    parameter INIT_FILE_PATH = "path_to/sw", // The sw folder path. It will be used for finding initial file. The path will be rewriten by the top module. 
    // wishbon bus param
    parameter   BURST_MODE= "DISABLED", // "DISABLED" , "ENABLED" wisbone bus burst mode 
    parameter   TAGw   =   3,
    parameter   SELw   =   Dw/8,
    parameter   CTIw   =   3,
    parameter   BTEw   =   2 


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
        sa_rty_o
        
    );


     

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
    
    wire [SELw-1 :   0]  byteena_a;
    wire [Dw-1   :   0]  d;
    wire [Aw-1   :   0]  addr;
    wire                 we;
    wire [Dw-1   :   0]  q;

`ifdef VERILATOR // verilatore does not recognize altsyncram
	localparam FPGA_VENDOR_MDFY= "GENERIC";
`else 
    `ifdef MODEL_TECH
        localparam FPGA_VENDOR_MDFY= "GENERIC";
    `else
	   localparam FPGA_VENDOR_MDFY= FPGA_VENDOR;
	`endif
`endif


	localparam MEM_NAME = (FPGA_VENDOR_MDFY== "ALTERA")? {MEM_CONTENT_FILE_NAME,".mif"} : 
							{MEM_CONTENT_FILE_NAME,".hex"}; //Generic


	localparam INIT_FILE =  {INIT_FILE_PATH,"/RAM/",MEM_NAME};
     

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
	.INIT_FILE(INIT_FILE) 
    )
    ram_top
    (
    	.reset(reset),
    	.clk(clk),
    	.data_a(d),
    	.addr_a(addr),
    	.we_a(we),
    	.q_a(q),
    	.byteena_a(byteena_a) 
    );
  

endmodule


















module single_port_ram_top #(
    parameter Dw=32, //RAM data_width in bits
    parameter Aw=10, //RAM address width
    parameter BYTE_WR_EN= "YES",//"YES","NO"
    parameter FPGA_VENDOR= "ALTERA",//"ALTERA","GENERIC"
    parameter JTAG_CONNECT= "JTAG_WB",//"DISABLED", "JTAG_WB" , "ALTERA_IMCE", if not disabled then the actual memory implements as a dual port RAM with the second port is connected either to In-System Memory Content Editor or Jtag_to_wb  
    parameter JTAG_INDEX= 0,
    parameter INITIAL_EN= "NO",
    parameter INIT_FILE= "sw/ram/ram0.txt"// ram initial file 

    )
    (
        reset,
        clk,
        data_a,
        addr_a,
        byteena_a,
        we_a, 
        q_a
);
  localparam  BYTE_ENw= ( BYTE_WR_EN == "YES")? Dw/8 : 1;
  
input                           clk,reset;
input  [Dw-1   :   0]  data_a;
input  [Aw-1   :   0]  addr_a;
input                     we_a;
input  [BYTE_ENw-1   :   0] byteena_a;
output [Dw-1    :   0]  q_a;



    function   [15:0]i2s;   
        input   integer c;  integer i;  integer tmp; begin 
        tmp =0; 
        for (i=0; i<2; i=i+1'b1) begin 
            tmp = tmp + (((c % 10)   + 6'd48) << i*8); 
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
if(FPGA_VENDOR=="ALTERA")begin:altera_fpga
 localparam  RAM_TAG_STRING=i2s(JTAG_INDEX);  
localparam  RAM_ID =(JTAG_CONNECT== "ALTERA_IMCE") ?  {"ENABLE_RUNTIME_MOD=YES,INSTANCE_NAME=",RAM_TAG_STRING}
                                    : {"ENABLE_RUNTIME_MOD=NO"};

    if(JTAG_CONNECT== "JTAG_WB")begin:dual_ram
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
            .init_file(INIT_FILE)
    
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
	    .init_file(INIT_FILE)   
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
            .addressstall_a     (    ),
            .addressstall_b     (    ),
            .q_b            (    ),
            .eccstatus      (    )
        );

    end
end

else if(FPGA_VENDOR=="GENERIC")begin:generic_ram
    if(JTAG_CONNECT== "JTAG_WB")begin:dual_ram
        

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
            .byteen   (byteena_a ),
            .we       (we_a),
            .clk      (clk),
            .q        (q_a)
            
        );

    end//jtag_wb
end //Generic


if(JTAG_CONNECT == "JTAG_WB")begin:jtag_wb

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
end//jtag_wb

endgenerate



endmodule









