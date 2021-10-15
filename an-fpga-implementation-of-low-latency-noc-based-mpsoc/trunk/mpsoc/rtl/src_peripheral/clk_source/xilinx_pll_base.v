/**************************************
* Module: xilinx_pll_base
* Date:2020-03-18  
* Author: alireza     
*
* Description: 
***************************************/
module  xilinx_pll_base #(
    parameter BANDWIDTH = "OPTIMIZED",  // OPTIMIZED, HIGH, LOW
    parameter CLKFBOUT_MULT = 5,        // Multiply value for all CLKOUT, (2-64)
    parameter CLKFBOUT_PHASE = 0.0,     // Phase offset in degrees of CLKFB, (-360.000-360.000).
    parameter CLKIN1_PERIOD =0.0,      // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
    // CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for each CLKOUT (1-128)
    parameter CLKOUT0_DIVIDE =1,
    parameter CLKOUT1_DIVIDE =1,
    parameter CLKOUT2_DIVIDE =1,
    parameter CLKOUT3_DIVIDE =1,
    parameter CLKOUT4_DIVIDE =1,
    parameter CLKOUT5_DIVIDE =1,
    // CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for each CLKOUT (0.001-0.999).
    parameter CLKOUT0_DUTY_CYCLE= 0.5,
    parameter CLKOUT1_DUTY_CYCLE=0.5,
    parameter CLKOUT2_DUTY_CYCLE=0.5,
    parameter CLKOUT3_DUTY_CYCLE=0.5,
    parameter CLKOUT4_DUTY_CYCLE=0.5,
    parameter CLKOUT5_DUTY_CYCLE=0.5,
    // CLKOUT0_PHASE - CLKOUT5_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
    parameter CLKOUT0_PHASE=0.0,
    parameter CLKOUT1_PHASE=0.0,
    parameter CLKOUT2_PHASE=0.0,
    parameter CLKOUT3_PHASE=0.0,
    parameter CLKOUT4_PHASE=0.0,
    parameter CLKOUT5_PHASE=0.0,
    parameter DIVCLK_DIVIDE=1,        // Master division value, (1-56)
    parameter REF_JITTER1=0.0,        // Reference input jitter in UI, (0.000-0.999).
    parameter STARTUP_WAIT="FALSE"    // Delay DONE until PLL Locks, ("TRUE"/"FALSE")
)(
  // Clock Outputs: 1-bit (each) output: User configurable clock outputs    
    output clk_out0,   // 1-bit output: CLKOUT0                             
    output clk_out1,   // 1-bit output: CLKOUT1                             
    output clk_out2,   // 1-bit output: CLKOUT2                             
    output clk_out3,   // 1-bit output: CLKOUT3                             
    output clk_out4,   // 1-bit output: CLKOUT4                             
    output clk_out5,   // 1-bit output: CLKOUT5                             
  // Feedback Clocks: 1-bit (each) output: Clock feedback ports             
   // output CLKFBOUT, // 1-bit output: Feedback clock                      
    output reset_out,     // 1-bit output: LOCK                                
    input clk_in,     // 1-bit input: Input clock                          
  // Control Ports: 1-bit (each) input: PLL control ports                   
  //  input PWRDWN,     // 1-bit input: Power-down                           
    input reset_in           // 1-bit input: Reset                                
  // Feedback Clocks: 1-bit (each) input: Clock feedback ports              
    //input CLKFBIN    // 1-bit input: Feedback clock                       
);



 // Xilinx HDL Language Template, version 2019.1

wire clk_feedback;
wire locked;

   PLLE2_BASE #(
    .BANDWIDTH           (BANDWIDTH            ),
    .CLKFBOUT_MULT       (CLKFBOUT_MULT        ),
    .CLKFBOUT_PHASE      (CLKFBOUT_PHASE       ),
    .CLKIN1_PERIOD       (CLKIN1_PERIOD        ),
                         
    .CLKOUT0_DIVIDE      (CLKOUT0_DIVIDE       ),
    .CLKOUT1_DIVIDE      (CLKOUT1_DIVIDE       ),
    .CLKOUT2_DIVIDE      (CLKOUT2_DIVIDE       ),
    .CLKOUT3_DIVIDE      (CLKOUT3_DIVIDE       ),
    .CLKOUT4_DIVIDE      (CLKOUT4_DIVIDE       ),
    .CLKOUT5_DIVIDE      (CLKOUT5_DIVIDE       ),
                         
    .CLKOUT0_DUTY_CYCLE  (CLKOUT0_DUTY_CYCLE   ),
    .CLKOUT1_DUTY_CYCLE  (CLKOUT1_DUTY_CYCLE   ),
    .CLKOUT2_DUTY_CYCLE  (CLKOUT2_DUTY_CYCLE   ),
    .CLKOUT3_DUTY_CYCLE  (CLKOUT3_DUTY_CYCLE   ),
    .CLKOUT4_DUTY_CYCLE  (CLKOUT4_DUTY_CYCLE   ),
    .CLKOUT5_DUTY_CYCLE  (CLKOUT5_DUTY_CYCLE   ),
                         
    .CLKOUT0_PHASE       (CLKOUT0_PHASE        ),
    .CLKOUT1_PHASE       (CLKOUT1_PHASE        ),
    .CLKOUT2_PHASE       (CLKOUT2_PHASE        ),
    .CLKOUT3_PHASE       (CLKOUT3_PHASE        ),
    .CLKOUT4_PHASE       (CLKOUT4_PHASE        ),
    .CLKOUT5_PHASE       (CLKOUT5_PHASE        ),
    .DIVCLK_DIVIDE       (DIVCLK_DIVIDE        ),
    .REF_JITTER1         (REF_JITTER1          ),
    .STARTUP_WAIT        (STARTUP_WAIT         )
   )
   PLLE2_BASE_inst
   (
      // Clock Outputs: 1-bit (each) output: User configurable clock outputs
      .CLKOUT0(clk_out0),   // 1-bit output: CLKOUT0
      .CLKOUT1(clk_out1),   // 1-bit output: CLKOUT1
      .CLKOUT2(clk_out2),   // 1-bit output: CLKOUT2
      .CLKOUT3(clk_out3),   // 1-bit output: CLKOUT3
      .CLKOUT4(clk_out4),   // 1-bit output: CLKOUT4
      .CLKOUT5(clk_out5),   // 1-bit output: CLKOUT5
      // Feedback Clocks: 1-bit (each) output: Clock feedback ports
      .CLKFBOUT(clk_feedback), // 1-bit output: Feedback clock
      .LOCKED(locked),     // 1-bit output: LOCK
      .CLKIN1(clk_in),     // 1-bit input: Input clock
      // Control Ports: 1-bit (each) input: PLL control ports
      .PWRDWN(1'b0),     // 1-bit input: Power-down
      .RST(reset_in),           // 1-bit input: Reset
      // Feedback Clocks: 1-bit (each) input: Clock feedback ports
      .CLKFBIN(clk_feedback)    // 1-bit input: Feedback clock
   );

    assign reset_out =~locked;

endmodule

