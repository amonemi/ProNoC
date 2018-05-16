`timescale     1ns/1ps

module pseudo_hotspot_no_core #(
        parameter MAX_RND                    = 10,
        parameter MAX_CORE                 = 10,
        parameter MAX_NUM                 = 10,
        parameter MAX_RND_WIDTH         =log2(MAX_RND+1), 
        parameter HOTSPOT_PERCENTAGE    = 8,    //maximum 20%
        parameter HOTSPOT_NUM            =    5, //maximum 5
        parameter [MAX_RND_WIDTH-1    :0]     HOTSPOT_CORE_1        =    2,
        parameter [MAX_RND_WIDTH-1    :0]    HOTSPOT_CORE_2        =    3,
        parameter [MAX_RND_WIDTH-1    :0]    HOTSPOT_CORE_3        =    4,
        parameter [MAX_RND_WIDTH-1    :0]    HOTSPOT_CORE_4        =    5,
        parameter [MAX_RND_WIDTH-1    :0]    HOTSPOT_CORE_5        =    6,
        parameter HOTSPOT_SEND_EN =0,

        
        parameter MAX_CORE_WIDTH         =log2(MAX_CORE+1), 
        parameter MAX_NUM_WIDTH         =log2(MAX_NUM+1) 

)(
    
    input    [MAX_CORE_WIDTH-1    :    0]    core,
    input    [MAX_NUM_WIDTH-1    :    0]    num,
    output reg [MAX_RND_WIDTH-1    :    0]    rnd,
    input                                    rnd_en,
    input                                 reset,
    input                                 clk
    

);

    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end        
      end   
    endfunction // log2 
    
    localparam HOTSPOT_RND    =    log2(100);
    wire     [MAX_RND_WIDTH-1        :    0]    uniform_rnd;
    wire     [HOTSPOT_RND-1            :    0]    hotspot_rnd;
    
    //uniform traffic generator
    pseudo_random_no_core #(
        .MAX_RND        (MAX_RND    ),
        .MAX_CORE    (MAX_CORE),
        .MAX_NUM        (MAX_NUM)
    )uniform
    (
    .core        (core),
    .num        (num),
    .rnd        (uniform_rnd),
    .rnd_en    (rnd_en),
    .reset    (reset),
    .clk        (clk)
    );

    // generate a random num between 0 to 100
    pseudo_random #(
        .MAX_RND        (100),
        .MAX_CORE    (MAX_CORE),
        .MAX_NUM        (MAX_NUM)
    )hotspot_rnd_gen
    (
        .core        (core),
        .num        (num),
        .rnd        (hotspot_rnd),
        .rnd_en    (rnd_en),
        .reset    (reset),
        .clk        (clk)
    );
    
    localparam  MAX_PERCENT =100/HOTSPOT_NUM,
                MAX1 = 1 * MAX_PERCENT,
                MAX2 = 2 * MAX_PERCENT,
                MAX3 = 3 * MAX_PERCENT,
                MAX4 = 4 * MAX_PERCENT;
    
    
    always @(*) begin 
       
        if(hotspot_rnd < HOTSPOT_PERCENTAGE    && core!=HOTSPOT_CORE_1)    rnd = HOTSPOT_CORE_1;
        else if((HOTSPOT_NUM > 1) && (hotspot_rnd >= MAX1)    && (hotspot_rnd < (MAX1+HOTSPOT_PERCENTAGE)) && core!=HOTSPOT_CORE_2 )  rnd = HOTSPOT_CORE_2;
        else if((HOTSPOT_NUM > 2) && (hotspot_rnd >= MAX2)    && (hotspot_rnd < (MAX2+HOTSPOT_PERCENTAGE)) && core!=HOTSPOT_CORE_3 )  rnd = HOTSPOT_CORE_3;
        else if((HOTSPOT_NUM > 3) && (hotspot_rnd >= MAX3)    && (hotspot_rnd < (MAX3+HOTSPOT_PERCENTAGE)) && core!=HOTSPOT_CORE_4 )  rnd = HOTSPOT_CORE_4;
        else if((HOTSPOT_NUM > 4) && (hotspot_rnd >= MAX4)    && (hotspot_rnd < (MAX4+HOTSPOT_PERCENTAGE)) && core!=HOTSPOT_CORE_5 )  rnd = HOTSPOT_CORE_5;
        else rnd = uniform_rnd;

        if(HOTSPOT_SEND_EN==0)begin 
            if(core ==HOTSPOT_CORE_1) rnd = core;
            else if((HOTSPOT_NUM > 1)   && (core ==HOTSPOT_CORE_2)) rnd = core;
            else if((HOTSPOT_NUM > 2)   && (core ==HOTSPOT_CORE_3)) rnd = core;
            else if((HOTSPOT_NUM > 3)   && (core ==HOTSPOT_CORE_4)) rnd = core;
            else if((HOTSPOT_NUM > 4)   && (core ==HOTSPOT_CORE_5)) rnd = core;
       end



    end

endmodule

module pseudo_hotspot #(
        parameter MAX_RND                    = 10,
        parameter MAX_CORE                 = 10,
        parameter MAX_NUM                 = 10,
        parameter MAX_RND_WIDTH         =log2(MAX_RND+1), 
        parameter HOTSPOT_PERCENTAGE    = 8,    //maximum 20%
        parameter HOTSPOT_NUM            =    5, //maximum 5
        parameter [MAX_RND_WIDTH-1    :0] HOTSPOT_CORE_1        =    2,
        parameter [MAX_RND_WIDTH-1    :0]    HOTSPOT_CORE_2        =    3,
        parameter [MAX_RND_WIDTH-1    :0]    HOTSPOT_CORE_3        =    4,
        parameter [MAX_RND_WIDTH-1    :0]    HOTSPOT_CORE_4        =    5,
        parameter [MAX_RND_WIDTH-1    :0]    HOTSPOT_CORE_5        =    6,
        parameter HOTSPOT_SEND_EN =0,

        
        parameter MAX_CORE_WIDTH         =log2(MAX_CORE+1), 
        parameter MAX_NUM_WIDTH         =log2(MAX_NUM+1) 

)(
    
    input    [MAX_CORE_WIDTH-1    :    0]    core,
    input    [MAX_NUM_WIDTH-1    :    0]    num,
    output reg [MAX_RND_WIDTH-1    :    0]    rnd,
    input                                    rnd_en,
    input                                 reset,
    input                                 clk
    

);
    
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 
    
    localparam HOTSPOT_RND    =    log2(100);
    wire     [MAX_RND_WIDTH-1        :    0]    uniform_rnd;
    wire     [HOTSPOT_RND-1            :    0]    hotspot_rnd;
    
    //uniform traffic generator
    pseudo_random #(
        .MAX_RND        (MAX_RND    ),
        .MAX_CORE    (MAX_CORE),
        .MAX_NUM        (MAX_NUM)
    )uniform
    (
    .core        (core),
    .num        (num),
    .rnd        (uniform_rnd),
    .rnd_en    (rnd_en),
    .reset    (reset),
    .clk        (clk)
    );

    // generate a random num between 0 to 100
    pseudo_random #(
        .MAX_RND        (100),
        .MAX_CORE    (MAX_CORE),
        .MAX_NUM        (MAX_NUM)
    )hotspot_rnd_gen
    (
        .core        (core),
        .num        (num),
        .rnd        (hotspot_rnd),
        .rnd_en    (rnd_en),
        .reset    (reset),
        .clk        (clk)
    );
    
      localparam  MAX_PERCENT =100/HOTSPOT_NUM,
                MAX1 = 1 * MAX_PERCENT,
                MAX2 = 2 * MAX_PERCENT,
                MAX3 = 3 * MAX_PERCENT,
                MAX4 = 4 * MAX_PERCENT;
    
    always @(*) begin 
         if(hotspot_rnd < HOTSPOT_PERCENTAGE    && core!=HOTSPOT_CORE_1)    rnd = HOTSPOT_CORE_1;
        else if((HOTSPOT_NUM > 1) && (hotspot_rnd >= MAX1)    && (hotspot_rnd < (MAX1+HOTSPOT_PERCENTAGE)) && core!=HOTSPOT_CORE_2 )  rnd = HOTSPOT_CORE_2;
        else if((HOTSPOT_NUM > 2) && (hotspot_rnd >= MAX2)    && (hotspot_rnd < (MAX2+HOTSPOT_PERCENTAGE)) && core!=HOTSPOT_CORE_3 )  rnd = HOTSPOT_CORE_3;
        else if((HOTSPOT_NUM > 3) && (hotspot_rnd >= MAX3)    && (hotspot_rnd < (MAX3+HOTSPOT_PERCENTAGE)) && core!=HOTSPOT_CORE_4 )  rnd = HOTSPOT_CORE_4;
        else if((HOTSPOT_NUM > 4) && (hotspot_rnd >= MAX4)    && (hotspot_rnd < (MAX4+HOTSPOT_PERCENTAGE)) && core!=HOTSPOT_CORE_5 )  rnd = HOTSPOT_CORE_5;
        else rnd = uniform_rnd;

        if(HOTSPOT_SEND_EN==0)begin 
            if(core ==HOTSPOT_CORE_1) rnd = core;
            else if((HOTSPOT_NUM > 1)   && (core ==HOTSPOT_CORE_2)) rnd = core;
            else if((HOTSPOT_NUM > 2)   && (core ==HOTSPOT_CORE_3)) rnd = core;
            else if((HOTSPOT_NUM > 3)   && (core ==HOTSPOT_CORE_4)) rnd = core;
            else if((HOTSPOT_NUM > 4)   && (core ==HOTSPOT_CORE_5)) rnd = core;
       end
    end

endmodule




module pseudo_random #(
        parameter MAX_RND                = 10,
        parameter MAX_CORE             = 10,
        parameter MAX_NUM             = 10,
        parameter MAX_RND_WIDTH     =log2(MAX_RND+1), 
        parameter MAX_CORE_WIDTH     =log2(MAX_CORE+1), 
        parameter MAX_NUM_WIDTH     =log2(MAX_NUM+1) 

)(
    
    input    [MAX_CORE_WIDTH-1    :    0]    core,
    input    [MAX_NUM_WIDTH-1    :    0]    num,
    output[MAX_RND_WIDTH-1    :    0]    rnd,
    input                                    rnd_en,
    input                                 reset,
    input                                 clk
    

);

    function integer log2;
      input integer number;    begin    
         log2=0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end    
      end    
    endfunction // log2 
    //`define verilator

     `ifdef verilator

    wire[MAX_RND_WIDTH-1    :    0]    rnd1,rnd2,rnd3;
    wire[MAX_NUM_WIDTH-1    :    0]    num2,num3;
    wire[MAX_CORE_WIDTH-1:    0]    core2,core3;
    wire valid1,valid2;
    assign num2 = num+num;
    assign num3 = num+rnd2;
    assign core2= core + core;
    assign core3= core+rnd1;
    


    
    pseudo_random_gen #(
            .MAX_RND        (MAX_RND),
            .MAX_CORE    (MAX_CORE),
            .MAX_NUM     (MAX_NUM )
    )
    pseudo_random_gen1
    (
        .core        (core),
        .num        (num),
        .rnd        (rnd1),
        .valid     (valid1),
        .rnd_en    (rnd_en),
        .reset    (reset),
        .clk        (clk    )
    );
    
    pseudo_random_gen #(
            .MAX_RND        (MAX_RND),
            .MAX_CORE    (MAX_CORE),
            .MAX_NUM     (MAX_NUM )
    )
    pseudo_random_gen2
    (
        .core    (core2),
        .num    (num2),
        .rnd    (rnd2),
        .valid (valid2),
        .rnd_en    (rnd_en),
        .reset    (reset),
        .clk        (clk    )
    );
    
    pseudo_random_gen #(
            .MAX_RND        (MAX_RND),
            .MAX_CORE    (MAX_CORE),
            .MAX_NUM     (MAX_NUM )
    )
    pseudo_random_gen3
    (
        .core    (core3),
        .num    (num3),
        .rnd    (rnd3),
        .valid (),
        .rnd_en    (rnd_en),
        .reset    (reset),
        .clk        (clk    )
    );

    assign rnd =    (valid1)? rnd1 :
                        (valid2)? rnd2: rnd3;

    `else 
    reg [MAX_RND_WIDTH-1    :    0]    rnd_reg;
    always @(posedge clk ) begin 
            rnd_reg =     $urandom_range(0,MAX_RND);
            //rnd_reg =     $random % (MAX_RND+1);
    end

    assign rnd =     rnd_reg;
    
    
    `endif

endmodule

module pseudo_random_gen #(
        parameter MAX_RND                = 10,
        parameter MAX_CORE             = 10,
        parameter MAX_NUM             = 10,
        parameter MAX_RND_WIDTH     =log2(MAX_RND+1), 
        parameter MAX_CORE_WIDTH     =log2(MAX_CORE+1), 
        parameter MAX_NUM_WIDTH     =log2(MAX_NUM+1) 

)(
    
    input    [MAX_CORE_WIDTH-1    :    0]    core,
    input    [MAX_NUM_WIDTH-1    :    0]    num,
    output[MAX_RND_WIDTH-1    :    0]    rnd,
    output                                valid,
    input                                    rnd_en,
    input                                 reset,
    input                                 clk

);
    
  
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 

localparam S_SEED_WIDTH    =    MAX_CORE_WIDTH + MAX_NUM_WIDTH;
localparam S_SEED_REPEAT=    24 / S_SEED_WIDTH;
localparam LST_SEED_WIDTH = 24 - S_SEED_REPEAT*S_SEED_WIDTH;


wire [23                    :    0] seed;
wire [S_SEED_WIDTH-1    :    0] s_seed;
wire  [15                    :    0] rnd_16_bit;
wire [MAX_RND_WIDTH-1:    0]    rnd_max_width;

//wire [7    :    0] ptable1[23    :0 ]= '{183,11,13,87,54,196,233,32,120,184,63,53,135,177,7,211,253,113,87,164,31,101,243,17};
/*
wire [7    :    0] ptable1[23    :0 ];
assign     {ptable1[23],ptable1[22],ptable1[21],ptable1[20],ptable1[19],ptable1[18],ptable1[17],ptable1[16],
              ptable1[15],ptable1[14],ptable1[13],ptable1[12],ptable1[11],ptable1[10],ptable1[09],ptable1[08],
              ptable1[07],ptable1[06],ptable1[05],ptable1[04],ptable1[03],ptable1[02],ptable1[01],ptable1[00]}=
              {8'd183,8'd11,8'd13,8'd87,8'd54,8'd196,8'd233,8'd32,8'd120,8'd184,8'd63,8'd53,8'd135,8'd177,8'd7,8'd211,8'd253,8'd113,8'd87,8'd164,8'd31,8'd101,8'd243,8'd17};

wire [7    :    0] ptable2[7:0 ];
assign {ptable2[7],ptable2[6],ptable2[5],ptable2[4],ptable2[3],ptable2[2],ptable2[1],ptable2[0]}= {8'd0,8'd255,8'd85,8'd170,8'd204,8'd51,8'd240,8'd15};
*/
assign s_seed = {core,num};

genvar i;
generate
    for(i=0;i<S_SEED_REPEAT; i=i+1 )begin :lp
        assign seed[(i+1)*S_SEED_WIDTH-1 : i*S_SEED_WIDTH  ] = s_seed ;// ^ ptable2[i]; 
    end
    if(S_SEED_REPEAT*S_SEED_WIDTH!=24) assign seed[23: S_SEED_REPEAT*S_SEED_WIDTH ] = s_seed[LST_SEED_WIDTH-1    : 0] ;// ^ ptable2[S_SEED_REPEAT][LST_SEED_WIDTH-1    : 0] ;
endgenerate


 crc crc_16(
    .data_in        (seed),
    .crc_en        (rnd_en),
    .crc_out        (rnd_16_bit),
    .rst            (reset),
    .clk            (clk)
    );


/*
always @(*)begin
        rnd_8_bit=  ({8{seed[0 ]}}& ptable1[0 ]) ^ ({8{seed[1 ]}}& ptable1[1 ]) ^ ({8{seed[2 ]}}& ptable1[2 ]) ^ ({8{seed[3 ]}}& ptable1[3 ]) ^
                       ({8{seed[4 ]}}& ptable1[4 ]) ^ ({8{seed[5 ]}}& ptable1[5 ]) ^ ({8{seed[6 ]}}& ptable1[6 ]) ^ ({8{seed[7 ]}}& ptable1[7 ]) ^
                        ({8{seed[8 ]}}& ptable1[8 ]) ^ ({8{seed[9 ]}}& ptable1[9 ]) ^ ({8{seed[10]}}& ptable1[10]) ^ ({8{seed[11]}}& ptable1[11]) ^
                        ({8{seed[12]}}& ptable1[12]) ^ ({8{seed[11]}}& ptable1[11]) ^ ({8{seed[14]}}& ptable1[14]) ^ ({8{seed[15]}}& ptable1[15]) ^
                        ({8{seed[16]}}& ptable1[16]) ^ ({8{seed[17]}}& ptable1[17]) ^ ({8{seed[18]}}& ptable1[18]) ^ ({8{seed[19]}}& ptable1[19]) ^
                        ({8{seed[18]}}& ptable1[18]) ^ ({8{seed[19]}}& ptable1[19]) ^ ({8{seed[22]}}& ptable1[22]) ^ ({8{seed[23]}}& ptable1[23]) ;
end
*/
assign rnd_max_width = rnd_16_bit    [MAX_RND_WIDTH-1    :    0];

assign rnd = (rnd_max_width > MAX_RND [MAX_RND_WIDTH-1  :   0]) ? rnd_max_width - MAX_RND[MAX_RND_WIDTH-1    :    0] : rnd_max_width; 
assign valid = (rnd_max_width <= MAX_RND [MAX_RND_WIDTH-1   :   0]);


endmodule


//  The output of random generator is not the core num
module pseudo_random_no_core #(
        parameter MAX_RND                = 10,
        parameter MAX_CORE             = 10,
        parameter MAX_NUM             = 10,
        parameter MAX_RND_WIDTH     =log2(MAX_RND+1), 
        parameter MAX_CORE_WIDTH     =log2(MAX_CORE+1), 
        parameter MAX_NUM_WIDTH     =log2(MAX_NUM+1) 

)(
    
    input    [MAX_CORE_WIDTH-1    :    0]    core,
    input    [MAX_NUM_WIDTH-1    :    0]    num,
    output[MAX_RND_WIDTH-1    :    0]    rnd,
    input                                    rnd_en,
    input                                 reset,
    input                                 clk

);

  
    function integer log2;
      input integer number; begin   
         log2=(number <=1) ? 1: 0;    
         while(2**log2<number) begin    
            log2=log2+1;    
         end 	   
      end   
    endfunction // log2 

    wire[MAX_RND_WIDTH-1    :    0]    rnd1,rnd2,rnd3;
    wire[MAX_NUM_WIDTH-1    :    0]    num2,num3;
    wire[MAX_CORE_WIDTH-1:    0]    core2,core3;
    
    assign num2 = num+num;
    assign num3 = num+rnd2;
    assign core2= core + core;
    assign core3= core+rnd1;
    

    
    pseudo_random #(
            .MAX_RND        (MAX_RND),
            .MAX_CORE    (MAX_CORE),
            .MAX_NUM     (MAX_NUM )
    )
    pseudo_random_1
    (
        .core    (core),
        .num    (num),
        .rnd    (rnd1),
        .rnd_en    (rnd_en),
        .reset    (reset),
        .clk        (clk    )
        
    );
    
    pseudo_random #(
            .MAX_RND        (MAX_RND),
            .MAX_CORE    (MAX_CORE),
            .MAX_NUM     (MAX_NUM )
    )
    pseudo_random_2
    (
        .core    (core2),
        .num    (num2),
        .rnd    (rnd2),
        .rnd_en    (rnd_en),
        .reset    (reset),
        .clk        (clk    )
    );
    
    pseudo_random #(
            .MAX_RND        (MAX_RND),
            .MAX_CORE    (MAX_CORE),
            .MAX_NUM     (MAX_NUM )
    )
    pseudo_random_3
    (
        .core    (core3),
        .num    (num3),
        .rnd    (rnd3),
        .rnd_en    (rnd_en),
        .reset    (reset),
        .clk        (clk    )
    );
    
    assign rnd = (rnd1 != core)? rnd1: 
                     (rnd2 != core)? rnd2:
                     (rnd3 != core)? rnd3:
                     (core == MAX_RND)? 0 : rnd1+1;
    
endmodule 

    
module crc(
  input [23:0] data_in,
  input crc_en,
  output [15:0] crc_out,
  input rst,
  input clk);

  reg [15:0] lfsr_q,lfsr_c;

  assign crc_out = lfsr_q;

  always @(*) begin
    lfsr_c[0] = lfsr_q[0] ^ lfsr_q[1] ^ lfsr_q[2] ^ lfsr_q[3] ^ lfsr_q[4] ^ lfsr_q[5] ^ lfsr_q[7] ^ lfsr_q[8] ^ lfsr_q[9] ^ lfsr_q[10] ^ lfsr_q[11] ^ lfsr_q[12] ^ lfsr_q[13] ^ lfsr_q[14] ^ lfsr_q[15] ^ data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7] ^ data_in[8] ^ data_in[9] ^ data_in[10] ^ data_in[11] ^ data_in[12] ^ data_in[13] ^ data_in[15] ^ data_in[16] ^ data_in[17] ^ data_in[18] ^ data_in[19] ^ data_in[20] ^ data_in[21] ^ data_in[22] ^ data_in[23];
    lfsr_c[1] = lfsr_q[0] ^ lfsr_q[1] ^ lfsr_q[2] ^ lfsr_q[3] ^ lfsr_q[4] ^ lfsr_q[5] ^ lfsr_q[6] ^ lfsr_q[8] ^ lfsr_q[9] ^ lfsr_q[10] ^ lfsr_q[11] ^ lfsr_q[12] ^ lfsr_q[13] ^ lfsr_q[14] ^ lfsr_q[15] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7] ^ data_in[8] ^ data_in[9] ^ data_in[10] ^ data_in[11] ^ data_in[12] ^ data_in[13] ^ data_in[14] ^ data_in[16] ^ data_in[17] ^ data_in[18] ^ data_in[19] ^ data_in[20] ^ data_in[21] ^ data_in[22] ^ data_in[23];
    lfsr_c[2] = lfsr_q[6] ^ lfsr_q[8] ^ data_in[0] ^ data_in[1] ^ data_in[14] ^ data_in[16];
    lfsr_c[3] = lfsr_q[7] ^ lfsr_q[9] ^ data_in[1] ^ data_in[2] ^ data_in[15] ^ data_in[17];
    lfsr_c[4] = lfsr_q[8] ^ lfsr_q[10] ^ data_in[2] ^ data_in[3] ^ data_in[16] ^ data_in[18];
    lfsr_c[5] = lfsr_q[9] ^ lfsr_q[11] ^ data_in[3] ^ data_in[4] ^ data_in[17] ^ data_in[19];
    lfsr_c[6] = lfsr_q[10] ^ lfsr_q[12] ^ data_in[4] ^ data_in[5] ^ data_in[18] ^ data_in[20];
    lfsr_c[7] = lfsr_q[11] ^ lfsr_q[13] ^ data_in[5] ^ data_in[6] ^ data_in[19] ^ data_in[21];
    lfsr_c[8] = lfsr_q[12] ^ lfsr_q[14] ^ data_in[6] ^ data_in[7] ^ data_in[20] ^ data_in[22];
    lfsr_c[9] = lfsr_q[0] ^ lfsr_q[13] ^ lfsr_q[15] ^ data_in[7] ^ data_in[8] ^ data_in[21] ^ data_in[23];
    lfsr_c[10] = lfsr_q[0] ^ lfsr_q[1] ^ lfsr_q[14] ^ data_in[8] ^ data_in[9] ^ data_in[22];
    lfsr_c[11] = lfsr_q[1] ^ lfsr_q[2] ^ lfsr_q[15] ^ data_in[9] ^ data_in[10] ^ data_in[23];
    lfsr_c[12] = lfsr_q[2] ^ lfsr_q[3] ^ data_in[10] ^ data_in[11];
    lfsr_c[13] = lfsr_q[3] ^ lfsr_q[4] ^ data_in[11] ^ data_in[12];
    lfsr_c[14] = lfsr_q[4] ^ lfsr_q[5] ^ data_in[12] ^ data_in[13];
    lfsr_c[15] = lfsr_q[0] ^ lfsr_q[1] ^ lfsr_q[2] ^ lfsr_q[3] ^ lfsr_q[4] ^ lfsr_q[6] ^ lfsr_q[7] ^ lfsr_q[8] ^ lfsr_q[9] ^ lfsr_q[10] ^ lfsr_q[11] ^ lfsr_q[12] ^ lfsr_q[13] ^ lfsr_q[14] ^ lfsr_q[15] ^ data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7] ^ data_in[8] ^ data_in[9] ^ data_in[10] ^ data_in[11] ^ data_in[12] ^ data_in[14] ^ data_in[15] ^ data_in[16] ^ data_in[17] ^ data_in[18] ^ data_in[19] ^ data_in[20] ^ data_in[21] ^ data_in[22] ^ data_in[23];

  end // always

  always @(posedge clk, posedge rst) begin
    if(rst) begin
      lfsr_q <= {16{1'b1}};
    end
    else begin
      lfsr_q <= crc_en ? lfsr_c : lfsr_q;
    end
  end // always
endmodule // crc
