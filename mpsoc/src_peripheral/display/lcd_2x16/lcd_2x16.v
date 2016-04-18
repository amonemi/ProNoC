// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on


module lcd_2x16 #(
	parameter Dw  =	8,   // wishbone bus data width
	parameter Aw  = 2
)(
	clk,
	reset,
	
	//wishbone bus interface
	s_dat_i,
	s_addr_i,  
	s_stb_i,
	s_cyc_i,
	s_we_i,    
	s_dat_o,
	s_ack_o,
	 
	//lcd interface
	lcd_en,
	lcd_rs,
	lcd_rw,
	lcd_data	 
);



 	input                       clk;
	input                       reset;
    
    	//wishbone bus interface
	input       [Dw-1       :   0]      s_dat_i;
	input       [Aw-1       :   0]      s_addr_i;  
	input                               s_stb_i;
	input                               s_cyc_i;
	input                               s_we_i;
    
	output      [Dw-1       :   0]      s_dat_o;
	output  reg                         s_ack_o;
   
    


	output           lcd_en;
	output           lcd_rs;
	output           lcd_rw;
	inout   [  7: 0] lcd_data;
	
	
   reg [5:0]cnt;

  
	assign lcd_rw = s_addr_i[0];
	assign lcd_rs = s_addr_i[1];
  


	assign lcd_en = (cnt>0);
	assign lcd_data = (s_addr_i[0]) ? 8'bz : s_dat_i;
	assign s_dat_o  = lcd_data;

	always @(posedge clk or posedge reset) begin 
		if(reset) begin 
			s_ack_o	<=	1'b0;
			cnt=6'd0;
		end else begin 
			s_ack_o	<=	s_stb_i & (cnt==2);
			if(s_stb_i && cnt==0) cnt=6'h111111;
			else if(lcd_en)cnt=cnt-1'b1;
		end
	end
  

endmodule



