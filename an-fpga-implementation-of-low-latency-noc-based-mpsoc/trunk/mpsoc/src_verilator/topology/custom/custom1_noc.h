



void topology_connect_all_nodes (void){
   	 //Connect R0 input ports 0 to  T0 output ports 0
	connect_r2e(1,0,0,0);
//Connect R0 input ports 1 to  R14 output ports 3
	conect_r2r(1,0,1,2,6,3);
//Connect R0 input ports 2 to  R13 output ports 3
	conect_r2r(1,0,2,2,5,3);
//Connect R1 input ports 0 to  T1 output ports 0
	connect_r2e(1,1,0,1);
//Connect R1 input ports 1 to  R7 output ports 3
	conect_r2r(1,1,1,2,3,3);
//Connect R1 input ports 2 to  R2 output ports 2
	conect_r2r(1,1,2,1,2,2);
//Connect R2 input ports 0 to  T2 output ports 0
	connect_r2e(1,2,0,2);
//Connect R2 input ports 1 to  R15 output ports 2
	conect_r2r(1,2,1,2,7,2);
//Connect R2 input ports 2 to  R1 output ports 2
	conect_r2r(1,2,2,1,1,2);
//Connect R3 input ports 0 to  T3 output ports 0
	connect_r2e(1,3,0,3);
//Connect R3 input ports 1 to  R15 output ports 3
	conect_r2r(1,3,1,2,7,3);
//Connect R3 input ports 2 to  R4 output ports 2
	conect_r2r(1,3,2,2,0,2);
//Connect R4 input ports 0 to  T4 output ports 0
	connect_r2e(2,0,0,4);
//Connect R4 input ports 1 to  R9 output ports 2
	conect_r2r(2,0,1,3,1,2);
//Connect R4 input ports 2 to  R3 output ports 2
	conect_r2r(2,0,2,1,3,2);
//Connect R4 input ports 3 to  R6 output ports 3
	conect_r2r(2,0,3,2,2,3);
//Connect R5 input ports 0 to  T5 output ports 0
	connect_r2e(2,1,0,5);
//Connect R5 input ports 1 to  R11 output ports 4
	conect_r2r(2,1,1,3,3,4);
//Connect R5 input ports 2 to  R6 output ports 2
	conect_r2r(2,1,2,2,2,2);
//Connect R5 input ports 3 to  R13 output ports 2
	conect_r2r(2,1,3,2,5,2);
//Connect R6 input ports 0 to  T6 output ports 0
	connect_r2e(2,2,0,6);
//Connect R6 input ports 1 to  R9 output ports 3
	conect_r2r(2,2,1,3,1,3);
//Connect R6 input ports 2 to  R5 output ports 2
	conect_r2r(2,2,2,2,1,2);
//Connect R6 input ports 3 to  R4 output ports 3
	conect_r2r(2,2,3,2,0,3);
//Connect R7 input ports 0 to  T7 output ports 0
	connect_r2e(2,3,0,7);
//Connect R7 input ports 1 to  R12 output ports 3
	conect_r2r(2,3,1,2,4,3);
//Connect R7 input ports 2 to  R14 output ports 2
	conect_r2r(2,3,2,2,6,2);
//Connect R7 input ports 3 to  R1 output ports 1
	conect_r2r(2,3,3,1,1,1);
//Connect R12 input ports 0 to  T8 output ports 0
	connect_r2e(2,4,0,8);
//Connect R12 input ports 1 to  R8 output ports 4
	conect_r2r(2,4,1,3,0,4);
//Connect R12 input ports 2 to  R10 output ports 3
	conect_r2r(2,4,2,3,2,3);
//Connect R12 input ports 3 to  R7 output ports 1
	conect_r2r(2,4,3,2,3,1);
//Connect R13 input ports 0 to  T9 output ports 0
	connect_r2e(2,5,0,9);
//Connect R13 input ports 1 to  R8 output ports 2
	conect_r2r(2,5,1,3,0,2);
//Connect R13 input ports 2 to  R5 output ports 3
	conect_r2r(2,5,2,2,1,3);
//Connect R13 input ports 3 to  R0 output ports 2
	conect_r2r(2,5,3,1,0,2);
//Connect R14 input ports 0 to  T10 output ports 0
	connect_r2e(2,6,0,10);
//Connect R14 input ports 1 to  R8 output ports 3
	conect_r2r(2,6,1,3,0,3);
//Connect R14 input ports 2 to  R7 output ports 2
	conect_r2r(2,6,2,2,3,2);
//Connect R14 input ports 3 to  R0 output ports 1
	conect_r2r(2,6,3,1,0,1);
//Connect R15 input ports 0 to  T11 output ports 0
	connect_r2e(2,7,0,11);
//Connect R15 input ports 1 to  R10 output ports 4
	conect_r2r(2,7,1,3,2,4);
//Connect R15 input ports 2 to  R2 output ports 1
	conect_r2r(2,7,2,1,2,1);
//Connect R15 input ports 3 to  R3 output ports 1
	conect_r2r(2,7,3,1,3,1);
//Connect R8 input ports 0 to  T12 output ports 0
	connect_r2e(3,0,0,12);
//Connect R8 input ports 1 to  R11 output ports 1
	conect_r2r(3,0,1,3,3,1);
//Connect R8 input ports 2 to  R13 output ports 1
	conect_r2r(3,0,2,2,5,1);
//Connect R8 input ports 3 to  R14 output ports 1
	conect_r2r(3,0,3,2,6,1);
//Connect R8 input ports 4 to  R12 output ports 1
	conect_r2r(3,0,4,2,4,1);
//Connect R9 input ports 0 to  T13 output ports 0
	connect_r2e(3,1,0,13);
//Connect R9 input ports 1 to  R11 output ports 3
	conect_r2r(3,1,1,3,3,3);
//Connect R9 input ports 2 to  R4 output ports 1
	conect_r2r(3,1,2,2,0,1);
//Connect R9 input ports 3 to  R6 output ports 1
	conect_r2r(3,1,3,2,2,1);
//Connect R9 input ports 4 to  R10 output ports 2
	conect_r2r(3,1,4,3,2,2);
//Connect R10 input ports 0 to  T14 output ports 0
	connect_r2e(3,2,0,14);
//Connect R10 input ports 1 to  R11 output ports 2
	conect_r2r(3,2,1,3,3,2);
//Connect R10 input ports 2 to  R9 output ports 4
	conect_r2r(3,2,2,3,1,4);
//Connect R10 input ports 3 to  R12 output ports 2
	conect_r2r(3,2,3,2,4,2);
//Connect R10 input ports 4 to  R15 output ports 1
	conect_r2r(3,2,4,2,7,1);
//Connect R11 input ports 0 to  T15 output ports 0
	connect_r2e(3,3,0,15);
//Connect R11 input ports 1 to  R8 output ports 1
	conect_r2r(3,3,1,3,0,1);
//Connect R11 input ports 2 to  R10 output ports 1
	conect_r2r(3,3,2,3,2,1);
//Connect R11 input ports 3 to  R9 output ports 1
	conect_r2r(3,3,3,3,1,1);
//Connect R11 input ports 4 to  R5 output ports 1
	conect_r2r(3,3,4,2,1,1);

}

void topology_init(void){
	router1[0]->current_r_addr=0;
router1[1]->current_r_addr=1;
router1[2]->current_r_addr=2;
router1[3]->current_r_addr=3;
router2[0]->current_r_addr=4;
router2[1]->current_r_addr=5;
router2[2]->current_r_addr=6;
router2[3]->current_r_addr=7;
router2[4]->current_r_addr=8;
router2[5]->current_r_addr=9;
router2[6]->current_r_addr=10;
router2[7]->current_r_addr=11;
router3[0]->current_r_addr=12;
router3[1]->current_r_addr=13;
router3[2]->current_r_addr=14;
router3[3]->current_r_addr=15;

}
