module gcd_ip#(
    parameter GCDw=32, 
    parameter Dw =GCDw, 
    parameter Aw =5,    
    parameter TAGw =3,
    parameter SELw =4
)
(
    clk,
    reset,    
    //wishbone bus interface
    s_dat_i,
    s_sel_i,
    s_addr_i,  
    s_tag_i,
    s_stb_i,
    s_cyc_i,
    s_we_i,    
    s_dat_o,
    s_ack_o,
    s_err_o,
    s_rty_o
    
);
    input                  clk;
    input                  reset;
    
    //wishbone bus interface
    input       [Dw-1       :   0]      s_dat_i;
    input       [SELw-1     :   0]      s_sel_i;
    input       [Aw-1       :   0]      s_addr_i;  
    input       [TAGw-1     :   0]      s_tag_i;
    input                               s_stb_i;
    input                               s_cyc_i;
    input                               s_we_i;
    
    output      [Dw-1       :   0]      s_dat_o;
    output   reg                        s_ack_o;
    output                              s_err_o;
    output                              s_rty_o;
    
 //Wishbone bus registers address
     localparam DONE_REG_ADDR=0;
     localparam IN_1_REG_ADDR=1;
     localparam IN_2_REG_ADDR=2;
     localparam GCD_REG_ADDR=3;
 
    assign s_err_o        =   1'b0;
    assign s_rty_o        =   1'b0; 
     
    wire[GCDw-1	:0] gcd;
    reg [GCDw-1	:0] readdata,in1,in2;
    wire done;

    assign s_dat_o =readdata;
     
    always @ (posedge clk or posedge reset) begin
        if(reset) begin 
            s_ack_o   <=  1'b0;
        end else begin
            s_ack_o   <=   (s_stb_i & ~s_ack_o); 
        end //reset
    end//always
     
    always @ (posedge clk or posedge reset) begin
        if(reset) begin 
            readdata <= 0; 
            in1 <= 0;
            in2 <= 0;            
        end else begin
            if(s_stb_i && s_we_i) begin  //write regiters
                if(s_addr_i==IN_1_REG_ADDR[Aw-1: 0]) in1 <= s_dat_i;
                else if(s_addr_i==IN_2_REG_ADDR[Aw-1: 0]) in2 <= s_dat_i;
            end //sa_stb_i && sa_we_i
            else begin //read registers
                if (s_addr_i==DONE_REG_ADDR) readdata<={{GCDw{1'b0}},done};
                if (s_addr_i==GCD_REG_ADDR)  readdata<=gcd;
            end
        end //reset
    end//always
     
    // start gcd calculation by writiing on in2 register    
    wire start=(s_stb_i && s_we_i && (s_addr_i==IN_2_REG_ADDR[Aw-1: 0]));    
    reg ps,ns;
    reg gcd_reset,gcd_reset_next;
    reg gcd_en,gcd_en_next;

    always @ (posedge clk or posedge reset) begin
        if(reset) begin 
            ps<=1'b0;
            gcd_reset<=1'b1;
            gcd_en<=1'b0; 
        end else begin 
            ps<=ns;
            gcd_en<=gcd_en_next;
            gcd_reset<=gcd_reset_next;                
        end
    end
        
    always @(*)begin 
        gcd_reset_next=1'b0;
        gcd_en_next=1'b0; 
        ns=ps;
        case(ps)
            1'b0:begin 
                if(start) begin 
                    ns=1'b1; 
                    gcd_reset_next=1'b1; 
                end
            end
            1'b1:begin 
                gcd_en_next=1'b1; 
                ns=1'b0;
            end 
        endcase
    end
 
     
	gcd #(
		.GCDw(GCDw)
	) the_gcd 
	( 
        .clk (clk),
        .reset (gcd_reset),
        .enable (gcd_en),
        .in1 (in1),
        .in2 (in2),
        .done (done),
        .gcd (gcd)
     );
     
endmodule

