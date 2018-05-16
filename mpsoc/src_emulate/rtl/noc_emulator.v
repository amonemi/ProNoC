/**************************************
* Module: emulator
* Date:2017-01-20  
* Author: alireza     
*
* Description: 
***************************************/


module  noc_emulator #(
    //NoC parameters
    parameter V    = 1,     // V
    parameter B    = 4,     // buffer space :flit per VC 
    parameter NX   = 4, // number of node in x axis
    parameter NY   = 4, // number of node in y axis
    parameter C    = 4, //  number of flit class 
    parameter Fpay = 32,
    parameter MUX_TYPE  =   "BINARY",   //"ONE_HOT" or "BINARY"
    parameter VC_REALLOCATION_TYPE  =   "NONATOMIC",// "ATOMIC" , "NONATOMIC"
    parameter COMBINATION_TYPE= "COMB_NONSPEC",// "BASELINE", "COMB_SPEC1", "COMB_SPEC2", "COMB_NONSPEC"
    parameter FIRST_ARBITER_EXT_P_EN   =    1,  
    parameter TOPOLOGY =    "MESH",//"MESH","TORUS"
    parameter ROUTE_NAME    =   "XY",
    parameter CONGESTION_INDEX =   2,
    parameter DEBUG_EN =   0,
    parameter ROUTE_SUBFUNC ="XY",
    parameter AVC_ATOMIC_EN=1,
    parameter ADD_PIPREG_AFTER_CROSSBAR=0,
    parameter CVw=(C==0)? V : C * V,
    parameter [CVw-1:   0] CLASS_SETTING = {CVw{1'b1}}, // shows how each class can use VCs   
    parameter [V-1  :   0] ESCAP_VC_MASK = 4'b1000,  // mask scape vc, valid only for full adaptive
    parameter SSA_EN="NO", // "YES" , "NO"       
    parameter SWA_ARBITER_TYPE = "RRA",//"RRA","WRRA". RRA: Round Robin Arbiter WRRA weighted Round Robin Arbiter 
    parameter WEIGHTw = 4, // WRRA width
    
    // simulation
    parameter PATTERN_VJTAG_INDEX=125,
    parameter STATISTIC_VJTAG_INDEX=124, 
    parameter MAX_RATIO = 100,
    parameter RAM_Aw=7,
    parameter STATISTIC_NUM=8,  
    parameter TIMSTMP_FIFO_NUM=16
           


)(
    jtag_ctrl_reset,
    start_o,
    reset,
    clk,
    done
);

    input reset,jtag_ctrl_reset,clk;
    output done;
    output start_o;

    
    
  
        
    localparam
        Fw      =   2+V+Fpay,
        NC      =   (TOPOLOGY=="RING" || TOPOLOGY == "LINE")? NX    :   NX*NY,
        NCV     =   NC  * V,
        NCFw    =   NC  * Fw;
                   

    localparam
        PCK_CNTw =30,  // 1 G packets
        PCK_SIZw =14,   // 16 K flit
        MAXXw    =4,   // 16 nodes in x dimention
        MAXYw    =4,   // 16 nodes in y dimention : max emulator size is 16X16
        MAXCw    =4;   // 16 message classes  
               
               
   localparam  MAX_SIM_CLKs  = 1_000_000_000;
               
                        

    
    reg start_i;
    reg [10:0] cnt;
    
   assign start_o=start_i;
    
    
    wire [NCFw-1    :   0]  noc_flit_out_all;
    wire [NC-1      :   0]  noc_flit_out_wr_all;
    wire [NCV-1     :   0]  noc_credit_in_all;
    wire [NCFw-1    :   0]  noc_flit_in_all;
    wire [NC-1      :   0]  noc_flit_in_wr_all;  
    wire [NCV-1     :   0]  noc_credit_out_all;
    

 noc #(
        .V(V),
        .B(B), 
        .NX(NX),
        .NY(NY),
        .C(C),    
        .Fpay(Fpay), 
        .MUX_TYPE(MUX_TYPE),
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .COMBINATION_TYPE(COMBINATION_TYPE),
        .FIRST_ARBITER_EXT_P_EN(FIRST_ARBITER_EXT_P_EN),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),
        .CONGESTION_INDEX(CONGESTION_INDEX),
        .DEBUG_EN (DEBUG_EN),
        .ROUTE_SUBFUNC(ROUTE_SUBFUNC),
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING), // shows how each class can use VCs   
        .ESCAP_VC_MASK(ESCAP_VC_MASK),  //
        .SSA_EN(SSA_EN),
    	.SWA_ARBITER_TYPE(SWA_ARBITER_TYPE), 
    	.WEIGHTw(WEIGHTw)   

    )
    the_noc
    (
        .flit_out_all(noc_flit_out_all),
        .flit_out_wr_all(noc_flit_out_wr_all), 
        .credit_in_all(noc_credit_in_all),
        .flit_in_all(noc_flit_in_all),  
        .flit_in_wr_all(noc_flit_in_wr_all),  
        .credit_out_all(noc_credit_out_all),
        .reset(reset),
        .clk(clk)
    );

 
 
   Jtag_traffic_gen #(
        .PATTERN_VJTAG_INDEX(PATTERN_VJTAG_INDEX),
        .STATISTIC_VJTAG_INDEX(STATISTIC_VJTAG_INDEX),
        .V(V),
        .B(B),
        .NX(NX),
        .NY(NY),
        .Fpay(Fpay),
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),
        .C(C),
        .RAM_Aw(RAM_Aw),
        .STATISTIC_NUM(STATISTIC_NUM),  // the last 8 rows of RAM is reserved for collecting statistic values;
        .MAX_SIM_CLKs(MAX_SIM_CLKs),
        .MAX_RATIO(MAX_RATIO),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw),
        .TIMSTMP_FIFO_NUM(TIMSTMP_FIFO_NUM),
        .PCK_CNTw(PCK_CNTw),  // 1 G packets
        .PCK_SIZw(PCK_SIZw),   // 16 K flit
        .MAXXw(MAXXw),   // 16 nodes in x dimention
        .MAXYw(MAXYw),   // 16 nodes in y dimention : max emulator size is 16X16
        .MAXCw(MAXCw)   // 16 message class            
    )
    the_traffic_gen
    (
          
        .start_i(start_i),   
        .jtag_ctrl_reset(jtag_ctrl_reset),           
        .reset(reset),
        .clk(clk),
        .done(done),                  
   //noc            
        .flit_out_all(noc_flit_in_all),  
        .flit_out_wr_all(noc_flit_in_wr_all),  
        .credit_in_all(noc_credit_out_all), 
        .flit_in_all(noc_flit_out_all),  
        .flit_in_wr_all(noc_flit_out_wr_all),  
        .credit_out_all(noc_credit_in_all)
              
    );
 
  
  always @(posedge clk or posedge reset) begin 
        if(reset) begin 
            cnt     <=0;
            start_i   <=0;
       end else begin 
             if(cnt < 1020) cnt<=  cnt+1'b1;            
             if(cnt== 1000)begin 
                    start_i<=1'b1;
             end else if(cnt== 1010)begin 
                    start_i<=1'b0;
             end 
                      
        
        end    
    end
endmodule



/***************
    Jtag_traffic_gen:
    A traffic generator which can be programed using JTAG port
    

****************/
module  Jtag_traffic_gen #(
    parameter PATTERN_VJTAG_INDEX=125,
    parameter STATISTIC_VJTAG_INDEX=124, 
    parameter V = 4,    // VC num per port
    parameter B = 4,    // buffer space :flit per VC 
    parameter NX= 4,    // number of node in x axis
    parameter NY= 4,    // number of node in y axis   
    parameter Fpay = 32,
    parameter VC_REALLOCATION_TYPE  = "NONATOMIC",// "ATOMIC" , "NONATOMIC"
    parameter TOPOLOGY  = "MESH",
    parameter ROUTE_NAME    = "XY",
    parameter C = 4 ,   //  number of flit class
    parameter RAM_Aw=7,
    parameter STATISTIC_NUM=8, 
    parameter MAX_RATIO = 100,
    parameter TIMSTMP_FIFO_NUM = 16,
    parameter MAX_SIM_CLKs=1_000_000_000,   
    parameter PCK_CNTw =30,  // 1 G packets
    parameter PCK_SIZw =14,   // 16 K flit
    parameter MAXXw    =4,   // 16 nodes in x dimention
    parameter MAXYw    =4,   // 16 nodes in y dimention : max emulator size is 16X16
    parameter MAXCw    =4,   // 16 message class
    parameter SWA_ARBITER_TYPE = "RRA",
    parameter WEIGHTw  =4
)
(
    
    //output
    done,   
    
    //input  
    start_i,
   
   //noc port
    flit_out_all,     
    flit_out_wr_all,   
    credit_in_all,
    flit_in_all,   
    flit_in_wr_all,   
    credit_out_all,     
   
    jtag_ctrl_reset,
    reset,
    clk
);


    function integer log2;
      input integer number; begin   
         log2=0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end    
      end   
    endfunction // log2  


    
    localparam
        Fw      =   2+V+Fpay,
        NC      =   (TOPOLOGY=="RING" || TOPOLOGY == "LINE")? NX    :   NX*NY,
        NCw     =   log2(NC),
        NCV     =   NC  * V,
        NCFw    =   NC  * Fw;
    
    

       
    
    
    input                               reset,jtag_ctrl_reset, clk;   
    input                               start_i;
   
    output   done;
   
    // NOC interfaces
    output [NCFw-1    :   0]  flit_out_all;
    output [NC-1      :   0]  flit_out_wr_all;
    input  [NCV-1     :   0]  credit_in_all;
    input  [NCFw-1    :   0]  flit_in_all;
    input  [NC-1      :   0]  flit_in_wr_all;  
    output [NCV-1     :   0]  credit_out_all; 
   
   
   
    wire [Fw-1      :   0]  flit_out                 [NC-1           :0];   
    wire [NC-1      :   0]  flit_out_wr; 
    wire [V-1       :   0]  credit_in                [NC-1           :0];
    wire [Fw-1      :   0]  flit_in                  [NC-1           :0];   
    wire [NC-1      :   0]  flit_in_wr;  
    wire [V-1       :   0]  credit_out               [NC-1           :0];       
     
 
    wire [NC-1 :   0]  start;
    wire [NC-1      :   0]  done_sep; 
    assign done = &done_sep; 
   
    start_delay_gen #(
        .NC(NC) //number of cores

    )
    st_gen
    (
        .clk(clk),
        .reset(reset),
        .start_i(start_i),
        .start_o(start)
    );
    
    
    //jtag pattern controller  


    localparam   Dw=64,  
                 Aw =RAM_Aw;   
              


    wire [Dw-1 :   0] jtag_data ; 
    wire [Aw-1 :   0] jtag_addr ; 
    wire              jtag_we; 
    wire [Dw-1 :   0] jtag_q ;
    wire [NCw-1:   0] jtag_RAM_select;
    wire [NC-1 :   0] jtag_we_sep;
    wire [Dw-1 :   0] jtag_q_sep   [NC-1  :   0];

    assign jtag_q = jtag_q_sep[jtag_RAM_select];
   

  
  

  jtag_emulator_controller #(
        .VJTAG_INDEX(PATTERN_VJTAG_INDEX),
        .Dw(Dw),
        .Aw(Aw+NCw)
        
   )
   pttern_jtag_controller
   (
        .dat_o(jtag_data),
        .addr_o({jtag_RAM_select,jtag_addr}),
        .we_o(jtag_we),
        .q_i(jtag_q),
        .clk(clk),
        .reset(jtag_ctrl_reset)
       
   );
    
    
    
    //jtag statistic reader 
    
     
    localparam
        STATISw=log2(STATISTIC_NUM);     
   
    
    wire [STATISw-1 :   0] statis_jtag_addr ; 
    wire [Dw-1 :   0] statis_jtag_data_i;
    wire [NCw-1:   0] statis_jtag_select;
    wire [Dw-1 :   0] statis_jtag_q_sep   [NC-1  :   0];
    
    assign statis_jtag_data_i = statis_jtag_q_sep[statis_jtag_select];
         
   jtag_emulator_controller #(
        .VJTAG_INDEX(STATISTIC_VJTAG_INDEX),
        .Dw(Dw),
        .Aw(STATISw+NCw)
        
   )
   jtag_statistic_reader
   (
        .dat_o(),
        .addr_o({statis_jtag_select,statis_jtag_addr}),
        .we_o( ),
        .q_i(statis_jtag_data_i),
        .clk(clk),
        .reset(jtag_ctrl_reset)       
   );
    
    
        
    
    
    
    
    
    
    
    
   
    
    genvar x,y;
    generate 
    for (y=0;   y<NY;   y=y+1) begin: y_loop1
    	for (x=0;   x<NX; x=x+1) begin :x_loop1
       
                localparam IP_NUM   =   ((y * NX) +  x);  
                
            // seperate interfaces per router    
           
            assign  flit_in      [IP_NUM] =   flit_in_all    [(IP_NUM+1)*Fw-1    : IP_NUM*Fw];   
            assign  flit_in_wr   [IP_NUM] =   flit_in_wr_all [IP_NUM]; 
            assign  credit_out_all   [(IP_NUM+1)*V-1 : IP_NUM*V]     =   credit_out   [IP_NUM];  
            assign  flit_out_all     [(IP_NUM+1)*Fw-1    : IP_NUM*Fw]    =  flit_out     [IP_NUM];
            assign  flit_out_wr_all  [IP_NUM] =   flit_out_wr  [IP_NUM];
            assign  credit_in    [IP_NUM] =   credit_in_all  [(IP_NUM+1)*V-1 : IP_NUM*V];
            assign jtag_we_sep[IP_NUM] = (jtag_RAM_select == IP_NUM) ? jtag_we :1'b0;
            
          traffic_gen_ram #(
          	.V(V),
          	.B(B),
          	.NX(NX),
          	.NY(NY),
          	.Fpay(Fpay),
          	.VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
          	.TOPOLOGY(TOPOLOGY),
          	.ROUTE_NAME(ROUTE_NAME),
          	.C(C),
          	.RAM_Aw(RAM_Aw),
            .STATISTIC_NUM(STATISTIC_NUM), 
          	.TIMSTMP_FIFO_NUM(TIMSTMP_FIFO_NUM),
          	.MAX_SIM_CLKs(MAX_SIM_CLKs),
            .MAX_RATIO(MAX_RATIO),
          	.PCK_CNTw(PCK_CNTw),  // 1 G packets
            .PCK_SIZw(PCK_SIZw),   // 16 K flit
            .MAXXw(MAXXw),   // 16 nodes in x dimention
            .MAXYw(MAXYw),   // 16 nodes in y dimention : max emulator size is 16X16
            .MAXCw(MAXCw),   // 16 message cla
            .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
            .WEIGHTw(WEIGHTw)
          	
          )
          traffic_gen_ram_inst
          (
          	.reset(reset),
          	.clk(clk),
          	.current_x(x),
          	.current_y(y),
          	.start(start[IP_NUM]),
          	.done(done_sep[IP_NUM]),
          	//pattern updater
          	.jtag_data_b(jtag_data),
          	.jtag_addr_b(jtag_addr),
          	.jtag_we_b( jtag_we_sep[IP_NUM]     ),
          	.jtag_q_b(  jtag_q_sep[IP_NUM]  ),          	
          	//statistic reader
          	.statistic_jtag_addr_b(statis_jtag_addr),
            .statistic_jtag_q_b( statis_jtag_q_sep[IP_NUM]),         
          	
          	.flit_out(flit_out[IP_NUM]),
          	.flit_out_wr(flit_out_wr[IP_NUM]),
          	.credit_in(credit_in[IP_NUM]),
          	.flit_in(flit_in[IP_NUM]),
          	.flit_in_wr(flit_in_wr[IP_NUM]),
          	.credit_out(credit_out[IP_NUM])
          );
            
   
            
            
    
        end
    end
    endgenerate
    
    
    
   
    
    
 
endmodule



/********************
*
*   traffic_gen_ram
*
*********************/

module  traffic_gen_ram #(
    parameter V = 4,    // VC num per port
    parameter B = 4,    // buffer space :flit per VC 
    parameter NX= 4,    // number of node in x axis
    parameter NY= 4,    // number of node in y axis   
    parameter Fpay = 32,
    parameter VC_REALLOCATION_TYPE  = "NONATOMIC",// "ATOMIC" , "NONATOMIC"
    parameter TOPOLOGY  = "MESH",
    parameter ROUTE_NAME    = "XY",
    parameter C = 4,    //  number of flit class 
    parameter RAM_Aw=7,
    parameter STATISTIC_NUM=8,  // the last 8 rows of RAM is reserved for collecting statistic values;   
    parameter TIMSTMP_FIFO_NUM=16,
    parameter MAX_SIM_CLKs = 1000000,
    parameter MAX_RATIO=100,
    parameter PCK_CNTw =30,  // 1 G packets
    parameter PCK_SIZw =14,   // 16 K flit
    parameter MAXXw    =4,   // 16 nodes in x dimention
    parameter MAXYw    =4,   // 16 nodes in y dimention : max emulator size is 16X16
    parameter MAXCw    =4,  // 16 message class
    parameter SWA_ARBITER_TYPE ="RRA",
    parameter WEIGHTw  =4
)
(
    
    //output
    done,    
    
    //input
    current_x,
    current_y,  
    start,
   
   //noc port
    flit_out,     
    flit_out_wr,   
    credit_in,
    flit_in,   
    flit_in_wr,   
    credit_out, 
    
    
    //Pattern RAM to jtag interface   
    jtag_data_b, 
    jtag_addr_b, 
    jtag_we_b, 
    jtag_q_b, 
    
    // Statistic to jtag interface
    statistic_jtag_addr_b,
    statistic_jtag_q_b,    
   
    reset,
    clk
);


    function integer log2;
      input integer number; begin   
         log2=0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end    
      end   
    endfunction // log2  

  
  //  localparam   MAX_PATTERN =  (2**RAM_Aw)-1;   // support up to MAX_PATTERN different injections pattern
    
    localparam
        Xw = log2(NX),   // number of node in x axis
        Yw = log2(NY),    // number of node in y axis
        Cw = (C > 1)? log2(C): 1,
        Fw = 2+V+Fpay;
                 
     
      //define maximum width for each parameter of packet injector

    localparam    RATIOw   =7;   // log2(100)
              

    

    localparam  Dw=PCK_CNTw+ RATIOw + PCK_SIZw + MAXXw + MAXYw + MAXCw  +1;//=64  
    localparam  Aw=RAM_Aw;
    localparam  STATISw=log2(STATISTIC_NUM);      
   
    localparam 
        STATE_NUM=3,
        IDEAL =1,
        SEND_PCK=2,
        /*
        SAVE_SENT_PCK_NUM=4,
        SAVE_RSVD_PCK_NUM=8,
        SAVE_TOTAL_LATENCY_NUM=16,
        SAVE_WORST_LATENCY_NUM=32,
        */
        ASSET_DONE=4;

    localparam
        CLK_CNTw = log2(MAX_SIM_CLKs+1),
        MAX_PCK_NUM   = (2**PCK_CNTw)-1,
        MAX_PCK_SIZ   = (2**PCK_SIZw)-1;  // max packet size
    
    localparam [Aw-1    :   0]
        RAM_CNT_ADDR = 0,
        PATTERN_START_ADDR=1,        
 //       PATTERN_END_ADDR=  MAX_PATTERN,
        SENT_PCK_ADDR = 0,
        RSVD_PCK_ADDR = 1,
        TOTAL_LATENCY_ADDR  = 2,
        WORST_LATENCY_ADDR  = 3;
        

    input                               reset, clk;   
    input  [Xw-1                    :0] current_x;
    input  [Yw-1                    :0] current_y;
    input                               start;
   
    output  reg done;
    reg done_next;
    
    input [Dw-1 :   0]  jtag_data_b; 
    input [Aw-1 :   0]  jtag_addr_b; 
    input jtag_we_b; 
    output [Dw-1 :   0] jtag_q_b;
     
    input [STATISw-1    :   0] statistic_jtag_addr_b;
    output reg [Dw-1 :   0] statistic_jtag_q_b;    
    
    
    
    // NOC interfaces
    output  [Fw-1                   :0] flit_out;     
    output                              flit_out_wr;   
    input   [V-1                    :0] credit_in;    
    input   [Fw-1                   :0] flit_in;   
    input                               flit_in_wr;   
    output  [V-1                    :0] credit_out;   
     
  
   
    wire [Dw-1  :   0] q_a;
    reg  [Aw-1  :   0] addr_a,addr_a_next;
    reg                we_a;
    reg  [Dw-1  :   0] data_a;
  
    
  
  
    wire  [PCK_CNTw-1              :0] pck_num_to_send_in;
    wire  [RATIOw-1                :0] ratio,ratio_in;   
    wire  [PCK_SIZw-1              :0] pck_size_in;
    wire  [MAXXw-1                 :0] dest_x_in;
    wire  [MAXYw-1                 :0] dest_y_in;
    wire  [MAXCw-1                 :0] pck_class_in;
    wire  last_adr_in;
           
    assign {pck_num_to_send_in,ratio_in, pck_size_in,dest_x_in, dest_y_in,pck_class_in, last_adr_in}= q_a;
    
    wire  [Xw-1                    :0] dest_x = dest_x_in [Xw-1                    :0];
    wire  [Yw-1                    :0] dest_y = dest_y_in [Yw-1                    :0];
    wire  [Cw-1                    :0] pck_class= pck_class_in[Cw-1                :0];
   

    wire [CLK_CNTw-1              :0] time_stamp_h2t;
    wire sent_done, update;
    reg  [ STATE_NUM-1 :   0]  ps,ns;   
    reg  [63    :   0] total_pck_recieved,total_pck_recieved_next,total_pck_sent,total_pck_sent_next;
    reg  [63    :   0] total_latency_cnt,total_latency_cnt_next;
    reg  [31    :   0] ram_counter,ram_counter_next;
    reg  [PCK_CNTw-1 : 0] pck_number_sent,pck_number_sent_next;
    reg  [CLK_CNTw-1 : 0] worst_latency,worst_latency_next;
      
    reg nvalid_dest,reset_pck_number_sent_old;
    wire nvalid_dest_next= (current_x==dest_x && current_y==dest_y);         
    wire reset_pck_number_sent= ((pck_number_sent==pck_num_to_send_in) | nvalid_dest) & ~reset_pck_number_sent_old;  
    reg stop;
	assign ratio=(ps==SEND_PCK)?  ratio_in : {RATIOw{1'b0}};
  
  
  
   

    dual_port_ram #( 
        .Dw (Dw),
        .Aw (Aw)
    )
    the_ram
    (    
        .clk        (clk),
         //port a 
        .data_a     (data_a), 
        .addr_a     (addr_a),       
        .we_a       (we_a),
        .q_a        (q_a),
               
        //port b connected to the jtag
        .data_b     (jtag_data_b),
        .addr_b     (jtag_addr_b),
        .we_b       (jtag_we_b),
        .q_b        (jtag_q_b)
        
    );
 
 wire start_traffic;    
 reg [3:0] counter;
 
 always @(posedge clk or posedge reset) begin 
    if(reset)  counter <=4'd0;
    else if(counter<=4'b1111) counter <=counter+1'b1; 
 end
            
 assign start_traffic = counter == 4'b1100; // delaied for 12 clock cycles
    
              
   
    traffic_gen #(
        .V(V),
        .B(B),
        .NX(NX),
        .NY(NY),
        .Fpay(Fpay),
        .C(C),
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .TOPOLOGY(TOPOLOGY),
        .ROUTE_NAME(ROUTE_NAME),
        .MAX_PCK_NUM(MAX_PCK_NUM),
        .MAX_SIM_CLKs(MAX_SIM_CLKs),
        .MAX_PCK_SIZ(MAX_PCK_SIZ),
        .TIMSTMP_FIFO_NUM(TIMSTMP_FIFO_NUM),
        .MAX_RATIO(MAX_RATIO),
    	.CLASS_HDR_WIDTH(8),
    	.ROUTING_HDR_WIDTH(8),
    	.DST_ADR_HDR_WIDTH(8),
    	.SRC_ADR_HDR_WIDTH(8),
    	.SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw)
    )
    the_traffic_gen
    (
        //input 
        .ratio (ratio),
        .avg_pck_size_in(pck_size_in),
        .pck_size_in(pck_size_in), 
        .current_x(current_x),
        .current_y(current_y),
        .dest_x(dest_x),
        .dest_y(dest_y), 
        .pck_class_in(pck_class),        
        .start(start_traffic),
        .stop(stop),
        .init_weight({WEIGHTw{1'b0}}),
        .report ( ),
        
        //output
        .src_x( ),
        .src_y( ),
        .pck_number( ),
        .sent_done(sent_done), // tail flit has been sent
        .hdr_flit_sent( ),
        .update(update), // update the noc_analayzer
        .distance( ),
        .pck_class_out( ),   
        .time_stamp_h2h( ),
        .time_stamp_h2t(time_stamp_h2t),
        
         //noc
        .flit_out(flit_out),  
        .flit_out_wr(flit_out_wr),  
        .credit_in(credit_in), 
        .flit_in(flit_in),  
        .flit_in_wr(flit_in_wr),  
        .credit_out(credit_out),      
                     
        .reset(reset),
        .clk(clk)
               
    );
   
   
   
   
    always @ (*)begin 
        case (statistic_jtag_addr_b)
            SENT_PCK_ADDR: statistic_jtag_q_b=  total_pck_sent;
            RSVD_PCK_ADDR: statistic_jtag_q_b=  total_pck_recieved;
            TOTAL_LATENCY_ADDR: statistic_jtag_q_b= total_latency_cnt;
            WORST_LATENCY_ADDR: statistic_jtag_q_b= worst_latency;
            default: statistic_jtag_q_b= worst_latency; 
         endcase
    end
                
          
           
       
              
     always @ (*)begin
         ns=ps;
         addr_a_next =  addr_a;
         pck_number_sent_next = pck_number_sent;
         done_next =done;
         total_latency_cnt_next = total_latency_cnt;
         worst_latency_next = worst_latency;
         total_pck_recieved_next = total_pck_recieved;
         total_pck_sent_next = total_pck_sent;
         ram_counter_next = ram_counter;
         data_a = total_pck_sent;
         we_a = 0;
         stop=1'b0;

         if(update)begin
                total_latency_cnt_next = total_latency_cnt + time_stamp_h2t;
                if(time_stamp_h2t >worst_latency ) worst_latency_next=time_stamp_h2t;  
                total_pck_recieved_next =total_pck_recieved+1'b1;
         end 
         
         if(sent_done)begin 
                 pck_number_sent_next =pck_number_sent+1'b1;
                 total_pck_sent_next  =total_pck_sent+1'b1;
         end              

     
         case(ps)
         IDEAL : begin 
              done_next =1'b0;
              addr_a_next =RAM_CNT_ADDR;
              ram_counter_next = q_a[31:0];  // first ram data shows how many times the RAM is needed to ne read
              if( start) begin 
                    addr_a_next=PATTERN_START_ADDR;
                    ns= SEND_PCK;              
              end
         
         end//IDEAL
         SEND_PCK: begin 
            if (reset_pck_number_sent) begin 
                 pck_number_sent_next={PCK_CNTw{1'b0}};
                 if(last_adr_in)begin
                     if(ram_counter==0)begin
                       ns = ASSET_DONE;// SAVE_SENT_PCK_NUM;
                       //addr_a_next = SENT_PCK_ADDR;
                     end else addr_a_next = 1;
                     ram_counter_next=ram_counter-1'b1; 
               end else begin
                    addr_a_next=addr_a+1'b1;
                                  
               end
            
            end
                
               
                  
         
         
         end//SEND_PCk
         /*
         SAVE_SENT_PCK_NUM: begin 
            data_a = total_pck_sent;
            we_a   = 1;
            addr_a_next =RSVD_PCK_ADDR ;
            ns= SAVE_RSVD_PCK_NUM;       
         
         end
         SAVE_RSVD_PCK_NUM: begin 
            data_a = total_pck_recieved;
            addr_a_next =TOTAL_LATENCY_ADDR;
            we_a   = 1;
            ns= SAVE_TOTAL_LATENCY_NUM;       
         
         
         end        
         SAVE_TOTAL_LATENCY_NUM:  begin 
            data_a = total_latency_cnt;
            addr_a_next =WORST_LATENCY_ADDR;
            we_a   = 1; 
            ns=SAVE_WORST_LATENCY_NUM;
           
         
         end   
         SAVE_WORST_LATENCY_NUM:begin 
            data_a = worst_latency;
            we_a   = 1; 
            ns= ASSET_DONE;     
         end  
         */    
         ASSET_DONE: begin 
              done_next =1'b1;
              stop=1'b1;
         end
         endcase
      end//always
   
   
   
    always @(posedge clk) begin
        if(reset)begin
            ps      <=  IDEAL;
            addr_a  <={Aw{1'b0}};
            pck_number_sent<={PCK_CNTw{1'b0}};
            done<=1'b0;
            total_latency_cnt<=64'd0;
            total_pck_recieved<=64'd0;
            total_pck_sent<=64'd0;
            ram_counter<= 32'd0;
            nvalid_dest<=1'b0;
            reset_pck_number_sent_old<=1'b0;
            worst_latency<={CLK_CNTw{1'b0}};
        end else begin 
            ps      <=  ns;
            addr_a<= addr_a_next;
            pck_number_sent<= pck_number_sent_next;
            done <=done_next;
            total_latency_cnt<= total_latency_cnt_next;
            total_pck_recieved<= total_pck_recieved_next;
            total_pck_sent<= total_pck_sent_next;
            ram_counter<= ram_counter_next;
            nvalid_dest<=nvalid_dest_next;
            reset_pck_number_sent_old<=reset_pck_number_sent;
            worst_latency<=worst_latency_next;
        end   
     end
 


endmodule





/***********************
*
*   jtag_emulator_controller
*
***********************/



module jtag_emulator_controller #(
    parameter VJTAG_INDEX=125,
    parameter Dw=32,
    parameter Aw=32 

)(
    clk,
    reset,    
    //wishbone master interface signals
    
    dat_o,
    addr_o,
    we_o,
    q_i    
);

    //IO declaration
    input reset,clk;
         
    
    //wishbone master interface signals
     
    output  [Dw-1            :   0] dat_o;
    output  [Aw-1          :   0] addr_o;
    output  we_o; 
    input   [Dw-1           :  0]   q_i;
     
   
    
    localparam STATE_NUM=3,
                  IDEAL =1,
                  WB_WR_DATA=2,
                  WB_RD_DATA=4;
    
    reg [STATE_NUM-1    :   0] ps,ns;
    
    wire [Dw-1  :0] data_out,  data_in;
    wire  wb_wr_addr_en,  wb_wr_data_en,    wb_rd_data_en;
    reg wr_mem_en,    wb_cap_rd;
    
    reg [Aw-1   :   0]  wb_addr,wb_addr_next;
    reg [Dw-1   :   0]  wb_wr_data,wb_rd_data;
    reg wb_addr_inc;
    
    
     
    assign  we_o                = wr_mem_en;
    assign  dat_o           = wb_wr_data;
    assign  addr_o          = wb_addr;
    assign  data_in             = wb_rd_data;
//vjtag vjtag signals declaration
    

localparam VJ_DW= (Dw > Aw)? Dw : Aw;   
    
    
    vjtag_ctrl #(
        .DW(VJ_DW),
        .VJTAG_INDEX(VJTAG_INDEX)
    )
    vjtag_ctrl_inst
    (
        .clk(clk),
        .reset(reset),
        .data_out(data_out),
        .data_in(data_in),
        .wb_wr_addr_en(wb_wr_addr_en),
        .wb_wr_data_en(wb_wr_data_en),
        .wb_rd_data_en(wb_rd_data_en),
        .status_i( )
    );
    
    
    
    always @(posedge clk or posedge reset) begin 
        if(reset) begin 
            wb_addr <= {Aw{1'b0}};
            wb_wr_data  <= {Dw{1'b0}};  
            ps <= IDEAL;
        end else begin
            wb_addr <= wb_addr_next;
            ps <= ns;
            if(wb_wr_data_en) wb_wr_data  <= data_out;  
            if(wb_cap_rd) wb_rd_data <= q_i;
        end
    end
    
    
   
    
    
    always @(*)begin 
        wb_addr_next= wb_addr;
        if(wb_wr_addr_en) wb_addr_next = data_out [Aw-1 :   0];
        else if (wb_addr_inc)  wb_addr_next =   wb_addr + 1'b1;    
    end
    
    
    
    always @(*)begin 
        ns=ps;
        wr_mem_en =1'b0;
         
        wb_addr_inc=1'b0;
        wb_cap_rd=1'b0;
        case(ps)
        IDEAL : begin 
            if(wb_wr_data_en) ns= WB_WR_DATA;   
            if(wb_rd_data_en) ns= WB_RD_DATA;   
        end 
        WB_WR_DATA: begin 
            wr_mem_en =1'b1;
            ns=IDEAL;
            wb_addr_inc=1'b1;           
            
        end 
        WB_RD_DATA: begin 
          
            wb_cap_rd=1'b1;
            ns=IDEAL;
                //wb_addr_inc=1'b1;         
            
        end     
        endcase 
    end 
    
    //assign led={wb_addr[7:0], wb_wr_data[7:0]};

endmodule








module start_delay_gen #(
	parameter NC     =	64 //number of cores

)(
	clk,
	reset,
	start_i,
	start_o
);

	input reset,clk,start_i;
	output [NC-1	:	0] start_o;
	reg start_i_reg;
	wire start;
	wire cnt_increase;
	reg  [NC-1	:	0] start_o_next;
	reg [NC-1	:	0] start_o_reg;
	
	assign start= start_i_reg|start_i;

	always @(*)begin 
		if(NC[0]==1'b0)begin // odd
			start_o_next={start_o[NC-3:0],start_o[NC-2],start};
		end else begin //even
			start_o_next={start_o[NC-3:0],start_o[NC-1],start};
		
		end	
	end
	
	reg [2:0] counter;
	assign cnt_increase=(counter==3'd0);
	always @(posedge clk or posedge reset) begin 
		if(reset) begin 
			
			start_o_reg		<= {NC{1'b0}};
			start_i_reg	<=1'b0;
			counter		<=3'd0;
		end else begin 
		   counter		<= counter+3'd1;
		   start_i_reg	<=start_i;
			if(cnt_increase | start) start_o_reg <=start_o_next;
			

		end//reset
	end //always

	assign start_o=(cnt_increase | start)? start_o_reg : {NC{1'b0}};

endmodule














