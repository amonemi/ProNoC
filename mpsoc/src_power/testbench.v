`timescale 1ps/1ps 


module testbench;


`define  INCLUD_TESTBENCH
`define  INCLUDE_PARAM 
`include "parameter.v"

localparam CONGw =2;
  function integer log2;
      input integer number;	begin	
         log2=0;	
         while(2**log2<number) begin	
            log2=log2+1;	
         end	
      end	
   endfunction // log2 
 
 
localparam 	PV		=	V		*	P,
				PVV	    =	PV		*  V,	
				P_1	    =	P-1	,
				PP_1	=	P_1     *	P,
				PVP_1	=	PV      *	P_1;

	localparam 	Fw		=	2+V+Fpay,	//flit width;	
                PFw		=	P*Fw,
                Xw      =   log2(NX),
                Yw      =   log2(NY),
                CONG_ALw=   CONGw* P;    //  congestion width per router         
                   

	
	reg  [Xw-1       :   0]  current_x;
	reg  [Yw-1       :   0]  current_y;
	
	reg  [PFw-1      :   0]  flit_in_all;
	reg  [P-1        :   0]  flit_in_we_all;
	wire [PV-1       :   0]  credit_out_all;
	//reg  [CONG_ALw-1 :   0]  congestion_in_all;
	
	wire [PFw-1      :   0]  flit_out_all;
	wire [P-1        :   0]  flit_out_we_all;
	reg  [PV-1       :   0]  credit_in_all;
	wire [CONG_ALw-1 :   0]  congestion_out_all;
	
	reg clk,reset;



router_top 

the_router

(
		.current_x(current_x),
		.current_y(current_y),
		.flit_in_all(flit_in_all),
		.flit_in_we_all(flit_in_we_all),
		.credit_out_all(credit_out_all),
		//.congestion_in_all(congestion_in_all),
		.flit_out_all(flit_out_all),
		.flit_out_we_all(flit_out_we_all),
		.credit_in_all(credit_in_all),
		.congestion_out_all(congestion_out_all),
		.clk(clk),
		.reset(reset)
	);







`define  INCLUDE_CLK
`include "clk.v"


initial begin 
	reset =1'b1;
	current_x=4;
	current_y=4;
	flit_in_all=0;
	flit_in_we_all=0;
	//congestion_in_all=0;
	credit_in_all=0;
	
	#200000
	@(posedge clk)#10 reset =1'b0;
	`include "samples.v"
	
	$stop();
	

end


endmodule
