module kc705_wrapper(
    // FMC conector
    // clk and rst inputs
    // output    FMC_HPC_LA00_CC_N,//reset
    output      FMC_HPC_LA00_CC_P,//clk
    // 32 input data
    input       FMC_HPC_LA01_CC_N,
    input       FMC_HPC_LA01_CC_P,
    input       FMC_HPC_LA02_N,
    input       FMC_HPC_LA02_P,
    input       FMC_HPC_LA03_N,
    input       FMC_HPC_LA03_P,
    input       FMC_HPC_LA04_N,
    input       FMC_HPC_LA04_P,
    input       FMC_HPC_LA05_N,
    input       FMC_HPC_LA05_P,
    input       FMC_HPC_LA06_N,
    input       FMC_HPC_LA06_P,
    input       FMC_HPC_LA07_N,
    input       FMC_HPC_LA07_P,
    input       FMC_HPC_LA08_N,
    input       FMC_HPC_LA08_P,
    input       FMC_HPC_LA09_N,
    input       FMC_HPC_LA09_P,
    input       FMC_HPC_LA10_N,
    input       FMC_HPC_LA10_P,
    input       FMC_HPC_LA11_N,
    input       FMC_HPC_LA11_P,
    input       FMC_HPC_LA12_N,
    input       FMC_HPC_LA12_P,
    input       FMC_HPC_LA13_N,
    input       FMC_HPC_LA13_P,
    input       FMC_HPC_LA14_N,
    input       FMC_HPC_LA14_P,
    input       FMC_HPC_LA15_N,
    input       FMC_HPC_LA15_P,
    input       FMC_HPC_LA16_N,
    input       FMC_HPC_LA16_P,
    // ready input output
    output      FMC_HPC_LA17_CC_N,
    // valid outut input
    input       FMC_HPC_LA17_CC_P,
    // 32 bit output data
    output      FMC_HPC_LA18_CC_N,
    output      FMC_HPC_LA18_CC_P,
    output      FMC_HPC_LA19_N,
    output      FMC_HPC_LA19_P,
    output      FMC_HPC_LA20_N,
    output      FMC_HPC_LA20_P,
    output      FMC_HPC_LA21_N,
    output      FMC_HPC_LA21_P,
    output      FMC_HPC_LA22_N,
    output      FMC_HPC_LA22_P,
    output      FMC_HPC_LA23_N,
    output      FMC_HPC_LA23_P,
    output      FMC_HPC_LA24_N,
    output      FMC_HPC_LA24_P,
    output      FMC_HPC_LA25_N,
    output      FMC_HPC_LA25_P,
    output      FMC_HPC_LA26_N,
    output      FMC_HPC_LA26_P,
    output      FMC_HPC_LA27_N,
    output      FMC_HPC_LA27_P,
    output      FMC_HPC_LA28_N,
    output      FMC_HPC_LA28_P,
    output      FMC_HPC_LA29_N,
    output      FMC_HPC_LA29_P,
    output      FMC_HPC_LA30_N,
    output      FMC_HPC_LA30_P,
    output      FMC_HPC_LA31_N,
    output      FMC_HPC_LA31_P,
    output      FMC_HPC_LA32_N,
    output      FMC_HPC_LA32_P,
    output      FMC_HPC_LA33_N,
    output      FMC_HPC_LA33_P,
    //ready output input 
    input       FMC_HPC_HA00_CC_N,
    // valid output intput
    output      FMC_HPC_HA00_CC_P,
    // SPI and uart irq inputs
    // input     FMC_HPC_HA01_CC_N,
    // input     FMC_HPC_HA01_CC_P,
    //asincronous rstn input
    input       FMC_HPC_HA02_N,
    ///clk status leds
    output      FMC_HPC_HA02_P,
    output      FMC_HPC_HA03_N,
    //diferential clk_input 
    input       clk_p,
    input       clk_n,
   //UART
   input         rxd,
   output        txd,
   //JTAG
   input         tdi,
   output        tdo,
   input         tms,
   input         tck,
   //SPI for SD-card
   output         spi_cs,
   output         spi_sclk,
   output         spi_mosi,
   input          spi_miso,
   //leds
    output [7: 0] led,
   //buttons
   input           button_n,
   input           button_s,
   input           button_w,
   input           button_e,
   input           button_c,
   //Dip sw   
   input [3: 0]    dipsw


);


endmodule
