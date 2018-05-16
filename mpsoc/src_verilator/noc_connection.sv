`timescale     1ns/1ps

`define  START_LOC(port_num,width)       (width*(port_num+1)-1)
`define    END_LOC(port_num,width)            (width*port_num)
`define    CORE_NUM(x,y)                         ((y * NX) +    x)
`define  SELECT_WIRE(x,y,port,width)    `CORE_NUM(x,y)] [`START_LOC(port,width) : `END_LOC(port,width )


module noc_connection (
    
    /*
    reset,
    clk,    
    flit_out_all,
    flit_out_wr_all, 
    credit_in_all,
    flit_in_all,  
    flit_in_wr_all,  
    credit_out_all
    */
 clk,
 reset,
 start_i,
 start_o,
 router_flit_out_all, 
 router_flit_out_we_all,    
 router_credit_in_all,
 router_credit_out_all,
 router_flit_in_all,     
 router_flit_in_we_all,
 router_congestion_in_all,
 router_congestion_out_all,
// router_iport_weight_in_all,
// router_iport_weight_out_all, 
 ni_flit_in,    
 ni_flit_in_wr, 
 ni_credit_out,                 
 ni_flit_out, 
 ni_flit_out_wr,  
 ni_credit_in
    
);
    


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

    `define  INCLUDE_PARAM
    `include"parameter.v"
         
    
    localparam CONGw= (CONGESTION_INDEX==3)?  3:
                      (CONGESTION_INDEX==5)?  3:
                      (CONGESTION_INDEX==7)?  3:
                      (CONGESTION_INDEX==9)?  3:
                      (CONGESTION_INDEX==10)? 4:
                      (CONGESTION_INDEX==12)? 3:2;

    
    localparam
        PV = V * P,
        P_1 = P-1,
        Fw = 2+V+Fpay, //flit width;    
        PFw = P * Fw,
        /* verilator lint_off WIDTH */
        NC = (TOPOLOGY=="RING" || TOPOLOGY=="LINE")? NX : NX*NY,    //number of cores
        /* verilator lint_on WIDTH */
        NCFw = NC * Fw,
        NCV = NC * V,
        CONG_ALw = CONGw * P, // congestion width per router            
        Xw = log2(NX),    // number of node in x axis
        Yw = log2(NY),    // number of node in y axis
        W= WEIGHTw,
        WP = W * P;
                    
                    
   

                    
                    
                    
    output [PFw-1 : 0] router_flit_out_all [NC-1 : 0];
    output [P-1 : 0] router_flit_out_we_all [NC-1 : 0];    
    input  [PV-1 : 0] router_credit_in_all [NC-1 : 0];
    
    
    input  [PFw-1 : 0] router_flit_in_all [NC-1 : 0];
    input  [P-1 : 0] router_flit_in_we_all [NC-1 : 0];
    output [PV-1 : 0] router_credit_out_all[NC-1: 0];                    
    
    input  [CONG_ALw-1  :   0] router_congestion_in_all [NC-1         :0];    
    output [CONG_ALw-1  :   0] router_congestion_out_all  [NC-1         :0]; 
   // input  [WP-1 : 0] router_iport_weight_in_all [NC-1 :0]; 
   // output [WP-1 : 0] router_iport_weight_out_all [NC-1 :0]; 
    
    input  [Fw-1 : 0] ni_flit_in [NC-1 : 0];   
    input  [NC-1 : 0] ni_flit_in_wr; 
    output [V-1 : 0] ni_credit_out [NC-1 : 0];
    output [Fw-1 : 0] ni_flit_out [NC-1 : 0];   
    output [NC-1 : 0] ni_flit_out_wr;  
    input  [V-1 : 0]  ni_credit_in [NC-1 : 0];    
    
    input clk,reset, start_i;
    
    
    output [NC-1 : 0] start_o;

genvar x,y;
generate 
    /* verilator lint_off WIDTH */ 
    if( TOPOLOGY == "RING" || TOPOLOGY == "LINE") begin : ring_line
    /* verilator lint_on WIDTH */  
        for  (x=0;   x<NX; x=x+1) begin :ring_loop
            if(x    <   NX-1) begin: not_last_node
                assign router_flit_out_all [`SELECT_WIRE(x,0,1,Fw)] = router_flit_in_all [`SELECT_WIRE((x+1),0,2,Fw)];
                assign router_credit_out_all [`SELECT_WIRE(x,0,1,V)] = router_credit_in_all [`SELECT_WIRE((x+1),0,2,V)];
                assign router_flit_out_we_all [x][1] = router_flit_in_we_all [`CORE_NUM((x+1),0)][2];
                assign router_congestion_out_all[`SELECT_WIRE(x,0,1,CONGw)] = router_congestion_in_all [`SELECT_WIRE((x+1),0,2,CONGw)];
               // assign router_iport_weight_out_all[`SELECT_WIRE(x,0,1,W)] = router_iport_weight_in_all [`SELECT_WIRE((x+1),0,2,W)];
            end else begin :last_node
                 /* verilator lint_off WIDTH */ 
                 if(TOPOLOGY == "LINE") begin : line_last_x
                 /* verilator lint_on WIDTH */ 
                    assign router_flit_out_all [`SELECT_WIRE(x,0,1,Fw)] = {Fw{1'b0}};
                    assign router_credit_out_all [`SELECT_WIRE(x,0,1,V)]= {V{1'b0}};
                    assign router_flit_out_we_all [x][1] = 1'b0;
                    assign router_congestion_out_all [`SELECT_WIRE(x,0,1,CONGw)] = {CONGw{1'b0}};  
                 //   assign router_iport_weight_out_all [`SELECT_WIRE(x,0,1,W)] = {W{1'b0}};                
                 end else begin : ring_last_x
                    assign router_flit_out_all [`SELECT_WIRE(x,0,1,Fw)] = router_flit_in_all     [`SELECT_WIRE(0,0,2,Fw)];
                    assign router_credit_out_all [`SELECT_WIRE(x,0,1,V)] = router_credit_in_all    [`SELECT_WIRE(0,0,2,V)];
                    assign router_flit_out_we_all [x][1] =    router_flit_in_we_all [`CORE_NUM(0,0)][2];
                    assign router_congestion_out_all [`SELECT_WIRE(x,0,1,CONGw)]  = router_congestion_in_all [`SELECT_WIRE(0,0,2,CONGw)];
                  //  assign router_iport_weight_out_all [`SELECT_WIRE(x,0,1,W)]  = router_iport_weight_in_all [`SELECT_WIRE(0,0,2,W)];
                end 
            end
            if(x>0)begin :not_first_x
                assign  router_flit_out_all [`SELECT_WIRE(x,0,2,Fw)] = router_flit_in_all [`SELECT_WIRE((x-1),0,1,Fw)];
                assign  router_credit_out_all [`SELECT_WIRE(x,0,2,V)] =  router_credit_in_all [`SELECT_WIRE((x-1),0,1,V)] ;
                assign  router_flit_out_we_all [x][2] = router_flit_in_we_all [`CORE_NUM((x-1),0)][1];
                assign  router_congestion_out_all [`SELECT_WIRE(x,0,2,CONGw)] = router_congestion_in_all [`SELECT_WIRE((x-1),0,1,CONGw)];
               // assign  router_iport_weight_out_all [`SELECT_WIRE(x,0,2,W)] = router_iport_weight_in_all [`SELECT_WIRE((x-1),0,1,W)];
            end else begin :first_x
                /* verilator lint_off WIDTH */ 
                if(TOPOLOGY == "LINE") begin : line_first_x
                /* verilator lint_on WIDTH */ 
                    assign  router_flit_out_all [`SELECT_WIRE(x,0,2,Fw)] = {Fw{1'b0}};
                    assign  router_credit_out_all [`SELECT_WIRE(x,0,2,V)] = {V{1'b0}};
                    assign  router_flit_out_we_all [x][2] = 1'b0;
                    assign  router_congestion_out_all[`SELECT_WIRE(x,0,2,CONGw)] = {CONGw{1'b0}};
                   // assign  router_iport_weight_out_all[`SELECT_WIRE(x,0,2,W)] = {W{1'b0}};
                 end else begin : ring_first_x

                    assign  router_flit_out_all      [`SELECT_WIRE(x,0,2,Fw)] = router_flit_in_all [`SELECT_WIRE((NX-1),0,1,Fw)] ;
                    assign  router_credit_out_all    [`SELECT_WIRE(x,0,2,V)] = router_credit_in_all [`SELECT_WIRE((NX-1),0,1,V)] ;
                    assign  router_flit_out_we_all   [x][2] = router_flit_in_we_all [`CORE_NUM((NX-1),0)][1];
                    assign  router_congestion_out_all[`SELECT_WIRE(x,0,2,CONGw)] = router_congestion_in_all [`SELECT_WIRE((NX-1),0,1,CONGw)];
                   // assign  router_iport_weight_out_all[`SELECT_WIRE(x,0,2,W)] = router_iport_weight_in_all [`SELECT_WIRE((NX-1),0,1,W)];
                end
            end             
            // local port connection
                assign router_flit_out_all [`SELECT_WIRE(x,0,0,Fw)] = ni_flit_in [x];
                assign router_credit_out_all [`SELECT_WIRE(x,0,0,V)] =  ni_credit_in[x];
                assign router_flit_out_we_all [x][0] = ni_flit_in_wr [x];
                assign router_congestion_out_all[`SELECT_WIRE(x,0,0,CONGw)] = {CONGw{1'b0}};    
              //  assign router_iport_weight_out_all[`SELECT_WIRE(x,0,0,W)] = 1;    
    
                assign ni_flit_out [x] = router_flit_in_all [`SELECT_WIRE(x,0,0,Fw)];
                assign ni_flit_out_wr [x] = router_flit_in_we_all[x][0];
                assign ni_credit_out [x] = router_credit_in_all [`SELECT_WIRE(x,0,0,V)];
        end//x        
    end else begin :mesh_torus



    for    (x=0;    x<NX; x=x+1) begin :x_loop
        for    (y=0;    y<NY;    y=y+1) begin: y_loop
        localparam IP_NUM    =    (y * NX) +    x;
    
/*
    router # (
        .V                            (V),
        .P                            (P),
        .B                         (B), 
        .NX                        (NX),
        .NY                        (NY),
        //.X                            (x),    
        //.Y                            (y),    
        .C                            (C),    
        .Fpay                     (Fpay),    
        .TOPOLOGY                (TOPOLOGY),
        .MUX_TYPE                (MUX_TYPE),
        .VC_REALLOCATION_TYPE(VC_REALLOCATION_TYPE),
        .VC_SW_COMB_TYPE        (VC_SW_COMB_TYPE)
    )
    the_router
    (
        .X                        (x    [Xw-1    :0]),    
        .Y                        (y    [Yw-1    :0]),
        .flit_in_all        (router_flit_out_all        [IP_NUM]),
        .flit_in_we_all    (router_flit_out_we_all    [IP_NUM]),
        .credit_out_all    (router_credit_in_all    [IP_NUM]),
    
        .flit_out_all        (router_flit_in_all        [IP_NUM]),
        .flit_out_we_all    (router_flit_in_we_all    [IP_NUM]),
        .credit_in_all        (router_credit_out_all    [IP_NUM]),
    
        .clk                    (clk),
        .reset                (reset)

    );
    */
/*
in    [x,y][1] <------         out [x+1        ,y     ][3]    ;
in    [x,y][2] <------        out [x        ,y-1][4] ;
in    [x,y][3] <------        out [x-1        ,y     ][1]    ;
in    [x,y][4] <------        out [x        ,y+1][2]    ;
    
port num
local = 0
east  = 1
north = 2
west  = 3
south = 4
*/    
    
    
    if(x    <    NX-1) begin
        assign    router_flit_out_all     [`SELECT_WIRE(x,y,1,Fw)]         = router_flit_in_all     [`SELECT_WIRE((x+1),y,3,Fw)];
        assign    router_credit_out_all    [`SELECT_WIRE(x,y,1,V)]    = router_credit_in_all    [`SELECT_WIRE((x+1),y,3,V)];
        assign    router_flit_out_we_all    [IP_NUM][1]                            = router_flit_in_we_all    [`CORE_NUM((x+1),y)][3];
        assign    router_congestion_out_all     [`SELECT_WIRE(x,y,1,CONGw)]  = router_congestion_in_all [`SELECT_WIRE((x+1),y,3,CONGw)];
      //  assign    router_iport_weight_out_all     [`SELECT_WIRE(x,y,1,W)]  = router_iport_weight_in_all [`SELECT_WIRE((x+1),y,3,W)];
    end else begin
        /* verilator lint_off WIDTH */ 
        if(TOPOLOGY == "MESH") begin 
        /* verilator lint_on WIDTH */ 
            assign    router_flit_out_all     [`SELECT_WIRE(x,y,1,Fw)]         =    {Fw{1'b0}};
            assign    router_credit_out_all    [`SELECT_WIRE(x,y,1,V)]            =    {V{1'b0}};
            assign    router_flit_out_we_all    [IP_NUM][1]                        =    1'b0;
            assign    router_congestion_out_all [`SELECT_WIRE(x,y,1,CONGw)]  = {CONGw{1'b0}};
       //     assign    router_iport_weight_out_all [`SELECT_WIRE(x,y,1,W)]  = {W{1'b0}};
        /* verilator lint_off WIDTH */ 
        end else if(TOPOLOGY == "TORUS") begin
        /* verilator lint_on WIDTH */ 
            assign    router_flit_out_all     [`SELECT_WIRE(x,y,1,Fw)]         =    router_flit_in_all     [`SELECT_WIRE(0,y,3,Fw)];
            assign    router_credit_out_all    [`SELECT_WIRE(x,y,1,V)]            =    router_credit_in_all    [`SELECT_WIRE(0,y,3,V)];
            assign    router_flit_out_we_all    [IP_NUM][1]                        =    router_flit_in_we_all    [`CORE_NUM(0,y)][3];
            assign    router_congestion_out_all [`SELECT_WIRE(x,y,1,CONGw)]  = router_congestion_in_all [`SELECT_WIRE(0,y,3,CONGw)];
        //    assign    router_iport_weight_out_all [`SELECT_WIRE(x,y,1,W)]  = router_iport_weight_in_all [`SELECT_WIRE(0,y,3,W)];
        end //topology
    end 
        
    
    if(y>0) begin
        assign    router_flit_out_all     [`SELECT_WIRE(x,y,2,Fw)] =    router_flit_in_all [`SELECT_WIRE(x,(y-1),4,Fw)];
        assign    router_credit_out_all    [`SELECT_WIRE(x,y,2,V)] =  router_credit_in_all [`SELECT_WIRE(x,(y-1),4,V)];
        assign    router_flit_out_we_all    [IP_NUM][2]  =    router_flit_in_we_all    [`CORE_NUM(x,(y-1))][4];
        assign    router_congestion_out_all [`SELECT_WIRE(x,y,2,CONGw)]  = router_congestion_in_all [`SELECT_WIRE(x,(y-1),4,CONGw)];
      //  assign    router_iport_weight_out_all [`SELECT_WIRE(x,y,2,W)] =  router_iport_weight_in_all [`SELECT_WIRE(x,(y-1),4,W)];
    end else begin 
        /* verilator lint_off WIDTH */ 
        if(TOPOLOGY == "MESH") begin
        /* verilator lint_on WIDTH */  
            assign     router_flit_out_all     [`SELECT_WIRE(x,y,2,Fw)]            =    {Fw{1'b0}};
            assign    router_credit_out_all    [`SELECT_WIRE(x,y,2,V)]    =    {V{1'b0}};
            assign    router_flit_out_we_all    [IP_NUM][2]                            =    1'b0;
            assign    router_congestion_out_all [`SELECT_WIRE(x,y,2,CONGw)]                      =     {CONGw{1'b0}};
       //     assign    router_iport_weight_out_all [`SELECT_WIRE(x,y,2,W)]                      =     {W{1'b0}};
       /* verilator lint_off WIDTH */ 
        end else if(TOPOLOGY == "TORUS") begin
        /* verilator lint_on WIDTH */ 
            assign    router_flit_out_all     [`SELECT_WIRE(x,y,2,Fw)]            =    router_flit_in_all     [`SELECT_WIRE(x,(NY-1),4,Fw)];
            assign    router_credit_out_all    [`SELECT_WIRE(x,y,2,V)]    =  router_credit_in_all    [`SELECT_WIRE(x,(NY-1),4,V)];
            assign    router_flit_out_we_all    [IP_NUM][2]                                        =    router_flit_in_we_all    [`CORE_NUM(x,(NY-1))][4];
            assign    router_congestion_out_all [`SELECT_WIRE(x,y,2,CONGw)]  = router_congestion_in_all [`SELECT_WIRE(x,(NY-1),4,CONGw)];
        //    assign    router_iport_weight_out_all [`SELECT_WIRE(x,y,2,W)] = router_iport_weight_in_all [`SELECT_WIRE(x,(NY-1),4,W)];
        end//topology
    end//y>0
    
    
    if(x>0)begin
        assign    router_flit_out_all     [`SELECT_WIRE(x,y,3,Fw)]            =    router_flit_in_all     [`SELECT_WIRE((x-1),y,1,Fw)] ;
        assign    router_credit_out_all    [`SELECT_WIRE(x,y,3,V)]    =  router_credit_in_all    [`SELECT_WIRE((x-1),y,1,V)] ;
        assign    router_flit_out_we_all    [IP_NUM][3]                                        =    router_flit_in_we_all    [`CORE_NUM((x-1),y)][1];
        assign    router_congestion_out_all [`SELECT_WIRE(x,y,3,CONGw)]  = router_congestion_in_all [`SELECT_WIRE((x-1),y,1,CONGw)];
     //   assign    router_iport_weight_out_all [`SELECT_WIRE(x,y,3,W)]  = router_iport_weight_in_all [`SELECT_WIRE((x-1),y,1,W)];
    end else begin
        /* verilator lint_off WIDTH */ 
        if(TOPOLOGY == "MESH") begin 
        /* verilator lint_on WIDTH */ 
            assign    router_flit_out_all     [`SELECT_WIRE(x,y,3,Fw)]  =  {Fw{1'b0}};
            assign    router_credit_out_all    [`SELECT_WIRE(x,y,3,V)] =    {V{1'b0}};
            assign    router_flit_out_we_all    [IP_NUM][3] = 1'b0;
            assign    router_congestion_out_all [`SELECT_WIRE(x,y,3,CONGw)]  = {CONGw{1'b0}};
      //      assign    router_iport_weight_out_all [`SELECT_WIRE(x,y,3,W)]  =  {W{1'b0}};
        /* verilator lint_off WIDTH */ 
        end else if(TOPOLOGY == "TORUS") begin
        /* verilator lint_on WIDTH */ 
            assign    router_flit_out_all     [`SELECT_WIRE(x,y,3,Fw)]            =    router_flit_in_all     [`SELECT_WIRE((NX-1),y,1,Fw)] ;
            assign    router_credit_out_all    [`SELECT_WIRE(x,y,3,V)]    =  router_credit_in_all    [`SELECT_WIRE((NX-1),y,1,V)] ;
            assign    router_flit_out_we_all    [IP_NUM][3]   =    router_flit_in_we_all    [`CORE_NUM((NX-1),y)][1];
            assign    router_congestion_out_all [`SELECT_WIRE(x,y,3,CONGw)]  = router_congestion_in_all [`SELECT_WIRE((NX-1),y,1,CONGw)];
        //    assign    router_iport_weight_out_all [`SELECT_WIRE(x,y,3,W)]  =  router_iport_weight_in_all [`SELECT_WIRE((NX-1),y,1,W)];
        end//topology
    end    
    
    if(y    <    NY-1)begin
        assign    router_flit_out_all     [`SELECT_WIRE(x,y,4,Fw)] =    router_flit_in_all     [`SELECT_WIRE(x,(y+1),2,Fw)];
        assign    router_credit_out_all    [`SELECT_WIRE(x,y,4,V)] =     router_credit_in_all    [`SELECT_WIRE(x,(y+1),2,V)];
        assign    router_flit_out_we_all    [IP_NUM][4] =    router_flit_in_we_all    [`CORE_NUM(x,(y+1))][2];
        assign    router_congestion_out_all [`SELECT_WIRE(x,y,4,CONGw)]  =  router_congestion_in_all [`SELECT_WIRE(x,(y+1),2,CONGw)];
    //    assign    router_iport_weight_out_all [`SELECT_WIRE(x,y,4,W)] = router_iport_weight_in_all [`SELECT_WIRE(x,(y+1),2,W)];
    end else     begin
        /* verilator lint_off WIDTH */ 
        if(TOPOLOGY == "MESH") begin 
        /* verilator lint_on WIDTH */ 
            assign    router_flit_out_all     [`SELECT_WIRE(x,y,4,Fw)]  =  {Fw{1'b0}};
            assign    router_credit_out_all    [`SELECT_WIRE(x,y,4,V)]  =    {V{1'b0}};
            assign    router_flit_out_we_all    [IP_NUM][4] = 1'b0;
            assign    router_congestion_out_all [`SELECT_WIRE(x,y,4,CONGw)]  = {CONGw{1'b0}};    
      //      assign    router_iport_weight_out_all [`SELECT_WIRE(x,y,4,W)] = {W{1'b0}};    
       /* verilator lint_off WIDTH */ 
        end else if(TOPOLOGY == "TORUS") begin
        /* verilator lint_on WIDTH */ 
            assign    router_flit_out_all  [`SELECT_WIRE(x,y,4,Fw)]  =    router_flit_in_all     [`SELECT_WIRE(x,0,2,Fw)];
            assign    router_credit_out_all [`SELECT_WIRE(x,y,4,V)]  =     router_credit_in_all    [`SELECT_WIRE(x,0,2,V)];
            assign    router_flit_out_we_all [IP_NUM][4]   =    router_flit_in_we_all    [`CORE_NUM(x,0)][2];
            assign    router_congestion_out_all [`SELECT_WIRE(x,y,4,CONGw)]  = router_congestion_in_all [`SELECT_WIRE(x,0,2,CONGw)];
       //     assign    router_iport_weight_out_all [`SELECT_WIRE(x,y,4,W)]  = router_iport_weight_in_all [`SELECT_WIRE(x,0,2,W)];
        end//topology
    end    
    
    //connection to the ip_core
    
    
    assign router_flit_out_all     [`SELECT_WIRE(x,y,0,Fw)]        =    ni_flit_in            [IP_NUM];
    assign router_credit_out_all   [`SELECT_WIRE(x,y,0,V)]         =    ni_credit_in        [IP_NUM];
    assign router_flit_out_we_all  [IP_NUM][0]                     =    ni_flit_in_wr        [IP_NUM];
    assign router_congestion_out_all[`SELECT_WIRE(x,y,0,CONGw)]     =   {CONGw{1'b0}};   
  //  assign router_iport_weight_out_all[`SELECT_WIRE(x,y,0,W)]     =   1;    
    
    assign ni_flit_out [IP_NUM] = router_flit_in_all [`SELECT_WIRE(x,y,0,Fw)];
    assign ni_flit_out_wr [IP_NUM] = router_flit_in_we_all [IP_NUM][0];
    assign ni_credit_out [IP_NUM] = router_credit_in_all [`SELECT_WIRE(x,y,0,V)];
    
    
            
    /*                
    assign     flit_out_all    [(IP_NUM+1)*Fw-1    : IP_NUM*Fw]    =    ni_flit_out        [IP_NUM];    
    assign    flit_out_wr_all[IP_NUM]                                    =     ni_flit_out_wr    [IP_NUM]; 
    assign     ni_credit_in    [IP_NUM]                                    =    credit_in_all    [(IP_NUM+1)*V-1    : IP_NUM*V];  
    assign     ni_flit_in        [IP_NUM]                                    =     flit_in_all        [(IP_NUM+1)*Fw-1    : IP_NUM*Fw];
    assign      ni_flit_in_wr    [IP_NUM]                                    =    flit_in_wr_all    [IP_NUM];
    assign    credit_out_all    [(IP_NUM+1)*V-1    : IP_NUM*V]        =    ni_credit_out     [IP_NUM];
    */

/*    
always @(posedge clk) begin 
    if(router_credit_out_all[IP_NUM]>0) $display("router_credit_out_all=%x %m",router_credit_out_all[IP_NUM]);
    if(router_credit_in_all[IP_NUM]>0)  $display("router_credit_in_all=%x %m",router_credit_in_all[IP_NUM]);
    if(ni_credit_in        [IP_NUM]>0) $display("ni_credit_in=%x %m",ni_credit_in[IP_NUM]);

end    
*/    

        end //y
    end //x
end        
    
endgenerate



    start_delay_gen #(
        .NC(NC)

    )delay_gen
    (
        .clk(clk),
        .reset(reset),
        .start_i(start_i),
        .start_o(start_o)
    );



endmodule



module start_delay_gen #(
    parameter NC     =    64 //number of cores

)(
    clk,
    reset,
    start_i,
    start_o
);

    input reset,clk,start_i;
    output [NC-1    :    0] start_o;
    reg start_i_reg;
    wire start;
    wire cnt_increase;
    reg  [NC-1    :    0] start_o_next;
    reg [NC-1    :    0] start_o_reg;
    
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
            start_o_reg <= {NC{1'b0}};
            start_i_reg <= 1'b0;
            counter <= 3'd0;
        end else begin 
            counter <= counter+3'd1;
            start_i_reg <= start_i;
            if(cnt_increase | start) start_o_reg <= start_o_next;
            

        end//reset
    end //always

    assign start_o=(cnt_increase | start)? start_o_reg : {NC{1'b0}};

endmodule

