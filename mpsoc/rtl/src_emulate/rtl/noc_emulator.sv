/**************************************
* Module: emulator
* Date:2017-01-20  
* Author: alireza     
*
* Description: 
***************************************/
`include "pronoc_def.v"

module  noc_emulator	
 #(
    parameter NOC_ID=0,   
    // simulation
    parameter PATTERN_VJTAG_INDEX=125,
    parameter STATISTIC_VJTAG_INDEX=124    
)(
    jtag_ctrl_reset,
    start_o,
    reset,
    clk,
    done
);

    `NOC_CONF

	parameter MAX_RATIO = 100;
    parameter RAM_Aw=7;
    parameter STATISTIC_NUM=8;  
   

    input reset,jtag_ctrl_reset,clk;
    output done;
    output start_o;     

    localparam
        PCK_CNTw =30,  // 1 G packets
        PCK_SIZw =14,   // 16 K flit
        MAX_EAw  =8,  
        MAX_Cw   =4;   // 16 message classes                 
               
   //localparam  MAX_SIM_CLKs  = 1_000_000_000;
    
    reg start_i;
    reg [10:0] cnt;
    
    assign start_o=start_i;
   
   
    //noc connection channels
    smartflit_chanel_t chan_in_all  [NE-1 : 0];
	smartflit_chanel_t chan_out_all [NE-1 : 0];

	noc_top  # ( 
		.NOC_ID(NOC_ID)
	) the_top (
		.reset(reset),
		.clk(clk),    
		.chan_in_all(chan_in_all),
		.chan_out_all(chan_out_all),
		.router_event()
	);
 
   Jtag_traffic_gen #(
        .NOC_ID(NOC_ID),
        .PATTERN_VJTAG_INDEX(PATTERN_VJTAG_INDEX),
        .STATISTIC_VJTAG_INDEX(STATISTIC_VJTAG_INDEX),
		.MAX_RATIO(MAX_RATIO),
        .RAM_Aw(RAM_Aw),
        .STATISTIC_NUM(STATISTIC_NUM),  // the last 8 rows of RAM is reserved for collecting statistic values;
        .PCK_CNTw(PCK_CNTw),  // 1 G packets
        .PCK_SIZw(PCK_SIZw),   // 16 K flit
        .MAX_EAw(MAX_EAw),   // 16 nodes in x dimension
        .MAX_Cw(MAX_Cw)   // 16 message class            
    )
    the_traffic_gen
    (
          
        .start_i(start_i),   
        .jtag_ctrl_reset(jtag_ctrl_reset),           
        .reset(reset),
        .clk(clk),
        .done(done),                  
   		//noc            
        .chan_in_all(chan_out_all),
		.chan_out_all(chan_in_all)       
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

module  Jtag_traffic_gen 
#(
    parameter NOC_ID = 0,
    parameter PATTERN_VJTAG_INDEX=125,
    parameter STATISTIC_VJTAG_INDEX=124, 
    parameter RAM_Aw=7,
    parameter STATISTIC_NUM=8, 
    parameter MAX_RATIO = 100,
    parameter PCK_CNTw =30,  // 1 G packets
    parameter PCK_SIZw =14,   // 16 K flit
    parameter MAX_EAw    =8,   
    parameter MAX_Cw    =4   // 16 message class
)
(
    chan_in_all,
	chan_out_all,

    done,       
    start_i,   
    jtag_ctrl_reset,
    reset,
    clk
);

`NOC_CONF

    
    
    input  reset,jtag_ctrl_reset, clk;   
    input  start_i;
    output done;
   
    // NOC interfaces
    input  smartflit_chanel_t chan_in_all  [NE-1 : 0];
	output smartflit_chanel_t chan_out_all [NE-1 : 0];
   
     
 
    wire [NE-1 :   0]  start;
    wire [NE-1      :   0]  done_sep; 
    assign done = &done_sep; 
   
    start_delay_gen #(
        .NC(NE) //number of cores

    )
    st_gen
    (
        .clk(clk),
        .reset(reset),
        .start_i(start_i),
        .start_o(start)
    );
        
    //jtag pattern controller  

    localparam   
		NEw=$clog2(NE),		
		Dw=64,  
        Aw =RAM_Aw;   

    wire [Dw-1 :   0] jtag_data ; 
    wire [Aw-1 :   0] jtag_addr ; 
    wire              jtag_we; 
    wire [Dw-1 :   0] jtag_q ;
    wire [NEw-1:   0] jtag_RAM_select;
    wire [NE-1 :   0] jtag_we_sep;
    wire [Dw-1 :   0] jtag_q_sep   [NE-1  :   0];

    assign jtag_q = jtag_q_sep[jtag_RAM_select];
   

    jtag_emulator_controller #(
        .VJTAG_INDEX(PATTERN_VJTAG_INDEX),
        .Dw(Dw),
        .Aw(Aw+NEw)        
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
    wire [NEw-1:   0] statis_jtag_select;
    wire [Dw-1 :   0] statis_jtag_q_sep   [NE-1  :   0];
    
    assign statis_jtag_data_i = statis_jtag_q_sep[statis_jtag_select];
         
   jtag_emulator_controller #(
        .VJTAG_INDEX(STATISTIC_VJTAG_INDEX),
        .Dw(Dw),
        .Aw(STATISw+NEw)
        
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
  
   function integer addrencode;
        input integer pos,k,n,kw;
        integer pow,i,tmp;begin
        addrencode=0;
        pow=1;
        for (i = 0; i <n; i=i+1 ) begin 
            tmp=(pos/pow);
            tmp=tmp%k;
            tmp=tmp<<i*kw;
            addrencode=addrencode | tmp;
            pow=pow * k;
        end
        end   
    endfunction 
  
    
    genvar i;
    generate 
    for (i=0;   i<NE;   i=i+1) begin: endp
    	     
    	wire [EAw-1 : 0] current_e_addr [NE-1 : 0];
			
    	endp_addr_encoder #(
    		.TOPOLOGY(TOPOLOGY),
    		.T1(T1),
    		.T2(T2),
    		.T3(T3),
    		.EAw(EAw),
    		.NE(NE)
    	)
    	encoder
    	(
    		.id(i[NEw-1 : 0]),
    		.code(current_e_addr[i])
    	);     
                
                
        // seperate interfaces per router             
        assign jtag_we_sep[i] = (jtag_RAM_select == i) ? jtag_we :1'b0;
            
        traffic_gen_ram #(
            .NOC_ID(NOC_ID),
          	.RAM_Aw(RAM_Aw),
            .STATISTIC_NUM(STATISTIC_NUM), 
          	.MAX_RATIO(MAX_RATIO),
          	.PCK_CNTw(PCK_CNTw),  // 1 G packets
            .PCK_SIZw(PCK_SIZw),   // 16 K flit
            .MAX_EAw(MAX_EAw),  
            .MAX_Cw(MAX_Cw)   // 16 message cla
          )
          traffic_gen_ram_inst
          (
          	.reset(reset),
          	.clk(clk),
          	.current_r_addr(chan_in_all[i].ctrl_chanel.neighbors_r_addr),
            .current_e_addr(current_e_addr[i]),
          	.start(start[i]),
          	.done(done_sep[i]),
          	//pattern updater
          	.jtag_data_b(jtag_data),
          	.jtag_addr_b(jtag_addr),
          	.jtag_we_b( jtag_we_sep[i]),
          	.jtag_q_b(  jtag_q_sep[i]),          	
          	//statistic reader
          	.statistic_jtag_addr_b(statis_jtag_addr),
            .statistic_jtag_q_b( statis_jtag_q_sep[i]),       
          	//noc interface
			.chan_in (chan_in_all[i]),
			.chan_out(chan_out_all[i])
          	
          );        
    end
    endgenerate
     
endmodule



/********************
*
*   traffic_gen_ram
*
*********************/

module  traffic_gen_ram 
#(
    parameter NOC_ID=0,
    parameter RAM_Aw=7,
    parameter STATISTIC_NUM=8,  // the last 8 rows of RAM is reserved for collecting statistic values;   
    parameter MAX_RATIO=100,
    parameter PCK_CNTw =30,  // 1 G packets
    parameter PCK_SIZw =14,   // 16 K flit
    parameter MAX_EAw    =8,   
    parameter MAX_Cw    =4  // 16 message class
  
)
(
       
    done,    
    current_r_addr,
    current_e_addr,
    start,
   
   //noc port
    chan_in,
	chan_out, 
    
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

    `NOC_CONF
   

  
  //  localparam   MAX_PATTERN =  (2**RAM_Aw)-1;   // support up to MAX_PATTERN different injections pattern
    
   
                 
     
      //define maximum width for each parameter of packet injector

    localparam    RATIOw   =7;   // log2(100)  

    localparam  Dw=PCK_CNTw+ RATIOw + PCK_SIZw + MAX_EAw + MAX_Cw  +1;//=64  
    localparam  Aw=RAM_Aw;
    localparam  STATISw=log2(STATISTIC_NUM);      
   
    localparam 
        STATE_NUM=5,
        IDEAL =1,
        WAIT1 = 2,
        WAIT2 = 4,
        SEND_PCK=8,
        /*
        SAVE_SENT_PCK_NUM=4,
        SAVE_RSVD_PCK_NUM=8,
        SAVE_TOTAL_LATENCY_NUM=16,
        SAVE_WORST_LATENCY_NUM=32,
        */
        ASSET_DONE=16;

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
    // the connected router address
    input  [RAw-1                   :0] current_r_addr;
    // the current endpoint address
    input  [EAw-1                   :0] current_e_addr;

   
   
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
    input   smartflit_chanel_t 	chan_in;
	output  smartflit_chanel_t 	chan_out;  
     
  
   
    wire [Dw-1  :   0] q_a;
    reg  [Aw-1  :   0] addr_a,addr_a_next;
    reg                we_a;
    reg  [Dw-1  :   0] data_a; 
  
  
    wire  [PCK_CNTw-1 :0] pck_num_to_send_in;
    wire  [RATIOw-1 :0] ratio,ratio_in;   
    wire  [PCK_SIZw-1 :0] pck_size_in;
    wire  [MAX_EAw-1  :0] dest_e_in;
    wire  [MAX_Cw-1   :0] pck_class_in;
    wire  last_adr_in;
           
    assign {pck_num_to_send_in,ratio_in, pck_size_in,dest_e_in, pck_class_in, last_adr_in}= q_a;
    
    wire  [EAw-1                    :0] dest_e_addr = dest_e_in [EAw-1                    :0];
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
    wire nvalid_dest_next= (current_e_addr==dest_e_addr && ps!=IDEAL && ps!=WAIT1);         
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
    else begin 
        if(start)  counter <=4'd1;
        else if(counter> 4'd0 &&  counter<=4'b1111) counter <=counter+1'b1; 
    end
 end
            
 assign start_traffic = counter == 4'b1100; // delaied for 12 clock cycles
    
       
  traffic_gen_top #(
        .NOC_ID(NOC_ID),
        .MAX_RATIO(MAX_RATIO)
    )
    the_traffic_gen
    (
    
        .reset(reset),
        .clk(clk),
        //input 
        .ratio (ratio),
        .start(start_traffic),
        .stop(stop),
        .pck_size_in(pck_size_in), 
        .current_e_addr(current_e_addr),
        .dest_e_addr(dest_e_addr),        
        .pck_class_in(pck_class),         
        .init_weight({WEIGHTw{1'b0}}),
        .report ( ),
        
        //output
        .update(update), // update the noc_analayzer
        .src_e_addr( ),      
        .pck_number( ),
        .sent_done(sent_done), // tail flit has been sent
        .hdr_flit_sent( ),
        .distance( ),
        .pck_class_out( ),   
        .time_stamp_h2h( ),
        .time_stamp_h2t(time_stamp_h2t),
        .flit_out_class(),
         //noc
         .chan_in(chan_in),
		 .chan_out(chan_out),  
		 .mcast_dst_num_o()
			
               
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
                    ns= WAIT1;              
              end
         
         end//IDEAL
         WAIT1 : begin 
            ns= WAIT2;            
         
         end 
         WAIT2 : begin 
            ns= SEND_PCK;            
         
         end        
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




