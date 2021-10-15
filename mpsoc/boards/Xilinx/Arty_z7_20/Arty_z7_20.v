module Arty_z7 (

    //Clock Signal
    clk,

    //Switches
    sw,

    //RGB LEDs
   led4_b,
   led4_g, 
   led4_r, 
   led5_b, 
   led5_g, 
   led5_r, 

    //LEDs
    led,

    //Buttons
    btn,
    
    //Audio Out
    aud_pwm,
    aud_sd,

    //HDMI RX Signals 
    hdmi_rx_clk_n,
    hdmi_rx_clk_p,
    hdmi_rx_d_n,
    hdmi_rx_d_p,    
    hdmi_rx_cec,
    hdmi_rx_hpd,
    hdmi_rx_scl, 
    hdmi_rx_sda,    
    
     //HDMI TX Signals 
    hdmi_tx_cec,
    hdmi_tx_clk_n,
    hdmi_tx_clk_p,
    hdmi_tx_d_n,
    hdmi_tx_d_p,
    hdmi_tx_hpdn, 
    hdmi_tx_scl, 
    hdmi_tx_sda, 

    //ChipKit SPI
    ck_miso,                                                                                                               
    ck_mosi,                                                                                                               
    ck_sck,                                                                                                                
    ck_ss,                                                                                                                 
                                                                                                                        
    //ChipKit I2C                                                                                                     
    ck_scl, 
    ck_sda,
    
    //ChipKit Outer Digital Header
    ck_io0 ,
    ck_io1 ,
    ck_io2 ,
    ck_io3 ,
    ck_io4 ,
    ck_io5 ,
    ck_io6 ,
    ck_io7 ,
    ck_io8 ,
    ck_io9 ,
    ck_io10,
    ck_io11,
    ck_io12,
    ck_io13,
           
           
    ck_io26,
    ck_io27,
    ck_io28,
    ck_io29,
    ck_io30,
    ck_io31,
    ck_io32,
    ck_io33,
    ck_io34,
    ck_io35,
    ck_io36,
    ck_io37,
    ck_io38,
    ck_io39,
    ck_io40,
    ck_io41
    
    



);

	//Clock Signal
	input          clk;
	
	//Switches
    input [1:0]     sw;

	//RGB LEDs
    output          led4_b;
    output          led4_g; 
    output          led4_r; 
    output          led5_b; 
    output          led5_g; 
    output          led5_r; 

	//LEDs
    output [3: 0]   led;

	//Buttons
	input [3: 0]    btn;

    //Audio Out
    output           aud_pwm;
    output           aud_sd;

    //HDMI RX Signals 
    input hdmi_rx_clk_n;
    input hdmi_rx_clk_p;
    input [2:0] hdmi_rx_d_n;
    input [2:0] hdmi_rx_d_p;    
    inout  hdmi_rx_cec;
    output hdmi_rx_hpd;
    input hdmi_rx_scl; 
    inout hdmi_rx_sda;    
    
     //HDMI TX Signals 
    inout hdmi_tx_cec;
    output hdmi_tx_clk_n;
    output hdmi_tx_clk_p;
    output [2:0] hdmi_tx_d_n;
    output [2:0] hdmi_tx_d_p;
    input hdmi_tx_hpdn; 
    inout hdmi_tx_scl; 
    inout hdmi_tx_sda; 

    //ChipKit SPI
    inout ck_miso;                                                                                                               
	inout ck_mosi;                                                                                                               
    inout ck_sck;                                                                                                                
    inout ck_ss;                                                                                                                 
                                                                                                                        
    //ChipKit I2C                                                                                                     
    inout ck_scl; 
    inout ck_sda; 
    
    //ChipKit Outer Digital Header
    inout ck_io0 ;
    inout ck_io1 ;
    inout ck_io2 ;
    inout ck_io3 ;
    inout ck_io4 ;
    inout ck_io5 ;
    inout ck_io6 ;
    inout ck_io7 ;
    inout ck_io8 ;
    inout ck_io9 ;
    inout ck_io10;
    inout ck_io11;
    inout ck_io12;
    inout ck_io13;
  
  
    inout ck_io26;
    inout ck_io27;
    inout ck_io28;
    inout ck_io29;
    inout ck_io30;
    inout ck_io31;
    inout ck_io32;
    inout ck_io33;
    inout ck_io34;
    inout ck_io35;
    inout ck_io36;
    inout ck_io37;
    inout ck_io38;
    inout ck_io39;
    inout ck_io40;
    inout ck_io41;
    


endmodule
