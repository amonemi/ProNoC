#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>


void jtag_reorder ( char * string_in, char *string_out ) {
 
  int size = strlen(string_in);
  int i;
  for (i=0;i<size;i+=2){
	 string_out[i]=   string_in[size-i-2];
	 string_out[i+1]= string_in[size-i-1];
  }	
   string_out[i]=0;
}

void init_out_file (FILE * out){
fprintf(out," `ifdef INCLUDE_SIM_INPUT \n\
/*  \n\
parameter SIM_ACTION = \"((1,1,7,3),(0,2,010000007f,24),(0,2,0200000006,24),(0,2,04000000ff,24))\";  \n\
SIM_ACTION:\n\
((time,type,value,length),\n\
(time,type,value,length),\n\
...\n\
(time,type,value,length))\n\
where:\n\
time: A 32-bit value in milliseconds that represents the start time of the shift\n\
relative to the completion of the previous shift.\n\
type: A 4-bit value that determines whether the shift is a DR shift or an\n\
IR shift.\n\
value: The data associated with the shift. For IR shifts, it is a 32-bit value.\n\
For DR shifts, the length is determined by length.\n\
length: A 32-bit value that specifies the length of the data being shifted.\n\
This value should be equal to SLD_NODE_IR_WIDTH; otherwise, the value\n\
field may be padded or truncated. 0 is invalid.\n\
\n\
SLD_SIM_TOTAL_LENGTH: \n\
The total number of bits to be shifted in either an IR shift or a DR shift. This\n\
value should be equal to the sum of all the length values specified in the SLD_SIM_ACTION string\n\
\n\
SIM_N_SCAN:\n\
Specifies the number of shifts in the simulation model\n\
\n\
example:\n\
select index 7f\n\
$jseq drshift -state IDLE -hex 36 7f00000001    (0,2, 010000007f,24)\n\
I:6,D:32:FFFFFFF,D:32:FFFFFFFF to jtag\n\
\n\
$jseq drshift -state IDLE -hex 36 0600000002    (0,2, 0200000006,24)\n\
$jseq drshift -state IDLE -hex 36 ff00000004    (0,2, 04000000ff,24)\n\
\n\
	parameter SIM_ACTION = \"((1,1,7,3),(0,2,ff,20),(0,1,6,3),(0,2,ffffffff,20),(0,2,1,20),(0,2,2,20),(0,2,3,20),(0,2,4,20))\";  \n\
	parameter SIM_N_SCAN=8;\n\
    	parameter SIM_LENGTH=198;\n\
*/\n\
    parameter SIM_ACTION = \"((1,1,7,3)");



}


int main (){
	char * line = NULL;
	char chunk[1024];
	char data[100];
	char data_o[100];
	int n=1;
	int len=3;
	FILE *in  = fopen ("to_xsct.txt", "r");
 	FILE *out = fopen ("jtag_sim_input.v", "w");
	if (out == NULL) perror("cant creat out file");
	if (in == NULL)  perror("cant read input file");
        unsigned int num,size;	
	init_out_file(out);
        while (fgets(chunk, sizeof(chunk), in) != NULL) {
        	if(sscanf( chunk, "$jseq drshift -state IDLE -hex %u %s",&size, data )){
			jtag_reorder(data,data_o);		 
			fprintf(out,",(0,2,%s,%x)",data_o,size);
			len+=size;
			n++;

		}
		if(sscanf( chunk, "$jseq drshift -state IDLE -capture -hex %u %s",&size, data )){
			jtag_reorder(data,data_o);		 
			fprintf(out,",(0,2,%s,%x)",data_o,size);
			len+=size;
			n++;
		}


    	}
    	fprintf(out,")\";\n");
	fprintf(out,"parameter SIM_N_SCAN=%u;\n",n);
	fprintf(out,"parameter SIM_LENGTH=%u;\n`endif",len);


	fclose (in);
	fclose (out);
return 0;
}
