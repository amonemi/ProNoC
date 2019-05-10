 // synthesis translate_off
`timescale   1ns/1ns


module testbench_modelsim;

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




    testbench_sub 
    uut (
        .reset  (reset) ,
        .clk        (clk),
        .start  (start),
        .ratio   (ratio), 
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
  
    ratio =90;
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
    parameter V=1,
    parameter B=4,
    parameter T1=2,
    parameter T2=2,
    parameter T3=2,
    parameter C=1,
    parameter Fpay=32,
    parameter MUX_TYPE="ONE_HOT",
    parameter VC_REALLOCATION_TYPE="NONATOMIC",
    parameter COMBINATION_TYPE="COMB_NONSPEC",
    parameter FIRST_ARBITER_EXT_P_EN=1,
   // parameter TOPOLOGY="LINE",
  //  parameter TOPOLOGY="FATTREE",
 parameter TOPOLOGY="TREE",
    // parameter TOPOLOGY="MESH",
   //  parameter ROUTE_NAME="XY",
// parameter ROUTE_NAME="DUATO",
    // parameter  ROUTE_NAME= "NCA_RND_UP",
    parameter  ROUTE_NAME= "NCA_STRAIGHT_UP",
    parameter CONGESTION_INDEX=7,
    
    parameter AVC_ATOMIC_EN= 0,
    parameter ADD_PIPREG_AFTER_CROSSBAR=0,
    parameter CVw=(C==0)? V : C * V,
    parameter [CVw-1:   0] CLASS_SETTING = 4'b1111, // shows how each class can use VCs   
    parameter [V-1  :   0] ESCAP_VC_MASK = 2'b10,  // mask scape vc, valid only for full adaptive 
    parameter SSA_EN=  "NO",//"YES", // "YES" , "NO"    
    parameter SWA_ARBITER_TYPE = "WRRA",//"RRA","WRRA". SWA: Switch Allocator.  RRA: Round Robin Arbiter. WRRA Weighted Round Robin Arbiter          
    parameter WEIGHTw=7, // WRRA weights' max width
    //hardware minimum packet size support
    parameter MIN_PCK_SIZE=2,  
  
    parameter C0_p=100,
    parameter C1_p=0,
    parameter C2_p=0,
    parameter C3_p=0,
   // parameter TRAFFIC="HOTSPOT",   
 // parameter TRAFFIC="TRANSPOSE1",
   parameter TRAFFIC="RANDOM", 
 //  parameter TRAFFIC="CUSTOM",
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
   
    parameter TIMSTMP_FIFO_NUM=16,
  
    parameter DEBUG_EN=1,
    parameter AVG_LATENCY_METRIC= "HEAD_2_TAIL",
    //simulation min and max packet size. The injeced packet take a size randomly selected between min and max
    parameter MIN_PACKET_SIZE=3,
    parameter MAX_PACKET_SIZE=3
  
    )
    (
        reset ,
        clk,
        start,
        ratio,        
        all_done
        
    );
           
    
    `define INCLUDE_TOPOLOGY_LOCALPARAM
   `include "../src_noc/topology_localparam.v"
  

   
    localparam      Fw      =   2+V+Fpay,
                     /* verilator lint_off WIDTH */
                    
                    NEw=log2(NE),
                    DISTw = (TOPOLOGY=="FATTREE" || TOPOLOGY == "TREE") ? log2(2*L+1): log2(NR+1),
                    /* verilator lint_on WIDTH */
                    
                    Cw      =   (C>1)? log2(C): 1,
                   // NEw     =   log2(NE),
                    RATIOw  =   log2(100),
                    NEV     =   NE  * V,
                    NEFw    =   NE  * Fw,
                    PCK_CNTw=   log2(MAX_PCK_NUM+1),
                    CLK_CNTw=   log2(MAX_SIM_CLKs+1),
                    PCK_SIZw=   log2(MAX_PACKET_SIZE+1),
                    AVG_PCK_SIZ = (MAX_PACKET_SIZE + MIN_PACKET_SIZE)/2 ;
                   
                    
  
    input                   reset ,clk,  start;
    input   [RATIOw-1  :0]  ratio; 
    output                  all_done;
    
    
    wire [Fw-1      :   0]  ni_flit_out                 [NE-1           :0];   
    wire [NE-1      :   0]  ni_flit_out_wr; 
    wire [V-1       :   0]  ni_credit_in                [NE-1           :0];
    wire [Fw-1      :   0]  ni_flit_in                  [NE-1           :0];   
    wire [NE-1      :   0]  ni_flit_in_wr;  
    wire [V-1       :   0]  ni_credit_out               [NE-1           :0];    
    wire [NEFw-1    :   0]  flit_out_all;
    wire [NE-1      :   0]  flit_out_wr_all;
    wire [NEV-1     :   0]  credit_in_all;
    wire [NEFw-1    :   0]  flit_in_all;
    wire [NE-1      :   0]  flit_in_wr_all;  
    wire [NEV-1     :   0]  credit_out_all;
    wire [NE-1      :   0]  hdr_flit_sent;
    wire [EAw-1     :   0]  dest_e_addr                  [NE-1           :0];   
    wire [Cw-1      :   0]  pck_class_in            [NE-1           :0]; 
  
    
    wire   [PCK_SIZw-1:0]  pck_size_in [NE-1           :0]; 
       
    
    
 //   wire    [NE-1           :0] report;
    reg     [CLK_CNTw-1             :0] clk_counter;
    
    
  
    wire    [PCK_CNTw-1     :0] pck_counter     [NE-1        :0];
    wire    [NE-1           :0] noc_report;
    wire    [NE-1           :0] update;
    wire    [CLK_CNTw-1     :0] time_stamp      [NE-1           :0];
    wire    [DISTw-1         :0] distance        [NE-1           :0];    
    wire    [Cw-1           :0] msg_class       [NE-1           :0];    
    
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
        .T1(T1),
        .T2(T2),
	.T3(T3),
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
        .AVC_ATOMIC_EN(AVC_ATOMIC_EN),
        .ADD_PIPREG_AFTER_CROSSBAR(ADD_PIPREG_AFTER_CROSSBAR),
        .CVw(CVw),
        .CLASS_SETTING(CLASS_SETTING), // shows how each class can use VCs   
        .ESCAP_VC_MASK(ESCAP_VC_MASK), //
        .SSA_EN(SSA_EN),
        .SWA_ARBITER_TYPE(SWA_ARBITER_TYPE),
        .WEIGHTw(WEIGHTw),
        .MIN_PCK_SIZE(MIN_PCK_SIZE)
               

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
    for(i=0; i< NE; i=i+1) begin : endpoints
        //connected router encoded address
        localparam CURRENTR=  i/T3;
        localparam CURRENTX= (TOPOLOGY == "FATTREE" || TOPOLOGY == "TREE")?  addrencode(i/K,K,L,Kw) : CURRENTR%T1;
        localparam CURRENTY= (TOPOLOGY == "FATTREE" || TOPOLOGY == "TREE")?  0 : CURRENTR/T1;
        localparam [RAw-1 : 0] CURRENT_ADDR =  (CURRENTY<<NXw) + CURRENTX; 
        //Endpoint encoded address
        localparam ENDPL= (TOPOLOGY == "FATTREE" || TOPOLOGY == "TREE")? 0 :(T3>1)? i%T3: 0;
        localparam ENDPX= (TOPOLOGY == "FATTREE" || TOPOLOGY == "TREE")?  addrencode(i,K,L,Kw) : CURRENTX;
        localparam ENDPY= (TOPOLOGY == "FATTREE" || TOPOLOGY == "TREE")? 0 : CURRENTY;    
        localparam [EAw-1 : 0] ENDP_ADRR = (ENDPL<<(NXw+NYw)) + (ENDPY<<NXw) + ENDPX;
       
            
        traffic_gen #(
            .V(V),
            .B(B),
            .T1(T1),
            .T2(T2),
            .T3(T3),
            .Fpay(Fpay),
            .C(C),
            .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
            .TOPOLOGY(TOPOLOGY),
            .ROUTE_NAME(ROUTE_NAME),
            .MAX_PCK_NUM(MAX_PCK_NUM),
            .MAX_SIM_CLKs(MAX_SIM_CLKs),
            .MAX_PCK_SIZ(MAX_PACKET_SIZE),
            .MAX_RATIO(100),
            .TIMSTMP_FIFO_NUM(TIMSTMP_FIFO_NUM),
            .WEIGHTw(WEIGHTw),
            .MIN_PCK_SIZE(MIN_PCK_SIZE)
        )
        the_traffic_gen
        (
       
            .ratio (ratio),
            .avg_pck_size_in(AVG_PCK_SIZ[PCK_SIZw-1  :0] ),  
            .pck_size_in(pck_size_in[i]),
            .current_r_addr(CURRENT_ADDR),
            .current_e_addr(ENDP_ADRR),
            .dest_e_addr(dest_e_addr[i]),
            .pck_class_in(pck_class_in[i]),  
            .init_weight({{(WEIGHTw-1){1'b0}},1'b1}),
            .hdr_flit_sent(hdr_flit_sent[i]),
            .pck_number(pck_counter[i]),
            .reset(reset),
            .clk(clk),
            .start(start),
            .stop(1'b0),
            .sent_done(),
            .update(update[i]),
            .time_stamp_h2h(time_stamp[i]),
            .time_stamp_h2t(),
            .distance(distance[i]),
            .src_e_addr( ),
            .pck_class_out(msg_class[i]),
            .flit_out  (ni_flit_out [i]),  
            .flit_out_wr (ni_flit_out_wr [i]),  
            .credit_in  (ni_credit_in [i]), 
            .flit_in (ni_flit_in [i]),  
            .flit_in_wr (ni_flit_in_wr   [i]),  
            .credit_out  (ni_credit_out [i]),
            .report (1'b0)
    );
            
                
                
           
        assign  ni_flit_in      [i] =   flit_out_all    [(i+1)*Fw-1    : i*Fw];   
        assign  ni_flit_in_wr   [i] =   flit_out_wr_all [i]; 
        assign  credit_in_all   [(i+1)*V-1 : i*V]     =   ni_credit_out   [i];  
        assign  flit_in_all     [(i+1)*Fw-1    : i*Fw]    =   ni_flit_out     [i];
        assign  flit_in_wr_all  [i] =   ni_flit_out_wr  [i];
        assign  ni_credit_in    [i] =   credit_out_all  [(i+1)*V-1 : i*V];    
        
  

         pck_class_in_gen #(
            .NE(NE),
            .C(C),
            .C0_p(C0_p),
            .C1_p(C1_p),
            .C2_p(C2_p),
            .C3_p(C3_p),
            .MAX_PCK_NUM(MAX_PCK_NUM)
           )
           the_pck_class_in_gen
           (
            .en(hdr_flit_sent[i]),
            .pck_class_in(pck_class_in[i]),
            .core_num(i[NEw-1  :   0] ),
            .pck_number(pck_counter[i]),
            .reset(reset),
            .clk(clk)
           );
   
   
   
  
       pck_dst_gen #(
        .T1(T1),
        .T2(T2),
        .T3(T3),
        .EAw(EAw),
        .NE(NE),
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
        .en(hdr_flit_sent[i]),
        .core_num(i[NEw-1  :   0]),
        .pck_number(pck_counter[i]),
        .current_e_addr(ENDP_ADRR),
        .dest_e_addr(dest_e_addr[i]),
        .valid_dst()
       );
       
       pck_size_gen #(
         .MIN(MIN_PACKET_SIZE),
         .MAX(MAX_PACKET_SIZE)
       )
       the_pck_siz_gen
       (
        .reset(reset),
        .clk(clk),
        .en(hdr_flit_sent[i]),
        .pck_size( pck_size_in[i]) 
       );
  
    
            //assign class_hdr  [i]    =   8'HFF;  
            
            always @(posedge clk or posedge reset)begin 
                            
                noc_analyze(    update      [i],
                                    noc_report  [i],
                                    time_stamp  [i],
                                    {{(32-DISTw){1'b0}},distance        [i]},
                                    msg_class   [i],
                                    ni_flit_in_wr   [i]
                                    
                                    );
            end//always
            
            
                        
        end
   
   
endgenerate

       
    reg[NE-1    :0] ratio_report;
  
   
    
    assign noc_report[0]= all_done;
    assign noc_report [NE-1  :   1]=0;
    generate 
    for(i=0; i< NE; i=i+1) begin : l2
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
                    
                end
            end
            if(inject_report_in) begin 
                    
    		    $display("simulation clk number=%d",clk_counter);
                    
                    $display("total_pck injected      =%f",total_pck);            
                    $display("TRAFFIC is   =%s",TRAFFIC);
                    $display("Min Packet size in flit=%d ",MIN_PACKET_SIZE);
                    $display("Max Packet size in flit=%d ",MAX_PACKET_SIZE);
                    $display("total_latency_accum=%d ",total_clk);
                    $display("ROUTE_NAME    =%s",ROUTE_NAME);
                    $display("ROUTE_TYPE =%s",ROUTE_TYPE);                  
                    $display("VC_REALLOCATION_TYPE = %s",VC_REALLOCATION_TYPE);
                    $display("COMBINATION_TYPE  = %s",COMBINATION_TYPE);
                    $display("VC_NUM_PER_PORT = %d",V);
                    $display("BUFFER_NUM_PER_VC = %d",B);
                    
                    
                            
            end
        end//else
    end
        
    endtask

 

/* 
always @(posedge clk or posedge reset) begin 
    if (reset)  noc_report <=0;
    else            noc_report <={ {(NE-1){1'b0}},report[0]}; // print just one report
end
*/





    integer             total_pck_num,total_flit_num;
    real                avg_latency_per_hop,sum,sum2,tmp1,tmp2,avg_latency;
    real                max_latency_per_hop;
    integer             total_pck_num_per_class         [C-1    :   0];
    real                avg_latency_per_hop_per_class [C-1  :   0];
    real                avg_latency_per_class           [C-1    :   0];
    real                max_latency_per_hop_per_class [C-1  :   0];
    real                sum_per_class [C-1  :   0];
    real                sum2_per_class[C-1  :   0];
    real                throughput_avg;
    
    integer cc;
    task noc_analyze; 
        input               update_i;
        input           Report;
        input integer   clk_num;
        input integer   offset;
        input integer  class_num;
        input ni_flit_in_wr;
    
        begin
    //@(posedge clk)  
        if (reset) begin 
            total_flit_num=0;
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
            if(ni_flit_in_wr) total_flit_num = total_flit_num+1;
            
            if(update_i)    begin 
              //  $display("offset=%u",offset);
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
                throughput_avg = (clk_counter)? (total_flit_num*100)/clk_counter:0;
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
               
                $display(" Total number of recived flits  = %d \n average throughput=%f \n" ,total_flit_num,throughput_avg);
                $display(" Total number of recived packets  = %d \n avrage latency per hop=%f \n avg_latency=%f\n",total_pck_num,avg_latency_per_hop,avg_latency);
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


