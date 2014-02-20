module int_ctrl #(
	parameter INT_NUM		=	4,
	parameter DATA_WIDTH	=	32,
	parameter SEL_WIDTH	=	4,
	parameter ADDR_WIDTH = 3


	)
	(
	input 										clk,
	input											reset,
	// wishbone interface
	input		[DATA_WIDTH-1		:	0]		sa_dat_i,
	input		[SEL_WIDTH-1		:	0]		sa_sel_i,
	input		[ADDR_WIDTH-1		:	0]		sa_addr_i,	
	input											sa_stb_i,
	input											sa_we_i,
	output	[DATA_WIDTH-1		:	0]		sa_dat_o,
	output 	reg								sa_ack_o,
	//intruupt interface
	input 	[INT_NUM-1			:	0	] int_i,
	output 									  int_o
	
	
	);
	localparam 	[ADDR_WIDTH-1		:	0]		MER_REG_ADDR	=	0;
	localparam	[ADDR_WIDTH-1		:	0]		IER_REG_ADDR	=	1;
	localparam	[ADDR_WIDTH-1		:	0]		IAR_REG_ADDR	=	2;
	localparam	[ADDR_WIDTH-1		:	0]		IPR_REG_ADDR	=	3;
	
	
//internal register 	
	reg [INT_NUM-1	:	0]	ipr,ier,iar;
	reg [INT_NUM-1	:	0]	ipr_next,ier_next,iar_next;
	reg [INT_NUM-1	:	0] read,read_next;
	reg [1:0]				mer,mer_next;
	
	
	always@(*) begin 
		mer_next			= mer;
		ier_next			= ier;
		iar_next			= iar	& ~int_i;
		ipr_next			= (ipr	| int_i) & ier;
		
		read_next		=	read;
		if(sa_stb_i )
			if(sa_we_i ) begin 
				case(sa_addr_i)
					MER_REG_ADDR:	mer_next	=	sa_dat_i[1:0];	
					IER_REG_ADDR:	ier_next	=	sa_dat_i[INT_NUM-1	:	0];
					IAR_REG_ADDR:	begin 
										iar_next	=	iar | sa_dat_i[INT_NUM-1		:	0];//set iar by writting 1
										ipr_next	= ipr &	~sa_dat_i[INT_NUM-1		:	0];//reset ipr by writting 1
					end
					default:		ipr_next			= ipr	| int_i;
				endcase
			end//we
			else begin
				case(sa_addr_i)
					MER_REG_ADDR:	read_next		=	mer;
					IER_REG_ADDR:	read_next		=	ier;
					IAR_REG_ADDR:	read_next		=	iar;
					IPR_REG_ADDR:	read_next		=	ipr;
					default:			read_next		=	read;
				endcase
			end
		end//stb
		
		always @(posedge clk) begin
		if(reset)begin 
			mer		<= 2'b0;
			ier		<= {INT_NUM{1'b0}};
			iar		<= {INT_NUM{1'b0}};
			ipr		<= {INT_NUM{1'b0}};
			read		<=	{INT_NUM{1'b0}};
			sa_ack_o	<=	1'b0;
		end else begin 
			mer		<= mer_next;
			ier		<= ier_next;
			iar		<= iar_next;
			ipr		<= ipr_next;
			read		<= read_next;
			sa_ack_o	<= sa_stb_i && ~sa_ack_o;
		end
	end
	
		assign int_o	= ((mer == 2'b11)	&& (ier & ipr)	) ? 1'b1	:1'b0;
		assign sa_dat_o = {{(DATA_WIDTH-INT_NUM){1'b0}},read};
	
	
	
	
	
	
	
	endmodule
	