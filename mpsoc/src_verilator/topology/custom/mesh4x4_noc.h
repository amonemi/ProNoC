



void topology_connect_all_nodes (void){
   	 //Connect R8 input ports 0 to  T8 output ports 0
	connect_r2e(1,0,0,8);
//Connect R8 input ports 1 to  R9 output ports 3
	conect_r2r(1,0,1,1,1,3);
//Connect R8 input ports 2 to  R4 output ports 4
	conect_r2r(1,0,2,1,8,4);
//Connect R8 port 3 to  ground
	connect_r2gnd(1,0,3);
//Connect R8 input ports 4 to  R12 output ports 2
	conect_r2r(1,0,4,1,12,2);
//Connect R9 input ports 0 to  T9 output ports 0
	connect_r2e(1,1,0,9);
//Connect R9 input ports 1 to  R10 output ports 3
	conect_r2r(1,1,1,1,2,3);
//Connect R9 input ports 2 to  R5 output ports 4
	conect_r2r(1,1,2,1,9,4);
//Connect R9 input ports 3 to  R8 output ports 1
	conect_r2r(1,1,3,1,0,1);
//Connect R9 input ports 4 to  R13 output ports 2
	conect_r2r(1,1,4,1,13,2);
//Connect R10 input ports 0 to  T10 output ports 0
	connect_r2e(1,2,0,10);
//Connect R10 input ports 1 to  R11 output ports 3
	conect_r2r(1,2,1,1,3,3);
//Connect R10 input ports 2 to  R6 output ports 4
	conect_r2r(1,2,2,1,10,4);
//Connect R10 input ports 3 to  R9 output ports 1
	conect_r2r(1,2,3,1,1,1);
//Connect R10 input ports 4 to  R14 output ports 2
	conect_r2r(1,2,4,1,14,2);
//Connect R11 input ports 0 to  T11 output ports 0
	connect_r2e(1,3,0,11);
//Connect R11 port 1 to  ground
	connect_r2gnd(1,3,1);
//Connect R11 input ports 2 to  R7 output ports 4
	conect_r2r(1,3,2,1,11,4);
//Connect R11 input ports 3 to  R10 output ports 1
	conect_r2r(1,3,3,1,2,1);
//Connect R11 input ports 4 to  R15 output ports 2
	conect_r2r(1,3,4,1,15,2);
//Connect R0 input ports 0 to  T0 output ports 0
	connect_r2e(1,4,0,0);
//Connect R0 input ports 1 to  R1 output ports 3
	conect_r2r(1,4,1,1,5,3);
//Connect R0 port 2 to  ground
	connect_r2gnd(1,4,2);
//Connect R0 port 3 to  ground
	connect_r2gnd(1,4,3);
//Connect R0 input ports 4 to  R4 output ports 2
	conect_r2r(1,4,4,1,8,2);
//Connect R1 input ports 0 to  T1 output ports 0
	connect_r2e(1,5,0,1);
//Connect R1 input ports 1 to  R2 output ports 3
	conect_r2r(1,5,1,1,6,3);
//Connect R1 port 2 to  ground
	connect_r2gnd(1,5,2);
//Connect R1 input ports 3 to  R0 output ports 1
	conect_r2r(1,5,3,1,4,1);
//Connect R1 input ports 4 to  R5 output ports 2
	conect_r2r(1,5,4,1,9,2);
//Connect R2 input ports 0 to  T2 output ports 0
	connect_r2e(1,6,0,2);
//Connect R2 input ports 1 to  R3 output ports 3
	conect_r2r(1,6,1,1,7,3);
//Connect R2 port 2 to  ground
	connect_r2gnd(1,6,2);
//Connect R2 input ports 3 to  R1 output ports 1
	conect_r2r(1,6,3,1,5,1);
//Connect R2 input ports 4 to  R6 output ports 2
	conect_r2r(1,6,4,1,10,2);
//Connect R3 input ports 0 to  T3 output ports 0
	connect_r2e(1,7,0,3);
//Connect R3 port 1 to  ground
	connect_r2gnd(1,7,1);
//Connect R3 port 2 to  ground
	connect_r2gnd(1,7,2);
//Connect R3 input ports 3 to  R2 output ports 1
	conect_r2r(1,7,3,1,6,1);
//Connect R3 input ports 4 to  R7 output ports 2
	conect_r2r(1,7,4,1,11,2);
//Connect R4 input ports 0 to  T4 output ports 0
	connect_r2e(1,8,0,4);
//Connect R4 input ports 1 to  R5 output ports 3
	conect_r2r(1,8,1,1,9,3);
//Connect R4 input ports 2 to  R0 output ports 4
	conect_r2r(1,8,2,1,4,4);
//Connect R4 port 3 to  ground
	connect_r2gnd(1,8,3);
//Connect R4 input ports 4 to  R8 output ports 2
	conect_r2r(1,8,4,1,0,2);
//Connect R5 input ports 0 to  T5 output ports 0
	connect_r2e(1,9,0,5);
//Connect R5 input ports 1 to  R6 output ports 3
	conect_r2r(1,9,1,1,10,3);
//Connect R5 input ports 2 to  R1 output ports 4
	conect_r2r(1,9,2,1,5,4);
//Connect R5 input ports 3 to  R4 output ports 1
	conect_r2r(1,9,3,1,8,1);
//Connect R5 input ports 4 to  R9 output ports 2
	conect_r2r(1,9,4,1,1,2);
//Connect R6 input ports 0 to  T6 output ports 0
	connect_r2e(1,10,0,6);
//Connect R6 input ports 1 to  R7 output ports 3
	conect_r2r(1,10,1,1,11,3);
//Connect R6 input ports 2 to  R2 output ports 4
	conect_r2r(1,10,2,1,6,4);
//Connect R6 input ports 3 to  R5 output ports 1
	conect_r2r(1,10,3,1,9,1);
//Connect R6 input ports 4 to  R10 output ports 2
	conect_r2r(1,10,4,1,2,2);
//Connect R7 input ports 0 to  T7 output ports 0
	connect_r2e(1,11,0,7);
//Connect R7 port 1 to  ground
	connect_r2gnd(1,11,1);
//Connect R7 input ports 2 to  R3 output ports 4
	conect_r2r(1,11,2,1,7,4);
//Connect R7 input ports 3 to  R6 output ports 1
	conect_r2r(1,11,3,1,10,1);
//Connect R7 input ports 4 to  R11 output ports 2
	conect_r2r(1,11,4,1,3,2);
//Connect R12 input ports 0 to  T12 output ports 0
	connect_r2e(1,12,0,12);
//Connect R12 input ports 1 to  R13 output ports 3
	conect_r2r(1,12,1,1,13,3);
//Connect R12 input ports 2 to  R8 output ports 4
	conect_r2r(1,12,2,1,0,4);
//Connect R12 port 3 to  ground
	connect_r2gnd(1,12,3);
//Connect R12 port 4 to  ground
	connect_r2gnd(1,12,4);
//Connect R13 input ports 0 to  T13 output ports 0
	connect_r2e(1,13,0,13);
//Connect R13 input ports 1 to  R14 output ports 3
	conect_r2r(1,13,1,1,14,3);
//Connect R13 input ports 2 to  R9 output ports 4
	conect_r2r(1,13,2,1,1,4);
//Connect R13 input ports 3 to  R12 output ports 1
	conect_r2r(1,13,3,1,12,1);
//Connect R13 port 4 to  ground
	connect_r2gnd(1,13,4);
//Connect R14 input ports 0 to  T14 output ports 0
	connect_r2e(1,14,0,14);
//Connect R14 input ports 1 to  R15 output ports 3
	conect_r2r(1,14,1,1,15,3);
//Connect R14 input ports 2 to  R10 output ports 4
	conect_r2r(1,14,2,1,2,4);
//Connect R14 input ports 3 to  R13 output ports 1
	conect_r2r(1,14,3,1,13,1);
//Connect R14 port 4 to  ground
	connect_r2gnd(1,14,4);
//Connect R15 input ports 0 to  T15 output ports 0
	connect_r2e(1,15,0,15);
//Connect R15 port 1 to  ground
	connect_r2gnd(1,15,1);
//Connect R15 input ports 2 to  R11 output ports 4
	conect_r2r(1,15,2,1,3,4);
//Connect R15 input ports 3 to  R14 output ports 1
	conect_r2r(1,15,3,1,14,1);
//Connect R15 port 4 to  ground
	connect_r2gnd(1,15,4);

}

void topology_init(void){
	router1[0]->current_r_addr=0;
router1[1]->current_r_addr=1;
router1[2]->current_r_addr=2;
router1[3]->current_r_addr=3;
router1[4]->current_r_addr=4;
router1[5]->current_r_addr=5;
router1[6]->current_r_addr=6;
router1[7]->current_r_addr=7;
router1[8]->current_r_addr=8;
router1[9]->current_r_addr=9;
router1[10]->current_r_addr=10;
router1[11]->current_r_addr=11;
router1[12]->current_r_addr=12;
router1[13]->current_r_addr=13;
router1[14]->current_r_addr=14;
router1[15]->current_r_addr=15;

}
