// =============================================================================/
//                         FILE DETAILS
// Project          : LatticeMico32
// File             : lm32_simtrace.v
// Title            : Trace excecution in simulation
// Dependencies     : lm32_include.v
// Version          : soc-lm32 only
// =============================================================================

`include "lm32_include.v"

// Index of opcode field in an instruction
`define LM32_OPCODE_RNG         31:26
`define LM32_OP_RNG             30:26

/////////////////////////////////////////////////////
// Module interface
/////////////////////////////////////////////////////

module lm32_simtrace (
    // ----- Inputs -------
    clk_i,
    rst_i,
    // From pipeline
    stall_x,
    stall_m,
	valid_w,
	kill_w,
    instruction_d,
	pc_w
    );

/////////////////////////////////////////////////////
// Inputs
/////////////////////////////////////////////////////

input                         clk_i;
input                         rst_i;
input                         stall_x;        //
input                         stall_m;        //
input                         valid_w;        //
input                         kill_w;         //
input [`LM32_INSTRUCTION_RNG] instruction_d;  // Instruction to decode
input [`LM32_PC_RNG]          pc_w;           // PC of instruction in D stage

/////////////////////////////////////////////////////
// Internal nets and registers 
/////////////////////////////////////////////////////
reg [`LM32_INSTRUCTION_RNG] instruction_x;  // Instruction to decode
reg [`LM32_INSTRUCTION_RNG] instruction_m;  // Instruction to decode
reg [`LM32_INSTRUCTION_RNG] instruction;    // Instruction to decode

wire [`LM32_WORD_RNG] extended_immediate;       // Zero or sign extended immediate
wire [`LM32_WORD_RNG] high_immediate;           // Immedate as high 16 bits
wire [`LM32_WORD_RNG] immediate;                // Immedate as high 16 bits
wire [`LM32_WORD_RNG] call_immediate;           // Call immediate
wire [`LM32_WORD_RNG] branch_immediate;         // Conditional branch immediate

/////////////////////////////////////////////////////
// Functions
/////////////////////////////////////////////////////
`define  INCLUDE_FUNCTION
`include "lm32_functions.v"


wire [4:0]  r3    = instruction[25:21];
wire [4:0]  r2    = instruction[20:16];
wire [4:0]  r1    = instruction[15:11];

wire [ 4:0] imm5  = instruction[ 4:0];
wire [15:0] imm16 = instruction[15:0];
wire [26:0] imm27 = instruction[26:0];

//assign high_imm     = {instruction[15:0], 16'h0000};
wire [`LM32_PC_RNG] call_imm     = {{ 4{instruction[25]}}, instruction[25:0]};
wire [`LM32_PC_RNG] branch_imm   = {{14{instruction[15]}}, instruction[15:0] };

// synopsys translate_off

always @(posedge clk_i) 
begin
	if (stall_x == `FALSE)
		instruction_x <= instruction_d;
	if (stall_m == `FALSE)
		instruction_m <= instruction_x;
	instruction <= instruction_m;

	if ((valid_w == `TRUE) && (!kill_w)) begin
		// $write ( $stime/10 );
		$writeh( " [", pc_w << 2);
		$writeh( "]\t" );

		case ( instruction[`LM32_OPCODE_RNG] )
			6'h00: $display( "srui    r%0d, r%0d, 0x%0x",    r2, r3, imm5 );
			6'h01: $display( "nori    r%0d, r%0d, 0x%0x",    r2, r3, imm16 );
			6'h02: $display( "muli    r%0d, r%0d, 0x%0x",    r2, r3, imm16 );
			6'h03: $display( "sh      (r%0d + 0x%0x), r%0d", r3, r2, imm16 );
			6'h04: $display( "lb      r%0d, (r%0d + 0x%0x)", r2, r3, imm16 );
			6'h05: $display( "sri     r%0d, r%0d, 0x%0x",    r2, r3, imm16 );
			6'h06: $display( "xori    r%0d, r%0d, 0x%0x",    r2, r3, imm16 );
			6'h07: $display( "lh      r%0d, (r%0d + 0x%0x)", r2, r3, imm16 );
			6'h08: $display( "andi    r%0d, r%0d, 0x%0x",    r2, r3, imm16 );
			6'h09: $display( "xnori   r%0d, r%0d, 0x%0x",    r2, r3, imm16 );
			6'h0a: $display( "lw      r%0d, (r%0d + 0x%0x)", r2, r3, imm16 );
			6'h0b: $display( "lhu     r%0d, (r%0d + 0x%0x)", r2, r3, imm16 );
			6'h0c: $display( "sb      (r%0d + 0x%0x), r%0d", r3, r2, imm16 );
			6'h0d: $display( "addi    r%0d, r%0d, 0x%0x",    r2, r3, imm16 );
			6'h0e: $display( "ori     r%0d, r%0d, 0x%0x",    r2, r3, imm16 );
			6'h0f: $display( "sli     r%0d, r%0d, 0x%0x",    r2, r3, imm5  );
			6'h10: $display( "lbu     r%0d, (r%0d + 0x%0x)", r2, r3, imm16 );
			6'h11: $display( "be      r%0d, r%0d, 0x%x",     r2, r3, (pc_w + branch_imm ) << 2 );
			6'h12: $display( "bg      r%0d, r%0d, 0x%x",     r2, r3, (pc_w + branch_imm ) << 2 );
			6'h13: $display( "bge     r%0d, r%0d, 0x%x",     r2, r3, (pc_w + branch_imm ) << 2 );
			6'h14: $display( "bgeu    r%0d, r%0d, 0x%x",     r2, r3, (pc_w + branch_imm ) << 2 );
			6'h15: $display( "bgu     r%0d, r%0d, 0x%x",     r2, r3, (pc_w + branch_imm ) << 2 );
			6'h16: $display( "sw      (r%0d + 0x%0x), r%0d", r3, r2, imm16 );
			6'h17: $display( "bne     r%0d, r%0d, 0x%x",     r2, r3, (pc_w + branch_imm ) << 2 );
			6'h18: $display( "andhi   r%0d, r%0d, 0x%0x",    r2, r3, imm16 );
			6'h19: $display( "cmpei   r%0d, r%0d, 0x%0x",    r2, r3, imm16 );
			6'h1a: $display( "cmpgi   r%0d, r%0d, 0x%0x",    r2, r3, imm16 );
			6'h1b: $display( "cmpgei r%0d, r%0d, 0x%0x",     r2, r3, imm16 );
			6'h1c: $display( "cmpgeui r%0d, r%0d, 0x%0x",    r2, r3, imm16 );
			6'h1d: $display( "cmpgui r%0d, r%0d, 0x%0x",     r2, r3, imm16 );
			6'h1e: $display( "orhi    r%0d, r%0d, 0x%0x",    r2, r3, imm16 );
			6'h1f: $display( "cmpnei  r%0d, r%0d, 0x%0x",    r2, r3, imm16 );
			6'h20: $display( "sru     r%0d, r%0d, r%0d",  r1, r3, r2 );
			6'h21: $display( "nor     r%0d, r%0d, r%0d",  r1, r3, r2 );
			6'h22: $display( "mul     r%0d, r%0d, r%0d",  r1, r3, r2 );
			6'h23: $display( "divu    r%0d, r%0d, r%0d",  r1, r3, r2 );
			6'h24: $display( "rcsr    r%0d, csr%0d",      r1, r3 );
			6'h25: $display( "sr      r%0d, r%0d, r%0d",  r1, r3, r2 );
			6'h26: $display( "xor     r%0d, r%0d, r%0d",  r1, r3, r2 );
			6'h27: $display( "div (XXX not documented XXX)" );
			6'h28: $display( "and     r%0d, r%0d, r%0d",  r1, r3, r2 );
			6'h29: $display( "xnor    r%0d, r%0d, r%0d",  r1, r3, r2 );
			6'h2a: $display( "XXX" );
			6'h2b: $display( "raise (XXX: scall or break)" );
			6'h2c: $display( "sextb   r%0d, r%0d", r1, r3 );
			6'h2d: $display( "add     r%0d, r%0d, r%0d",  r1, r3, r2 );
			6'h2e: $display( "or      r%0d, r%0d, r%0d",  r1, r3, r2 );
			6'h2f: $display( "sl      r%0d, r%0d, r%0d",  r1, r3, r2 );
			6'h30: $display( "b       r%0d", r3 );
			6'h31: $display( "modu    r%0d, r%0d, r%0d",  r1, r3, r2 );
			6'h32: $display( "sub     r%0d, r%0d, r%0d",  r1, r3, r2 );
			6'h33: $display( "XXX" );
			6'h34: $display( "wcsr    csr%0d, r%0d", r3, r2 );
			6'h35: $display( "modu    r%0d, r%0d, r%0d",  r1, r3, r2 );
			6'h36: $display( "call    r%0d", r3 );
			6'h37: $display( "sexth   r%0d, r%0d", r1, r3 );
			6'h38: $display( "bi      0x%x", (pc_w + call_imm) << 2 );
			6'h39: $display( "cmpe    r%0d, r%0d, r%0d", r1, r3, r2 );
			6'h3a: $display( "cmpg    r%0d, r%0d, r%0d", r1, r3, r2 );
			6'h3b: $display( "cmpge   r%0d, r%0d, r%0d", r1, r3, r2 );
			6'h3c: $display( "cmpgeu  r%0d, r%0d, r%0d", r1, r3, r2 );
			6'h3d: $display( "cmpgu   r%0d, r%0d, r%0d", r1, r3, r2 );
			6'h3e: $display( "calli   0x%x", (pc_w + call_imm) << 2 );
			6'h3f: $display( "cmpne   r%0d, r%0d, r%0d", r1, r3, r2 );
		endcase
	end
end

// synopsys translate_on

endmodule 

