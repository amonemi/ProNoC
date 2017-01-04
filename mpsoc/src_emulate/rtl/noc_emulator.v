

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
    
    // simulation
    parameter MAX_PCK_NUM=2560000,
    parameter MAX_SIM_CLKs=1000000,
    parameter MAX_PCK_SIZ=10,
    parameter TIMSTMP_FIFO_NUM=16
       


)(
    reset,
    clk,
    done
);

	input reset,clk;
	output done;

	function integer log2;
	input integer number; begin   
		log2=0;    
		while(2**log2<number) begin    
			log2=log2+1;    
		end    
	end   
	endfunction // log2 
    
  
        

    localparam      Fw      =   2+V+Fpay,
                    NC      =	(TOPOLOGY=="RING")? NX    :   NX*NY,
                    Xw      =   log2(NX),
                    Yw      =   log2(NY) , 
                    Cw      =   (C>1)? log2(C): 1,
                    NCw     =   log2(NC),
                    RATIOw  =   log2(100),
                    NCV     =   NC  * V,
                    NCFw    =   NC  * Fw,
                    PCK_CNTw=   log2(MAX_PCK_NUM+1),
                    CLK_CNTw=   log2(MAX_SIM_CLKs+1),
                    PCK_SIZw=   log2(MAX_PCK_SIZ+1);

    wire [Fw-1      :   0]  ni_flit_out                 [NC-1           :0];   
    wire [NC-1      :   0]  ni_flit_out_wr; 
    wire [V-1       :   0]  ni_credit_in                [NC-1           :0];
    wire [Fw-1      :   0]  ni_flit_in                  [NC-1           :0];   
    wire [NC-1      :   0]  ni_flit_in_wr;  
    wire [V-1       :   0]  ni_credit_out               [NC-1           :0];    
    wire [NCFw-1    :   0]  flit_out_all;
    wire [NC-1      :   0]  flit_out_wr_all;
    wire [NCV-1     :   0]  credit_in_all;
    wire [NCFw-1    :   0]  flit_in_all;
    wire [NC-1      :   0]  flit_in_wr_all;  
    wire [NCV-1     :   0]  credit_out_all;

     wire [NC-1      :   0]  done_sep; 
    assign done = &done_sep; 
    reg start_i;
    reg [10:0] cnt;
    
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
        .SSA_EN(SSA_EN)
               

    )
    the_noc
    (
        .flit_out_all(flit_out_all),
        .flit_out_wr_all(flit_out_wr_all), 
        .credit_in_all(credit_in_all),
        .flit_in_all(flit_in_all),  
        .flit_in_wr_all(flit_in_wr_all),  
        .credit_out_all(credit_out_all),
        .reset(reset),
        .clk(clk)
    );

	 wire [NC-1	:	0]	start;
	 
	 start_delay_gen #(
		.NC(NC) //number of cores

	)st_gen(
		.clk(clk),
		.reset(reset),
		.start_i(start_i),
		.start_o(start)
	);

 genvar x,y;
    
    
    generate 
    for (x=0;   x<NX; x=x+1) begin :x_loop1
        for (y=0;   y<NY;   y=y+1) begin: y_loop1
                localparam IP_NUM   =   ((y * NX) +  x);
            
           jtag_traffic_gen #(
                .IP_NUM(IP_NUM),
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
                .TIMSTMP_FIFO_NUM(TIMSTMP_FIFO_NUM)
            )
            the_traffic_gen
            (
  //input          
                .current_x(x[Xw-1  :   0]),
                .current_y(y[Yw-1  :   0]),
                .start(start[IP_NUM]),
   
   //output
                
                .reset(reset),
                .clk(clk),
                .done( done_sep[IP_NUM]),
                
                
   //noc            
                .flit_out  (ni_flit_out [IP_NUM]),  
                .flit_out_wr (ni_flit_out_wr [IP_NUM]),  
                .credit_in  (ni_credit_in [IP_NUM]), 
                .flit_in (ni_flit_in [IP_NUM]),  
                .flit_in_wr (ni_flit_in_wr   [IP_NUM]),  
                .credit_out  (ni_credit_out [IP_NUM])
              
            );
            
                
                
           
            assign  ni_flit_in      [IP_NUM] =   flit_out_all    [(IP_NUM+1)*Fw-1    : IP_NUM*Fw];   
            assign  ni_flit_in_wr   [IP_NUM] =   flit_out_wr_all [IP_NUM]; 
            assign  credit_in_all   [(IP_NUM+1)*V-1 : IP_NUM*V]     =   ni_credit_out   [IP_NUM];  
            assign  flit_in_all     [(IP_NUM+1)*Fw-1    : IP_NUM*Fw]    =   ni_flit_out     [IP_NUM];
            assign  flit_in_wr_all  [IP_NUM] =   ni_flit_out_wr  [IP_NUM];
            assign  ni_credit_in    [IP_NUM] =   credit_out_all  [(IP_NUM+1)*V-1 : IP_NUM*V];
    
        end
    end
    endgenerate


endmodule


module  prototype_noc #(
    //NoC parameters
    parameter V    = 1,     // V
    parameter B    = 4,     // buffer space :flit per VC 
    parameter NX   = 4, // number of node in x axis
    parameter NY   = 4, // number of node in y axis
    parameter C    = 0, //  number of flit class 
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
    
    // simulation
    parameter MAX_PCK_NUM=2560000,
    parameter MAX_SIM_CLKs=1000000,
    parameter MAX_PCK_SIZ=10,
    parameter TIMSTMP_FIFO_NUM=16
       


)(
    reset,
    clk,
    done
);

input reset,clk;
output done;

 function integer log2;
      input integer number; begin   
         log2=0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end    
      end   
   endfunction // log2 
    
  
        

    localparam      Fw      =   2+V+Fpay,
                    NC      =	(TOPOLOGY=="RING")? NX    :   NX*NY,
                    Xw      =   log2(NX),
                    Yw      =   log2(NY) , 
                    Cw      =   (C>1)? log2(C): 1,
                    NCw     =   log2(NC),
                    RATIOw  =   log2(100),
                    NCV     =   NC  * V,
                    NCFw    =   NC  * Fw,
                    PCK_CNTw=   log2(MAX_PCK_NUM+1),
                    CLK_CNTw=   log2(MAX_SIM_CLKs+1),
                    PCK_SIZw=   log2(MAX_PCK_SIZ+1);

    wire [Fw-1      :   0]  ni_flit_out                 [NC-1           :0];   
    wire [NC-1      :   0]  ni_flit_out_wr; 
    wire [V-1       :   0]  ni_credit_in                [NC-1           :0];
    wire [Fw-1      :   0]  ni_flit_in                  [NC-1           :0];   
    wire [NC-1      :   0]  ni_flit_in_wr;  
    wire [V-1       :   0]  ni_credit_out               [NC-1           :0];    
    wire [NCFw-1    :   0]  flit_out_all;
    wire [NC-1      :   0]  flit_out_wr_all;
    wire [NCV-1     :   0]  credit_in_all;
    wire [NCFw-1    :   0]  flit_in_all;
    wire [NC-1      :   0]  flit_in_wr_all;  
    wire [NCV-1     :   0]  credit_out_all;

     wire [NC-1      :   0]  done_sep; 
    assign done = &done_sep; 
    reg start;
    reg [10:0] cnt;
    
    always @(posedge clk or posedge reset) begin 
        if(reset) begin 
            cnt     <=0;
            start   <=0;
       end else begin 
             if(cnt < 1020) cnt<=  cnt+1'b1;            
             if(cnt== 1000)begin 
                    start<=1'b1;
             end else if(cnt== 1010)begin 
                    start<=1'b0;
             end 
                      
        
        end    
    end
    

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
        .SSA_EN(SSA_EN)
               

    )
    the_noc
    (
        .flit_out_all(flit_out_all),
        .flit_out_wr_all(flit_out_wr_all), 
        .credit_in_all(credit_in_all),
        .flit_in_all(flit_in_all),  
        .flit_in_wr_all(flit_in_wr_all),  
        .credit_out_all(credit_out_all),
        .reset(reset),
        .clk(clk)
    );


 genvar x,y;
    
    
    generate 
    for (x=0;   x<NX; x=x+1) begin :x_loop1
        for (y=0;   y<NY;   y=y+1) begin: y_loop1
                localparam IP_NUM   =   ((y * NX) +  x);
            
           jtag_traffic_gen #(
                .IP_NUM(IP_NUM),
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
                .TIMSTMP_FIFO_NUM(TIMSTMP_FIFO_NUM)
            )
            the_traffic_gen
            (
  //input          
                .current_x(x[Xw-1  :   0]),
                .current_y(y[Yw-1  :   0]),
                .start(start),
   
   //output
                
                .reset(reset),
                .clk(clk),
                .done( done_sep[IP_NUM]),
                
                
   //noc            
                .flit_out  (ni_flit_out [IP_NUM]),  
                .flit_out_wr (ni_flit_out_wr [IP_NUM]),  
                .credit_in  (ni_credit_in [IP_NUM]), 
                .flit_in (ni_flit_in [IP_NUM]),  
                .flit_in_wr (ni_flit_in_wr   [IP_NUM]),  
                .credit_out  (ni_credit_out [IP_NUM])
              
            );
            
                
                
           
            assign  ni_flit_in      [IP_NUM] =   flit_out_all    [(IP_NUM+1)*Fw-1    : IP_NUM*Fw];   
            assign  ni_flit_in_wr   [IP_NUM] =   flit_out_wr_all [IP_NUM]; 
            assign  credit_in_all   [(IP_NUM+1)*V-1 : IP_NUM*V]     =   ni_credit_out   [IP_NUM];  
            assign  flit_in_all     [(IP_NUM+1)*Fw-1    : IP_NUM*Fw]    =   ni_flit_out     [IP_NUM];
            assign  flit_in_wr_all  [IP_NUM] =   ni_flit_out_wr  [IP_NUM];
            assign  ni_credit_in    [IP_NUM] =   credit_out_all  [(IP_NUM+1)*V-1 : IP_NUM*V];
    
        end
    end
    endgenerate


endmodule




module  jtag_traffic_gen #(
    parameter IP_NUM=0,
    parameter V = 4,    // VC num per port
    parameter B = 4,    // buffer space :flit per VC 
    parameter NX= 4,    // number of node in x axis
    parameter NY= 4,    // number of node in y axis   
    parameter Fpay = 32,
    parameter VC_REALLOCATION_TYPE  = "NONATOMIC",// "ATOMIC" , "NONATOMIC"
    parameter TOPOLOGY  = "MESH",
    parameter ROUTE_NAME    = "XY",
    parameter C = 4,    //  number of flit class    
    parameter MAX_PCK_NUM   = 1000000,
    parameter MAX_SIM_CLKs  = 100000000,
    parameter MAX_PCK_SIZ   = 10,  // max packet size
    parameter TIMSTMP_FIFO_NUM=16  
    
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

  /*
    function   [23:0]index_gen;   
          input [7:0] ch; input   integer c;  integer i;  integer tmp; begin 
              tmp =0; 
              for (i=0; i<2; i=i+1'b1) begin 
              tmp =  tmp +    (((c % 10)   + 6'd48) << i*8); 
                  c       =   c/10; 
              end 
              index_gen = {ch, tmp[15:0]};
          end     
     endfunction //index_gen
  */
    
    
    localparam      Xw          =   log2(NX),   // number of node in x axis
                    Yw          =  log2(NY),    // number of node in y axis
                    Cw          =  (C > 1)? log2(C): 1,
                    Fw          =   2+V+Fpay,
                    RATIOw      =   log2(100),
                    PCK_CNTw    =   log2(MAX_PCK_NUM+1),
                    CLK_CNTw    =   log2(MAX_SIM_CLKs+1),
                    PCK_SIZw    =   log2(MAX_PCK_SIZ+1);

       
    
    
    input                               reset, clk;   
    input  [Xw-1                    :0] current_x;
    input  [Yw-1                    :0] current_y;
    input                               start;
   
    output  reg done;
   
    // NOC interfaces
    output  [Fw-1                   :0] flit_out;     
    output                              flit_out_wr;   
    input   [V-1                    :0] credit_in;    
    input   [Fw-1                   :0] flit_in;   
    input                               flit_in_wr;   
    output  [V-1                    :0] credit_out;   
  
   
    
    
    
    //wires
    wire  [RATIOw-1                :0] ratio,ratio_in;
   
    wire  [PCK_SIZw-1              :0] pck_size;
    wire  [Xw-1                    :0] dest_x;
    wire  [Yw-1                    :0] dest_y;
    wire  [Cw-1                    :0] pck_class_in;
    
   //
    wire                              update;
    wire [CLK_CNTw-1              :0] time_stamp_h2h,time_stamp_h2t;
    wire [31                      :0] distance;
    wire [Cw-1                    :0] pck_class_out;
   
    wire [PCK_CNTw-1              :0] pck_number_recieved,pck_num_to_send;
    reg  [PCK_CNTw-1              :0] pck_number_sent;
   
    wire                              sent_done;
    wire                              hdr_flit_sent;
   
    reg  [31    :   0] total_pck_recieved,total_pck_sent;
	 reg  [35    :   0] total_latency_cnt;
    reg  [31    :   0] ram_counter;
    wire [31    :   0] initial_ram_cnt;
    

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
        .TIMSTMP_FIFO_NUM(TIMSTMP_FIFO_NUM)
    )
    the_traffic_gen
    (
        //input 
        .ratio (ratio),
        .pck_size(pck_size), 
        .current_x(current_x),
        .current_y(current_y),
        .dest_x(dest_x),
        .dest_y(dest_y), 
        .pck_class_in(pck_class_in),        
        .start(start),
        .report (),
        //output
        .pck_number(pck_number_recieved),
        .sent_done(sent_done), // tail flit has been sent
        .hdr_flit_sent(hdr_flit_sent),
        .update(update), // update the noc_analayzer
        .distance(distance),
        .pck_class_out(pck_class_out),   
        .time_stamp_h2h(time_stamp_h2h),
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




localparam  RAM_TAG_STRING=IP_NUM;
localparam  SRC_PRB_TAG=IP_NUM+128;

localparam  RAM_ID = {"ENABLE_RUNTIME_MOD=NO"};
localparam  Dw=PCK_CNTw+ RATIOw + PCK_SIZw + Xw + Yw + Cw +1;  
localparam  Aw=7;

reg     [Aw-1    :   0] ram_addr;
wire    [Dw-1    :   0] ram_do;  
wire last_adr;


// control/monitor packet injector using In-System Sources and Probes Editor 

localparam PRBw=36+32+32,
           SRCw=32;
            
wire [SRCw-1    :   0] source;
wire [PRBw-1    :   0] probe;

assign probe ={total_latency_cnt, total_pck_recieved,total_pck_sent};
assign initial_ram_cnt      =source;

	
	ram_single_port_jtag #(
		.Dw(Dw), 
		.Aw(Aw),
		.JTAG_INDEX(RAM_TAG_STRING), //use for programming the memory at run time
		.BENw(1)
	
	) ram_inst
	(
	    .clk(clk),
	    .reset(1'b0),	
	    //memory interface
	    .data_a({Dw{1'b0}}),
	    .addr_a(ram_addr),
	    .byteena_a(1'b1),
	    .we_a(1'b0),
	    .q_a(ram_do)
	   
	);

   



 
localparam jDw=(PRBw>SRCw)? PRBw : SRCw;
   
	jtag_source_probe #(
        .Dw(jDw),
        .VJTAG_INDEX(SRC_PRB_TAG)
    
    ) 
    src_pb
    (
        .probe(probe),
        .source(source)
     );
 

 


     
  
     
    assign {pck_num_to_send,ratio_in,pck_size,dest_x,dest_y,pck_class_in,last_adr}=ram_do; 
    
    assign ratio=(done)?  {RATIOw{1'b0}} : ratio_in;
     wire nvalid_dest= (current_x==dest_x && current_y==dest_y);
    wire reset_pck_number_sent= (pck_number_sent==pck_num_to_send) | nvalid_dest;
   
    always @(posedge clk) begin
        if(reset)begin
            ram_addr<={Aw{1'b0}};
            pck_number_sent<={PCK_CNTw{1'b0}};
            done<=1'b0;
            total_latency_cnt<=36'd0;
            total_pck_recieved<=0;
            total_pck_sent<=0;
            ram_counter<= initial_ram_cnt;
        end else begin 
            if (reset_pck_number_sent)  pck_number_sent<={PCK_CNTw{1'b0}};
            else if(sent_done)begin 
                 pck_number_sent<=pck_number_sent+1'b1;
                 total_pck_sent <=total_pck_sent+1'b1;
            end
            
            if(update)begin
                total_latency_cnt<= total_latency_cnt + time_stamp_h2t;
                total_pck_recieved<=total_pck_recieved+1'b1;
            end
           
            if (reset_pck_number_sent  &&  done==1'b0)begin
               if(last_adr)begin
                     ram_addr<={Aw{1'b0}};
                     if(ram_counter==0)begin
                        done<=1'b1;
                     end
                            ram_counter<=ram_counter-1'b1; 
               end else begin
                    ram_addr<=ram_addr+1'b1;
                                  
               end
            end   
            
            
        end    
    
    end


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
			counter		<=2'd0;
		end else begin 
		   counter		<= counter+3'd1;
		   start_i_reg	<=start_i;
			if(cnt_increase | start) start_o_reg <=start_o_next;
			

		end//reset
	end //always

	assign start_o=(cnt_increase | start)? start_o_reg : {NC{1'b0}};

endmodule








