`include "pronoc_def.v"
`ifdef SIMULATION

module routers_statistic_collector #(
    parameter NOC_ID=0
)(
    reset,
    clk,        
    router_event,
    print
);
    `NOC_CONF
    
    input   clk,reset;
    input   router_event_t  router_event [NR-1 : 0][MAX_P-1 : 0];
    input   print;
    
    typedef struct   {
        integer pck_num_in;
        integer flit_num_in;
        integer pck_num_out;
        integer flit_num_out;
        integer flit_num_in_bypassed;
        integer flit_num_in_buffered;
        integer bypass_counter [SMART_NUM : 0];
    } router_stat_t;
    
    task  reset_router_stat;
        output  router_stat_t stat_in;
        integer k;
        begin
            stat_in.pck_num_in=0;
            stat_in.flit_num_in=0;
            stat_in.pck_num_out=0;
            stat_in.flit_num_out=0;
            stat_in.flit_num_in_bypassed=0;
            stat_in.flit_num_in_buffered=0;
            for (k=0;k<SMART_NUM+1;k++) stat_in.bypass_counter[k]=0;
        end
    endtask
    
    task print_router_st;
        input router_stat_t stat_in;
        integer k;
        begin 
            $write("%0d,", stat_in.flit_num_in);
            $write("%0d,", stat_in.pck_num_in);
            $write("%0d,", stat_in.flit_num_out);
            $write("%0d,", stat_in.pck_num_out);
            $write("%0d,", stat_in.flit_num_in_buffered);
            $write("%0d,", stat_in.flit_num_in_bypassed);    
            if(SMART_MAX>0) for (k=0;k<SMART_MAX+1;k++) $write("%0d,",stat_in.bypass_counter[k]);
            $write("\n");
        end
    endtask
    
    router_stat_t router_stat [NR][MAX_P];
    router_stat_t router_stat_accum [NR];    
    
    integer r,p;
    initial begin 
        for(r=0;r<NR;r++) begin
            reset_router_stat(router_stat_accum[r]);    
            for (p=0;p<MAX_P;p++)begin            
                reset_router_stat(router_stat[r][p]);                        
            end//p    
        end//r
    end//init
    
    always @ (posedge clk) begin 
        for(r=0;r<NR;r++) begin            
            for (p=0;p<MAX_P;p++)begin
                if( router_event[r][p].flit_wr_i )     router_stat[r][p].flit_num_in++;            
                if( router_event[r][p].pck_wr_i  ) router_stat[r][p].pck_num_in++;
                if( router_event[r][p].flit_wr_o ) router_stat[r][p].flit_num_out++;
                if( router_event[r][p].pck_wr_o  ) router_stat[r][p].pck_num_out++;
                if(    router_event[r][p].flit_in_bypassed) router_stat[r][p].flit_num_in_bypassed++;
                else if( router_event[r][p].flit_wr_i) begin 
                    router_stat [r][p].flit_num_in_buffered++;
                    router_stat[r][p].bypass_counter[router_event[r][p].bypassed_num]++;
                end
            end//p    
        end//r        
    end//always   
    
    integer k;
    always @(posedge print) begin 
        for(r=0;r<NR;r++) begin        
            for (p=0;p<MAX_P;p++)begin
                router_stat_accum[r].pck_num_in+=           router_stat[r][p].pck_num_in;                  
                router_stat_accum[r].flit_num_in+=         router_stat[r][p].flit_num_in;                 
                router_stat_accum[r].pck_num_out+=         router_stat[r][p].pck_num_out;                 
                router_stat_accum[r].flit_num_out+=        router_stat[r][p].flit_num_out;                
                router_stat_accum[r].flit_num_in_bypassed+=router_stat[r][p].flit_num_in_bypassed;        
                router_stat_accum[r].flit_num_in_buffered+=router_stat[r][p].flit_num_in_buffered;            
                for (k=0;k<SMART_MAX+1;k++) router_stat_accum[r].bypass_counter[k]+=router_stat[r][p].bypass_counter[k];   
                
            end//p
        end//r
        //report router statistic
        $write("\n"); 
        $display("\n\tRouters Statistics:");
        $write("\t#RID, #Port,flit_in,pck_in,flit_out,pck_out,flit_in_buffered,flit_in_bypassed,");
        if(SMART_MAX>0) for (k=0;k<SMART_MAX+1;k++) $write("bypsd_%0d_times,",k);
        $write("\n");        
        for(r=0;r<NR;r++) begin    
            for (p=0;p<MAX_P;p++)begin
                $write("\t%0d,%0d,",r,p);
                print_router_st(router_stat [r][p]);
            end//p
            $write("\t%0d,total,",r);
            print_router_st(router_stat_accum [r]);
        end    //r    
    end//always
endmodule
`endif