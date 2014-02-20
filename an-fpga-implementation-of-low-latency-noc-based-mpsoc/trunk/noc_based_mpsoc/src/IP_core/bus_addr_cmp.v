module bus_addr_cmp #(
	parameter	RAM_EN		=	1,
	parameter 	NOC_EN		=	1,
	parameter 	GPIO_EN		=	1,
	parameter 	EXT_INT_EN	=	1,
	parameter 	TIMER_EN		=	1,
	parameter 	INT_CTRL_EN	=	1,
	
	parameter  	ADDR_PERFIX_	=	8,
	parameter	SLAVE_NUM_	=	3	 
	)
	(
	input		[ADDR_PERFIX_-1		:	0] addr_in,
	output	[SLAVE_NUM_-1			:	0]	cmp_out
	);

	`define		ADD_BUS_LOCALPARAM	1
	`include "../parameter.v"



	wire	[ADDR_PERFIX-1:	0]	base_start_addr	[SLAVE_NUM-1 : 0];
	wire	[ADDR_PERFIX-1:	0]	base_end_addr		[SLAVE_NUM-1 : 0];

	genvar k;
	generate
		for (k=0;k<SLAVE_NUM; k=k+1'b1) begin : comploop1
				if				(k== RAM_ID) begin 
					assign   base_start_addr [k] =  RAM_ADDR_START;
					assign	base_end_addr 	 [k] =  RAM_ADDR_START+RAM_BK_NUM;
				
				end else if(k == NOC_S_ID) begin 
					assign   base_start_addr [k] = NOC_ADDR_START;
					assign	base_end_addr 	 [k] = NOC_ADDR_START+NOC_BK_NUM;
								
				end else if(k == GPIO_ID) begin 
					assign   base_start_addr [k] = GPIO_ADDR_START;
					assign	base_end_addr 	 [k] = GPIO_ADDR_START+ GPIO_BK_NUM;
								
				end else if(k == EXT_INT_ID) begin 
					assign   base_start_addr [k] = EXT_INT_ADDR_START;
					assign	base_end_addr 	 [k] = EXT_INT_ADDR_START+ EXT_INT_BK_NUM;
								
				end else if(k == TIMER_ID) begin 
					assign   base_start_addr [k] = TIMER_ADDR_START;
					assign	base_end_addr 	 [k] = TIMER_ADDR_START+ TIMER_BK_NUM;
								
				end else if(k == INT_CTRL_ID) begin 
					assign   base_start_addr [k] = INT_CTRL_ADDR_START;
					assign	base_end_addr 	 [k] = INT_CTRL_ADDR_START+ INT_CTRL_BK_NUM;
				end  
				
				
				assign 	cmp_out[k] = (  addr_in	 >= base_start_addr [k]  ) & 	(  addr_in	   < base_end_addr[k] );
				
		end//for
	endgenerate


endmodule
