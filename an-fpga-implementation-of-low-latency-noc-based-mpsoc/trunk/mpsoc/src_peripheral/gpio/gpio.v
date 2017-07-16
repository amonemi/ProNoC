/**********************************************************************
**	File:  gpio.v 
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
**	a simple wishbone compatible output/input port 
**	each port has three registers. 
**	
**	  addr
**		0	DIR_REG							
**		1	WRITE_REG	port 0 					
**		2	READ_REG		
**		
**		32	DIR_REG		
**		33	WRITE_REG	port 1
**		34	READ_REG	
**		.
**		.
**		.
**
*******************************************************************/




// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on





module gpio #(
	parameter Aw           =   2,
	parameter SELw         =   4,
	parameter TAGw         =   3,
	parameter PORT_WIDTH   =   1,
	parameter Dw           =    PORT_WIDTH
	
	
)
(
    clk,
    reset,
    
  //wishbone bus interface
    sa_dat_i,
    sa_sel_i,
    sa_addr_i,  
    sa_tag_i,
    sa_stb_i,
    sa_cyc_i,
    sa_we_i,    
    sa_dat_o,
    sa_ack_o,
    sa_err_o,
    sa_rty_o,
    
    port_io
	
	
);

		
	//registers num
	localparam DIR_REG         =0;
	localparam WRITE_REG       =1;
	localparam READ_REG        =2;
	
	
	
    input                               clk;
    input                               reset;
    
    //wishbone bus interface
    input       [Dw-1       :   0]      sa_dat_i;
    input       [SELw-1     :   0]      sa_sel_i;
    input       [Aw-1       :   0]      sa_addr_i;  
    input       [TAGw-1     :   0]      sa_tag_i;
    input                               sa_stb_i;
    input                               sa_cyc_i;
    input                               sa_we_i;
    
    output      [Dw-1       :   0]      sa_dat_o;
    output  reg                         sa_ack_o;
    output                              sa_err_o;
    output                              sa_rty_o;
    
    inout   [PORT_WIDTH-1     :   0]    port_io;
    
   
   assign  sa_err_o=1'b0;
   assign  sa_rty_o=1'b0;
	
	

	genvar i;
	
	reg	  [PORT_WIDTH-1			:	0] 	io_dir;
	reg	  [PORT_WIDTH-1			:	0]	io_write;
	reg   [PORT_WIDTH-1         :   0] read_reg;
	
	
	always @ (posedge clk or posedge reset) begin
	   if(reset) begin 
         io_dir		<= {PORT_WIDTH{1'b0}};
		 io_write	<= {PORT_WIDTH{1'b0}};
		end else begin 
            if(sa_stb_i && sa_we_i ) begin 
		      if( sa_addr_i 	== DIR_REG[Aw-1       :   0]    ) io_dir	 <=  sa_dat_i[PORT_WIDTH-1		 :	0];
              if( sa_addr_i 	== WRITE_REG[Aw-1     :   0]    ) io_write	 <=  sa_dat_i[PORT_WIDTH-1      :   0];
            end //sa_stb_i && sa_we_i
        end //reset
	end//always
	
	

    
    always @(posedge clk) begin
        if(reset)begin 
            read_reg    <= {PORT_WIDTH{1'b0}};
            sa_ack_o    <=  1'b0;
        end else begin 
            if(sa_stb_i && ~sa_we_i)  read_reg  <=  port_io;
            sa_ack_o    <=   (sa_stb_i & ~sa_ack_o);
        end
    end
    
    
    generate            
        for(i=0;i<PORT_WIDTH; i=i+1'b1) begin: out_pin_assign0
            assign port_io =    (io_dir[i]) ?   io_write[i] :   1'bZ;
       end
       if(PORT_WIDTH!=Dw) assign sa_dat_o = {{(Dw-PORT_WIDTH){1'b0}},read_reg};
       else               assign sa_dat_o = read_reg;
    endgenerate

endmodule
		
		


module gpi #(
    parameter Aw            =   2,
    parameter SELw          =   4,
    parameter TAGw          =   3,
    parameter PORT_WIDTH    =   1,
    parameter Dw           =    PORT_WIDTH
    
    
)
(
    clk,
    reset,
    
    //wishbone bus interface
    sa_dat_i,
    sa_sel_i,
    sa_addr_i,  
    sa_tag_i,
    sa_stb_i,
    sa_cyc_i,
    sa_we_i,    
    sa_dat_o,
    sa_ack_o,
    sa_err_o,
    sa_rty_o,

    port_i
 
    
  
    
    
);

        
    //registers num
    localparam DIR_REG      =0;
    localparam WRITE_REG    =1;
    localparam READ_REG     =2;
    
    
    
    //wishbone bus interface
    input       [Dw-1       :   0]      sa_dat_i;
    input       [SELw-1     :   0]      sa_sel_i;
    input       [Aw-1       :   0]      sa_addr_i;  
    input       [TAGw-1     :   0]      sa_tag_i;
    input                               sa_stb_i;
    input                               sa_cyc_i;
    input                               sa_we_i;
    
    output      [Dw-1       :   0]      sa_dat_o;
    output  reg                         sa_ack_o;
    output                              sa_err_o;
    output                              sa_rty_o;
    
    input   [PORT_WIDTH-1     :   0]    port_i;
    
    input clk,   reset;
    
  
   assign  sa_err_o=1'b0;
   assign  sa_rty_o=1'b0;

    
    
   
    reg   [PORT_WIDTH-1         :   0] read_reg;
    
    
      
    always @(posedge clk) begin
        if(reset)begin 
            read_reg    <= {PORT_WIDTH{1'b0}};
            sa_ack_o    <=  1'b0;
        end else begin 
            if(sa_stb_i && ~sa_we_i)  read_reg  <=  port_i;
            sa_ack_o    <=   sa_stb_i && ~sa_ack_o;
        end
    end
    
    
    generate            
       if(PORT_WIDTH!=Dw) assign sa_dat_o = {{(Dw-PORT_WIDTH){1'b0}},read_reg};
       else               assign sa_dat_o = read_reg;
    endgenerate

endmodule
        
		


module gpo #(
   
    parameter Aw           =    2,
    parameter SELw         =    4,
    parameter TAGw         =    3,
    parameter PORT_WIDTH    =   1,
    parameter Dw           =    PORT_WIDTH
    
    
)
(
    clk,
    reset,
    
    //wishbone bus interface
    sa_dat_i,
    sa_sel_i,
    sa_addr_i,  
    sa_tag_i,
    sa_stb_i,
    sa_cyc_i,
    sa_we_i,    
    sa_dat_o,
    sa_ack_o,
    sa_err_o,
    sa_rty_o,
  
    port_o
    
    
);

        
    //registers num
    localparam WRITE_REG                        =1;
    
    
    
    
    input                                 clk;
    input                               reset;
    
   //wishbone bus interface
    input       [Dw-1       :   0]      sa_dat_i;
    input       [SELw-1     :   0]      sa_sel_i;
    input       [Aw-1       :   0]      sa_addr_i;  
    input       [TAGw-1     :   0]      sa_tag_i;
    input                               sa_stb_i;
    input                               sa_cyc_i;
    input                               sa_we_i;
    
    output      [Dw-1       :   0]      sa_dat_o;
    output  reg                         sa_ack_o;
    output                              sa_err_o;
    output                              sa_rty_o;
    
    output   [PORT_WIDTH-1     :   0]    port_o;
    
    
  
   assign  sa_err_o=1'b0;
   assign  sa_rty_o=1'b0;

    
    
   
    reg   [PORT_WIDTH-1         :   0]  io_write;
    
    
    
    always @ (posedge clk or posedge reset) begin
       if(reset) begin 
            io_write   <= {PORT_WIDTH{1'b0}};
            sa_ack_o   <=  1'b0;
        end else begin
            sa_ack_o   <=   (sa_stb_i & ~sa_ack_o); 
            if(sa_stb_i && sa_we_i ) begin 
               if( sa_addr_i     == WRITE_REG[Aw-1     :   0]    ) io_write   <=  sa_dat_i[PORT_WIDTH-1      :   0];
            end //sa_stb_i && sa_we_i
        end //reset
    end//always
    
    
    assign port_o =      io_write;
    
     
     
     
     
    generate            
       if(PORT_WIDTH!=Dw) assign sa_dat_o = {{(Dw-PORT_WIDTH){1'b0}},io_write};
       else               assign sa_dat_o = io_write;
    endgenerate

endmodule
        		
	
	
