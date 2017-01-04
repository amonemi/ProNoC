
`include "system_conf.v"
`include "lm32_include.v"

module lm32 #(
    parameter INTR_NUM=32,
    parameter CFG_PL_MULTIPLY= "ENABLED", //"ENABLED","DISABLED"
    parameter CFG_PL_BARREL_SHIFT= "ENABLED",
    parameter CFG_SIGN_EXTEND="ENABLED",
    parameter CFG_MC_DIVIDE="DISABLED"

)(
    // ----- Inputs -------
    clk_i,
    rst_i,
    interrupt,
     en_i,
     // Instruction Wishbone master
    I_DAT_I,
    I_ACK_I,
    I_ERR_I,
    I_RTY_I,
    I_DAT_O,
    I_ADR_O,
    I_CYC_O,
    I_SEL_O,
    I_STB_O,
    I_WE_O,
    I_CTI_O,
    //I_LOCK_O,
    I_BTE_O,
    
    // Data Wishbone master
    D_DAT_I,
    D_ACK_I,
    D_ERR_I,
    D_RTY_I,
    D_DAT_O,
    D_ADR_O,
    D_CYC_O,
    D_SEL_O,
    D_STB_O,
    D_WE_O,
    D_CTI_O,
    //D_LOCK_O,
    D_BTE_O

);



input clk_i;                                    // Clock
input rst_i;                                    // Reset
input en_i;


wire reset;

assign reset = rst_i | ~ en_i;

//`ifdef CFG_INTERRUPTS_ENABLED
input [`LM32_INTERRUPT_RNG] interrupt;          // Interrupt pins
//`endif

`ifdef CFG_USER_ENABLED
input [`LM32_WORD_RNG] user_result;             // User-defined instruction result
input user_complete;                            // Indicates the user-defined instruction result is valid
`endif    

`ifdef CFG_IWB_ENABLED
input [`LM32_WORD_RNG] I_DAT_I;                 // Instruction Wishbone interface read data
input I_ACK_I;                                  // Instruction Wishbone interface acknowledgement
input I_ERR_I;                                  // Instruction Wishbone interface error
input I_RTY_I;                                  // Instruction Wishbone interface retry
`endif



`ifdef CFG_USER_ENABLED
output user_valid;                              // Indicates that user_opcode and user_operand_* are valid
wire   user_valid;
output [`LM32_USER_OPCODE_RNG] user_opcode;     // User-defined instruction opcode
reg    [`LM32_USER_OPCODE_RNG] user_opcode;
output [`LM32_WORD_RNG] user_operand_0;         // First operand for user-defined instruction
wire   [`LM32_WORD_RNG] user_operand_0;
output [`LM32_WORD_RNG] user_operand_1;         // Second operand for user-defined instruction
wire   [`LM32_WORD_RNG] user_operand_1;
`endif





`ifdef CFG_IWB_ENABLED
output [`LM32_WORD_RNG] I_DAT_O;                // Instruction Wishbone interface write data
wire   [`LM32_WORD_RNG] I_DAT_O;
output [`LM32_WORD_RNG] I_ADR_O;                // Instruction Wishbone interface address
wire   [`LM32_WORD_RNG] I_ADR_O;
output I_CYC_O;                                 // Instruction Wishbone interface cycle
wire   I_CYC_O;
output [`LM32_BYTE_SELECT_RNG] I_SEL_O;         // Instruction Wishbone interface byte select
wire   [`LM32_BYTE_SELECT_RNG] I_SEL_O;
output I_STB_O;                                 // Instruction Wishbone interface strobe
wire   I_STB_O;
output I_WE_O;                                  // Instruction Wishbone interface write enable
wire   I_WE_O;
output [`LM32_CTYPE_RNG] I_CTI_O;               // Instruction Wishbone interface cycle type 
wire   [`LM32_CTYPE_RNG] I_CTI_O;
//output I_LOCK_O;                                // Instruction Wishbone interface lock bus
//wire   I_LOCK_O;
output [`LM32_BTYPE_RNG] I_BTE_O;               // Instruction Wishbone interface burst type 
wire   [`LM32_BTYPE_RNG] I_BTE_O;
`endif


input [`LM32_WORD_RNG] D_DAT_I;                 // Data Wishbone interface read data
input D_ACK_I;                                  // Data Wishbone interface acknowledgement
input D_ERR_I;                                  // Data Wishbone interface error
input D_RTY_I;                                  // Data Wishbone interface retry


output [`LM32_WORD_RNG] D_DAT_O;                // Data Wishbone interface write data
wire   [`LM32_WORD_RNG] D_DAT_O;
output [`LM32_WORD_RNG] D_ADR_O;                // Data Wishbone interface address
wire   [`LM32_WORD_RNG] D_ADR_O;
output D_CYC_O;                                 // Data Wishbone interface cycle
wire   D_CYC_O;
output [`LM32_BYTE_SELECT_RNG] D_SEL_O;         // Data Wishbone interface byte select
wire   [`LM32_BYTE_SELECT_RNG] D_SEL_O;
output D_STB_O;                                 // Data Wishbone interface strobe
wire   D_STB_O;
output D_WE_O;                                  // Data Wishbone interface write enable
wire   D_WE_O;
output [`LM32_CTYPE_RNG] D_CTI_O;               // Data Wishbone interface cycle type 
wire   [`LM32_CTYPE_RNG] D_CTI_O;
//output D_LOCK_O;                                // Date Wishbone interface lock bus
//wire   D_LOCK_O;
output [`LM32_BTYPE_RNG] D_BTE_O;               // Data Wishbone interface burst type 
wire   [`LM32_BTYPE_RNG] D_BTE_O;


wire [31:0] iadr_o,dadr_o;   

lm32_top  the_lm32_top(
	.clk_i(clk_i),
	.rst_i(reset ),
	.interrupt_n(~interrupt),
	.I_DAT_I(I_DAT_I),
	.I_ACK_I(I_ACK_I),
	.I_ERR_I(I_ERR_I),
	.I_RTY_I(I_RTY_I),
	.D_DAT_I(D_DAT_I),
	.D_ACK_I(D_ACK_I),
	.D_ERR_I(D_ERR_I),
	.D_RTY_I(D_RTY_I),
	.I_DAT_O(I_DAT_O),
	.I_ADR_O(iadr_o),
	.I_CYC_O(I_CYC_O),
	.I_SEL_O(I_SEL_O),
	.I_STB_O(I_STB_O),
	.I_WE_O(I_WE_O),
	.I_CTI_O(I_CTI_O),
	.I_LOCK_O(),
	.I_BTE_O(I_BTE_O),
	.D_DAT_O(D_DAT_O),
	.D_ADR_O(dadr_o),
	.D_CYC_O(D_CYC_O),
	.D_SEL_O(D_SEL_O),
	.D_STB_O(D_STB_O),
	.D_WE_O(D_WE_O),
	.D_CTI_O(D_CTI_O),
	.D_LOCK_O(),
	.D_BTE_O(D_BTE_O)
);

	assign D_ADR_O= {2'b00,dadr_o[31:2]};
	assign I_ADR_O= {2'b00,iadr_o[31:2]};
      //  assign iwb_dat_o = 0;
       // assign iwb_tag_o = 3'b000;  // clasic wishbone without  burst 
       // assign dwb_tag_o = 3'b000;  // clasic wishbone without  burst 
      //  assign iwb_adr_o[31:30]  =   2'b00;
       // assign dwb_adr_o[31:30]  =   2'b00;

endmodule        
    

