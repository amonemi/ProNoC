`ifdef INCLUDE_SIM_INPUT

/*
parameter SIM_ACTION = "((0,1,7,3),(0,2,ff,20),(0,1,6,3),(0,2,ffffffff,20),(0,2,1,20),(0,2,2,20),(0,2,3,20),(0,2,4,20))",  

SIM_ACTION:
((time,type,value,length),
(time,type,value,length),
...
(time,type,value,length))
where:
time: A 32-bit value in milliseconds that represents the start time of the shift
relative to the completion of the previous shift.
type: A 4-bit value that determines whether the shift is a DR shift or an
IR shift.
value: The data associated with the shift. For IR shifts, it is a 32-bit value.
For DR shifts, the length is determined by length.
length: A 32-bit value that specifies the length of the data being shifted.
This value should be equal to SLD_NODE_IR_WIDTH; otherwise, the value
field may be padded or truncated. 0 is invalid.

SLD_SIM_TOTAL_LENGTH: 
The total number of bits to be shifted in either an IR shift or a DR shift. This
value should be equal to the sum of all the length values specified in the SLD_SIM_ACTION string

SIM_N_SCAN:
Specifies the number of shifts in the simulation model

example:
select index 7f
$jseq drshift -state IDLE -hex 36 7f00000001    (0,2, 010000007f,24)

I:6,D:32:FFFFFFF,D:32:FFFFFFFF to jtag

$jseq drshift -state IDLE -hex 36 0600000002    (0,2, 0200000006,24)

$jseq drshift -state IDLE -hex 36 ff00000004    (0,2, 04000000ff,24)

	parameter SIM_ACTION = "((1,1,7,3),(0,2,ff,20),(0,1,6,3),(0,2,ffffffff,20),(0,2,1,20),(0,2,2,20),(0,2,3,20),(0,2,4,20))";  
	parameter SIM_N_SCAN=8;
    	parameter SIM_LENGTH=198;

   


*/

	
    parameter SIM_ACTION = "((1,1,7,3),(0,2,010000007f,24),(0,2,0200000006,24),(0,2,04000000ff,24))";  
    parameter SIM_N_SCAN=4;
    parameter SIM_LENGTH=3*36+3;



`endif
