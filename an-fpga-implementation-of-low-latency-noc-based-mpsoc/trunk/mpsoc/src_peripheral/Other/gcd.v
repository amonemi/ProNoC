/************************
*	GCD
*************************/

module gcd #(
parameter GCDw=32

)( clk, reset, enable, in1, in2, done, gcd);
	input clk, reset;
	input [GCDw-1 : 0] in1, in2;
	output [GCDw-1 : 0] gcd;
	input enable;
	output done;
	wire ldG, ldP, ldQ, selP0, selQ0, selP, selQ;
	wire AeqB, AltB;
	
	gcd_cu CU( 
		.clk (clk),
		.reset (reset),
		.AeqB (AeqB),
		.AltB (AltB),
		.enable (enable),
		.ldG (ldG),
		.ldP (ldP),
		.ldQ (ldQ),
		.selP0 (selP0),
		.selQ0 (selQ0),
		.selP (selP),
		.selQ (selQ),
		.done (done)
	);
	
	
	gcd_dpu #(
		.GCDw(GCDw)	
	)DPU(
		.clk (clk),
		.reset (reset),
		.in1 (in1),
		.in2 (in2),
		.gcd (gcd),
		.AeqB (AeqB),
		.AltB (AltB),
		.ldG  (ldG),
		.ldP (ldP),
		.ldQ (ldQ),
		.selP0 (selP0),
		.selQ0 (selQ0),
		.selP (selP),
		.selQ (selQ)
		);
		

endmodule




/************************
*	gcd_cu
*************************/

module gcd_cu (clk, reset, ldG, ldP, ldQ, selP0, selQ0, selP, selQ, AeqB, AltB, done, enable);
	input clk, reset;
	input AeqB, AltB, enable;
	output ldG, ldP, ldQ, selP0, selQ0, selP, selQ, done;
	reg ldG, ldP, ldQ, selP0, selQ0, selP, selQ, done;

	
	//State encoding 
	parameter S0 = 2'b00, S1 = 2'b01, S2 = 2'b10;
	reg [1:0] y;
	always @ (posedge reset or posedge clk) begin
		if (reset == 1) y <= S0;
		else begin 
			case (y)
				S0: begin if (enable == 1) y <= S1;
					else y <= S0;
				end	
				S1: begin if (AeqB == 1) y <= S2;
					else y <= S1;
				end
				S2: begin if (enable == 0) y <= S0;
					else y <= S2;
				end
				default: y <= S0;
			endcase
		end
	end
	
	
	always @ (y or enable or AeqB or AltB) begin
		ldG = 1'b0; ldP = 1'b0; ldQ = 1'b0;
		selP0 = 1'b0;
		selQ0 = 1'b0;
		selP = 1'b0;	
		selQ = 1'b0;
		done = 1'b0;
		case (y)
		S0:	begin
			done = 1'b1;
			if (enable == 1)begin
				selP0 = 1; ldP = 1; selQ0 = 1; ldQ = 1; done = 0;
			end
		end
			
		S1: begin
			if (AeqB == 1) begin 
				ldG = 1; 
				done = 1;
			end
			else if (AltB == 1) begin
				ldQ = 1;
			end
			else begin
				ldP = 1; selP = 1; selQ = 1;
			end
		end
		S2: begin
			ldG = 1;
			done = 1;
		end
		default: ;
		endcase
		end
	endmodule


	
/************************
*	gcd_dpu
*************************/

module gcd_dpu #(
	parameter GCDw=32

)( clk, reset, in1, in2, gcd, ldG, ldP, ldQ, selP0, selQ0, selP, selQ, AeqB, AltB);
	input clk, reset;
	input [GCDw-1:0] in1, in2;
	output [GCDw-1:0]  gcd;
	input ldG, ldP, ldQ, selP0, selQ0, selP, selQ;
	output AeqB, AltB;
	reg [GCDw-1:0]  reg_P, reg_Q;
	wire [GCDw-1:0]  wire_ALU;
	reg [GCDw-1:0]  gcd;
	wire AeqB, AltB;
	//RegP with Multiplex 2:1
	always @ (posedge clk or posedge reset)begin
		if (reset == 1) reg_P <= 0;
		else begin 
			if (ldP == 1)begin
				if (selP0==1) reg_P <= in1;
				else reg_P <= wire_ALU;
			end
		end
	end

		//RegQ with Multiplex 2:1
	always @ (posedge clk or posedge reset) begin
		if (reset == 1) reg_Q <= 0;
		else begin 
			if (ldQ == 1)begin
				if (selQ0==1) reg_Q <= in2;
				else reg_Q <= wire_ALU;
			end
		end
	end

	//RegG with enable signal
	always @ (posedge clk or posedge reset)begin
		if (reset == 1) gcd <= {GCDw{1'b0}};
		else begin 
			if (ldG == 1) gcd <= reg_P;
		end
	end

	//Comparator
	assign AeqB = (reg_P == reg_Q)? 1'b1 : 1'b0;
	assign AltB = (reg_P < reg_Q) ? 1'b1 : 1'b0;
	
	//Subtractor
	assign wire_ALU = ((selP == 1) & (selQ == 1)) ? (reg_P - reg_Q) : (reg_Q - reg_P);
endmodule

