 // synthesis translate_off
`timescale   1ns/1ns


module testbench_modelsim;
parameter MAX_PCK_SIZ =10 ,
          PCK_SIZw    = log2(MAX_PCK_SIZ+1);


    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 

localparam RATIOw=log2(100);


reg     reset ,clk;
reg     start;
wire    done;
reg [RATIOw-1:0] ratio;
reg [PCK_SIZw-1 :   0]pck_size_in;



testbench_sub 
uut (
    .reset  (reset) ,
    .clk        (clk),
    .start  (start),
    .ratio   (ratio), 
    .pck_size_in(pck_size_in),
    .all_done (done)
);


initial begin 
    clk = 1'b0;
    forever clk = #10 ~clk;
end 

integer i;

initial begin 
    reset = 1'b1;
    start = 1'b0;
    pck_size_in=4;
    ratio =50;
    i=0;
    #40
    repeat(8) begin 
        reset = 1'b1;
        #40
        @(posedge clk) reset = 1'b0;
        #200
        @(posedge clk) start = 1'b1;
        @(posedge clk) start = 1'b0;
        @(posedge done) 
        #100
	 ratio=0;
	@(posedge clk) start = 1'b1;
        @(posedge clk) start = 1'b0;
	#10000;


        ratio= ratio +5;
        i=i+1'b1;
    end
    #10 $stop;
end

initial begin 
    reset = 1'b1;
    #40
    @(posedge clk) reset = 1'b0;
    
end
    
    
endmodule





module testbench_sub #(
    parameter V=2,
    parameter B=2,
    parameter NX=8,
    parameter NY=8,
    parameter C=1,
    parameter Fpay=32,
    parameter MUX_TYPE="ONE_HOT",
    parameter VC_REALLOCATION_TYPE="NONATOMIC",
    parameter COMBINATION_TYPE="COMB_NONSPEC",
    parameter FIRST_ARBITER_EXT_P_EN=1,
    parameter TOPOLOGY="MESH",
    parameter ROUTE_NAME="XY",
    parameter CONGESTION_INDEX=7,
    parameter ROUTE_SUBFUNC= "XY",
    parameter AVC_ATOMIC_EN= 0,
    parameter ADD_PIPREG_AFTER_CROSSBAR=0,
    parameter CVw=(C==0)? V : C * V,
    parameter [CVw-1:   0] CLASS_SETTING = 4'b1111, // shows how each class can use VCs   
    parameter [V-1  :   0] ESCAP_VC_MASK = 2'b10,  // mask scape vc, valid only for full adaptive 
    parameter SSA_EN=  "NO",//"YES", // "YES" , "NO"    
    parameter SWA_ARBITER_TYPE = "RRA",//"RRA","WRRA". SWA: Switch Allocator.  RRA: Round Robin Arbiter. WRRA Weighted Round Robin Arbiter          
    parameter WEIGHTw=6, // WRRA weights' max width
  
    parameter C0_p=100,
    parameter C1_p=0,
    parameter C2_p=0,
    parameter C3_p=0,
   // parameter TRAFFIC="HOTSPOT",
   parameter TRAFFIC="TRANSPOSE1",
   //parameter TRAFFIC="RANDOM", 
   // parameter TRAFFIC="CUSTOM",
    parameter HOTSPOT_PERCENTAGE=100,
    parameter HOTSPOT_NUM=1,
    parameter HOTSPOT_CORE_1=0,
    parameter HOTSPOT_CORE_2=52,
    parameter HOTSPOT_CORE_3=22,
    parameter HOTSPOT_CORE_4=54,
    parameter HOTSPOT_CORE_5=18,
    parameter HOTSPOT_SEND_EN=0,
    parameter MAX_PCK_NUM=256000,
    parameter MAX_SIM_CLKs=1000000,
    parameter MAX_PCK_SIZ=10,
    parameter TIMSTMP_FIFO_NUM=16,
    parameter ROUTE_TYPE = (ROUTE_NAME == "XY" || ROUTE_NAME == "TRANC_XY"   )?    "DETERMINISTIC" : 
                        (ROUTE_NAME == "DUATO" || ROUTE_NAME == "TRANC_DUATO" )?   "FULL_ADAPTIVE": "PAR_ADAPTIVE", 
    parameter DEBUG_EN=1,
    parameter AVG_LATENCY_METRIC= "HEAD_2_TAIL"
  
    

    
  
    )
    (
        reset ,
        clk,
        start,
        ratio,
        pck_size_in, 
        all_done
        
    );
       localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;
     
    
   
   
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
    
    function integer CORE_NUM;
        input integer x,y;
        begin
            CORE_NUM = ((y * NX) +  x);
        end
    endfunction
    
        

    localparam      Fw      =   2+V+Fpay,
                    NC     =	(TOPOLOGY=="RING" || TOPOLOGY=="LINE")? NX    :   NX*NY, //number of cores
                    Xw      =   log2(NX),
                    Yw      =   log2(NY) , 
                    Cw      =   (C>1)? log2(C): 1,
                    NCw     =   log2(NC),
                    RATIOw  =   log2(100),
                    NCV     =   NC  * V,
                    NCFw    =   NC  * Fw,
                    PCK_CNTw=   log2(MAX_PCK_NUM+1),
                    CLK_CNTw=   log2(MAX_SIM_CLKs+1),
                    PCK_SIZw=   log2(MAX_PCK_SIZ+1),
                    DSTw = log2(NC+1);
                    




    input                   reset ,clk,  start;
    input   [PCK_SIZw-1:0]  pck_size_in;
    input   [RATIOw-1  :0]  ratio; 
    output                  all_done;
    
    
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
    wire [NC-1      :   0]  hdr_flit_sent;
    wire [Xw-1      :   0]  dest_x                  [NC-1           :0];   
    wire [Yw-1      :   0]  dest_y                  [NC-1           :0];    
    wire [Cw-1      :   0]  pck_class_in            [NC-1           :0]; 
    wire [NC-1      :   0]  deafult_class_num;
    
   
       
    
    
 //   wire    [NC-1           :0] report;
    reg     [CLK_CNTw-1             :0] clk_counter;
    
    
  
    wire    [PCK_CNTw-1     :0] pck_counter     [NC-1        :0];
    wire    [NC-1           :0] noc_report;
    wire    [NC-1           :0] update;
    wire    [CLK_CNTw-1     :0] time_stamp      [NC-1           :0];
    wire    [DSTw-1         :0] distance        [NC-1           :0];    
    wire    [Cw-1           :0] msg_class       [NC-1           :0];    
    
    reg                         count_en;
  
    
    
    
    always @(posedge    clk or posedge reset) begin 
        if (reset) begin 
             count_en <=1'b0;
        end else begin 
            if(start) count_en <=1'b1;
            else if(noc_report) count_en <=1'b0;
        end 
    end//always
    

        
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
        .ESCAP_VC_MASK(ESCAP_VC_MASK), //
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw) 
               

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
     
    
        
        
      
    
always @ (posedge clk or posedge reset)begin 
    if          (reset  ) begin clk_counter  <= 0;  end
    else  begin 
        if  (count_en) clk_counter  <= clk_counter+1'b1;    
        
    end
end
    
    
    
    genvar i,x,y;
    
    
    generate 
    for (x=0;   x<NX; x=x+1) begin :x_loop1
        for (y=0;   y<NY;   y=y+1) begin: y_loop1
                localparam IP_NUM   =   CORE_NUM(x,y);  
            
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
                .MAX_RATIO(100),
                .TIMSTMP_FIFO_NUM(TIMSTMP_FIFO_NUM),
                .WEIGHTw(WEIGHTw)
            )
            the_traffic_gen
            (
  //input          
                .ratio (ratio),
                .avg_pck_size_in(pck_size_in),  
                .pck_size_in(pck_size_in),
                .current_x(x[Xw-1  :   0]),
                .current_y(y[Yw-1  :   0]),
                .dest_x(dest_x[IP_NUM]),
                .dest_y(dest_y[IP_NUM]), 
                .pck_class_in(pck_class_in[IP_NUM]),  
                .init_weight({{(WEIGHTw-1){1'b0}},1'b1}),
   
   //output
                .hdr_flit_sent(hdr_flit_sent[IP_NUM]),
              	.pck_number(pck_counter[IP_NUM]),
            	.reset(reset),
            	.clk(clk),
            	.start(start),
		.stop(1'b0),
            	.sent_done(),
            	.update(update[IP_NUM]),
            	.time_stamp_h2h(time_stamp[IP_NUM]),
            	.time_stamp_h2t(),
            	.distance(distance[IP_NUM]),
                .src_x(),
                .src_y(),
            	.pck_class_out(msg_class[IP_NUM]),
   //noc         	
            	.flit_out  (ni_flit_out [IP_NUM]),  
                .flit_out_wr (ni_flit_out_wr [IP_NUM]),  
                .credit_in  (ni_credit_in [IP_NUM]), 
                .flit_in (ni_flit_in [IP_NUM]),  
                .flit_in_wr (ni_flit_in_wr   [IP_NUM]),  
                .credit_out  (ni_credit_out [IP_NUM]),
            	.report (1'b0)
            );
            
                
                
           
            assign  ni_flit_in      [IP_NUM] =   flit_out_all    [(IP_NUM+1)*Fw-1    : IP_NUM*Fw];   
            assign  ni_flit_in_wr   [IP_NUM] =   flit_out_wr_all [IP_NUM]; 
            assign  credit_in_all   [(IP_NUM+1)*V-1 : IP_NUM*V]     =   ni_credit_out   [IP_NUM];  
            assign  flit_in_all     [(IP_NUM+1)*Fw-1    : IP_NUM*Fw]    =   ni_flit_out     [IP_NUM];
            assign  flit_in_wr_all  [IP_NUM] =   ni_flit_out_wr  [IP_NUM];
            assign  ni_credit_in    [IP_NUM] =   credit_out_all  [(IP_NUM+1)*V-1 : IP_NUM*V];
    
            assign  deafult_class_num[IP_NUM]= x[0] ^ y[0];
    
  

 pck_class_in_gen #(
    .NX(NX),
    .NY(NY),
    .TOPOLOGY(TOPOLOGY),
    .C(C),
    .C0_p(C0_p),
    .C1_p(C1_p),
    .C2_p(C2_p),
    .C3_p(C3_p),
    .MAX_PCK_NUM(MAX_PCK_NUM)
   )
   the_pck_class_in_gen
   (
    .en(hdr_flit_sent[IP_NUM]),
    .pck_class_in(pck_class_in[IP_NUM]),
    .core_num(IP_NUM[NCw-1  :   0] ),
    .pck_number(pck_counter[IP_NUM]),
    .reset(reset),
    .deafult_class_num(deafult_class_num[IP_NUM]),
    .clk(clk)
   );
   
   
   
  
   pck_dst_gen #(
    .NX(NX),
    .NY(NY),
    .TOPOLOGY(TOPOLOGY),
    .TRAFFIC(TRAFFIC),
    .MAX_PCK_NUM(MAX_PCK_NUM),
    .HOTSPOT_PERCENTAGE(HOTSPOT_PERCENTAGE),
    .HOTSPOT_NUM(HOTSPOT_NUM),
    .HOTSPOT_CORE_1(HOTSPOT_CORE_1),
    .HOTSPOT_CORE_2(HOTSPOT_CORE_2),
    .HOTSPOT_CORE_3(HOTSPOT_CORE_3),
    .HOTSPOT_CORE_4(HOTSPOT_CORE_4),
    .HOTSPOT_CORE_5(HOTSPOT_CORE_5),
    .HOTSPOT_SEND_EN(HOTSPOT_SEND_EN)
   )
   the_pck_dst_gen
   (
    .reset(reset),
    .clk(clk),
    .en(hdr_flit_sent[IP_NUM]),
    .core_num(IP_NUM[NCw-1  :   0]),
    .pck_number(pck_counter[IP_NUM]),
    .current_x(x[Xw-1  :   0]),
    .current_y(y[Yw-1  :   0]),
    .dest_x(dest_x[IP_NUM]),
    .dest_y(dest_y[IP_NUM]),
    .valid_dst()
   );
  
    
    
    
            //assign class_hdr  [IP_NUM]    =   8'HFF;  
            
            always @(posedge clk or posedge reset)begin 
                noc_analyze(    update      [IP_NUM],
                                    noc_report  [IP_NUM],
                                    time_stamp  [IP_NUM],
                                    {{(32-DSTw){1'b0}},distance        [IP_NUM]},
                                    msg_class   [IP_NUM]
                                    );
            end//always
            
            
                        
        end
    end
endgenerate

       
    reg[NC-1    :0] ratio_report;
  
   
    
    assign noc_report[0]= all_done;
    assign noc_report [NC-1  :   1]=0;
    generate 
    for(i=0; i< NC; i=i+1) begin : l2
        //for(i=3; i< 4; i=i+1) begin : ll
        always @(posedge clk or posedge reset ) begin
        
          injection_ratio(
                
                all_done,
                pck_counter[i],
                clk_counter,
                ratio_report[i]
                
                //noc_report_dela[i]
           );
        
        end
    end
    endgenerate
    
   
    
   
    
    
    integer fp;
    
    initial begin
        `ifndef verilator       
        fp = $fopen("Result.txt");
        `else
        fp = $fopen("Result.txt","w");
        `endif  
        $fwrite(fp,"TRAFFIC is   =%s\n",TRAFFIC);
        $fwrite(fp,"Packet size in flit=%d\n ",pck_size_in);
        //$fwrite(fp,"ROUTE_ALGRMT  =%s",ROUTE_ALGRMT);
        $fwrite(fp,"VC_REALLOCATION_TYPE = %s\n",VC_REALLOCATION_TYPE);
        $fwrite(fp,"COMBINATION_TYPE    = %s\n",COMBINATION_TYPE);
        $fwrite(fp,"VC_NUM_PER_PORT = %d\n",V);
        $fwrite(fp,"BUFFER_NUM_PER_VC = %d\n",B);
        
        $fwrite(fp,"\n\nRatio,pck_num,avg_latency_per_hop,avg_latency,max_latency_per_hop,total_pck_num_per_class ,avg_latency_per_hop_per_class,avg_latency_per_class,max_latency_per_hop_per_class\n");
   end
        
        
    integer total_clk;
    real total_pck;
    integer total_router;
    real      ratio_avg;
        
task injection_ratio ;
        input       inject_done;
        input integer   packet_num;
        input integer   clk_count;
        input inject_report_in;
    
    
    begin
    //@(posedge clk)  
        if (reset) begin 
            total_clk=0;
            total_pck=0;
            total_router=0;
        end else begin 
            if(inject_done) begin 
                if(packet_num>0) begin 
                    total_clk   =   total_clk   +   clk_count;
                    total_pck   =   total_pck   +   packet_num;
                    total_router    = total_router +1'b1;
                    ratio_avg <= (total_clk>0)? (total_pck* pck_size_in*100)/total_clk:0;
                end
            end
            if(inject_report_in) begin 
                    
    		    $display("simulation clk number=%d",clk_counter);
                    $display("Injection ratio is =%f",ratio_avg);
                    $display("total_pck      =%f",total_pck);            
                    $display("TRAFFIC is   =%s",TRAFFIC);
                    $display("Packet size in flit=%d ",pck_size_in);
                    $display("total_latency_accum=%d ",total_clk);
                    $display("ROUTE_NAME    =%s",ROUTE_NAME);
                    $display("ROUTE_TYPE =%s",ROUTE_TYPE);                  
                    $display("VC_REALLOCATION_TYPE = %s",VC_REALLOCATION_TYPE);
                    $display("COMBINATION_TYPE  = %s",COMBINATION_TYPE);
                    $display("VC_NUM_PER_PORT = %d",V);
                    $display("BUFFER_NUM_PER_VC = %d",B);
                    
                    $fwrite(fp,"\n%f,",ratio_avg);
                            
            end
        end//else
    end
        
    endtask

 

/* 
always @(posedge clk or posedge reset) begin 
    if (reset)  noc_report <=0;
    else            noc_report <={ {(NC-1){1'b0}},report[0]}; // print just one report
end
*/





    integer             total_pck_num;
    real                avg_latency_per_hop,sum,sum2,tmp1,tmp2,avg_latency;
    real                max_latency_per_hop;
    integer             total_pck_num_per_class         [C-1    :   0];
    real                avg_latency_per_hop_per_class [C-1  :   0];
    real                avg_latency_per_class           [C-1    :   0];
    real                max_latency_per_hop_per_class [C-1  :   0];
    real                sum_per_class [C-1  :   0];
    real                sum2_per_class[C-1  :   0];
    
    
    integer cc;
    task noc_analyze; 
        input               update_i;
        input           Report;
        input integer   clk_num;
        input integer   offset;
        input integer  class_num;
    
        begin
    //@(posedge clk)  
        if (reset) begin 
            total_pck_num       =0;
            sum                     =0;
            sum2                    =0;
            max_latency_per_hop=0;
            for(cc=0;cc<C;cc=cc+1'b1)begin 
                total_pck_num_per_class[cc]=0;
                sum_per_class[cc]=0;
                sum2_per_class[cc]=0;
                max_latency_per_hop_per_class[cc]=0;
                
            end//for
        end else begin 
            //measure the distance 
            if(update_i)    begin 
                tmp1                = (offset)? clk_num:0;
                tmp2                = (offset)? tmp1/offset: 0;
                total_pck_num   =total_pck_num+1;
                sum                 = sum + tmp2;
                sum_per_class[class_num] = sum_per_class[class_num] +tmp2;
                sum2                = sum2 + tmp1;
                sum2_per_class[class_num] = sum2_per_class[class_num] +tmp1;
                max_latency_per_hop = (tmp2> max_latency_per_hop)? tmp2 : max_latency_per_hop;
                total_pck_num_per_class[class_num]= total_pck_num_per_class[class_num]+1'b1;
                max_latency_per_hop_per_class[class_num]=(tmp2> max_latency_per_hop_per_class[class_num])? tmp2 : max_latency_per_hop_per_class[class_num];
            //  $fwrite(fp,"%f  \t : offset=%d  clk_num=%d\n", tmp2,offset,clk_num);
                if(total_pck_num>0 && sum) begin 
                    avg_latency_per_hop <= sum/total_pck_num;
                    avg_latency           <= sum2/total_pck_num;
                end
                if(total_pck_num_per_class[class_num]>0 && sum_per_class[class_num]) begin 
                    avg_latency_per_hop_per_class[class_num] <= sum_per_class[class_num]/total_pck_num_per_class[class_num];
                    avg_latency_per_class[class_num]              <= sum2_per_class[class_num]/total_pck_num_per_class[class_num];
                end
            end
            if(Report) begin 
            //  $display("%d :TOPOLOGY =%s\n ROUTE_ALGRMT =%s\n NEW_VC_ALOC_MTD =%s\n VC_NUM_PER_PORT =%d\n BUFFER_NUM_PER_VC =%d\n CONGESTION_ANLZ_LEVEL=%d\n",$time,TOPOLOGY,ROUTE_ALGRMT,NEW_VC_ALOC_MTD,VC_NUM_PER_PORT,BUFFER_NUM_PER_VC,CONGESTION_ANLZ_LEVEL);   
                $display(" Total number of packet = %d \n avrage latency per hop=%f \n avg_latency=%f\n",total_pck_num,avg_latency_per_hop,avg_latency);
                $display(" max_latency_per_hop= %d ",max_latency_per_hop); 
                $fwrite(fp,"%d,%f,%f,%f,",total_pck_num,avg_latency_per_hop,avg_latency,max_latency_per_hop);
                for(cc=0;cc<C;cc=cc+1'b1)begin 
                    $display ("class\t :\t %d  ",cc);
                    $display ("total_pck_num_per_class = %d",total_pck_num_per_class[cc]);
                    $display ("avg_latency_per_hop_per_class=%f",avg_latency_per_hop_per_class[cc]);
                    $display ("avg_latency_per_class=%f",avg_latency_per_class[cc]);    
                    $display ("max_latency_per_hop_per_class=%f",max_latency_per_hop_per_class[cc]);
                    $fwrite(fp,"%d,%f,%f,%f,",total_pck_num_per_class[cc],avg_latency_per_hop_per_class[cc],avg_latency_per_class[cc],max_latency_per_hop_per_class[cc]);
                end
                
                
                
            end
        end
    end
    endtask

    
    reg all_done_reg;
    wire all_done_in;
    assign all_done_in = (clk_counter > MAX_SIM_CLKs) || ( total_pck_num >  MAX_PCK_NUM );
    assign all_done = all_done_in & ~ all_done_reg;
    always @(posedge clk or posedge reset)begin 
        if(reset) begin 
            all_done_reg <= 1'b0;
            ratio_report    <=0;
        end  else  begin 
            all_done_reg <= all_done_in;
            ratio_report[0]    <=  all_done;
        end
    end    
 

   


endmodule
 // synthesis translate_on


