

 #define TNUM_0 1
 #define RNUM_0 0
 #define TNUM_1 1
 #define RNUM_1 1
 #define TNUM_2 1
 #define RNUM_2 2
 #define TNUM_3 1
 #define RNUM_3 3
 #define TNUM_4 2
 #define RNUM_4 0
 #define TNUM_5 2
 #define RNUM_5 1
 #define TNUM_6 2
 #define RNUM_6 2
 #define TNUM_7 2
 #define RNUM_7 3
 #define TNUM_8 2
 #define RNUM_8 4
 #define TNUM_9 2
 #define RNUM_9 5
 #define TNUM_10 2
 #define RNUM_10 6
 #define TNUM_11 2
 #define RNUM_11 7
 #define TNUM_12 3
 #define RNUM_12 0
 #define TNUM_13 3
 #define RNUM_13 1
 #define TNUM_14 3
 #define RNUM_14 2
 #define TNUM_15 3
 #define RNUM_15 3


void topology_connect_all_nodes (void){
   	 	connect_r2e(TNUM_0,RNUM_0,0,0);
	conect_r2r(TNUM_0,RNUM_0,1,TNUM_10,RNUM_10,3);
	conect_r2r(TNUM_0,RNUM_0,2,TNUM_9,RNUM_9,3);
	connect_r2e(TNUM_1,RNUM_1,0,1);
	conect_r2r(TNUM_1,RNUM_1,1,TNUM_7,RNUM_7,3);
	conect_r2r(TNUM_1,RNUM_1,2,TNUM_2,RNUM_2,2);
	connect_r2e(TNUM_2,RNUM_2,0,2);
	conect_r2r(TNUM_2,RNUM_2,1,TNUM_11,RNUM_11,2);
	conect_r2r(TNUM_2,RNUM_2,2,TNUM_1,RNUM_1,2);
	connect_r2e(TNUM_3,RNUM_3,0,3);
	conect_r2r(TNUM_3,RNUM_3,1,TNUM_11,RNUM_11,3);
	conect_r2r(TNUM_3,RNUM_3,2,TNUM_4,RNUM_4,2);
	connect_r2e(TNUM_4,RNUM_4,0,4);
	conect_r2r(TNUM_4,RNUM_4,1,TNUM_13,RNUM_13,2);
	conect_r2r(TNUM_4,RNUM_4,2,TNUM_3,RNUM_3,2);
	conect_r2r(TNUM_4,RNUM_4,3,TNUM_6,RNUM_6,3);
	connect_r2e(TNUM_5,RNUM_5,0,5);
	conect_r2r(TNUM_5,RNUM_5,1,TNUM_15,RNUM_15,4);
	conect_r2r(TNUM_5,RNUM_5,2,TNUM_6,RNUM_6,2);
	conect_r2r(TNUM_5,RNUM_5,3,TNUM_9,RNUM_9,2);
	connect_r2e(TNUM_6,RNUM_6,0,6);
	conect_r2r(TNUM_6,RNUM_6,1,TNUM_13,RNUM_13,3);
	conect_r2r(TNUM_6,RNUM_6,2,TNUM_5,RNUM_5,2);
	conect_r2r(TNUM_6,RNUM_6,3,TNUM_4,RNUM_4,3);
	connect_r2e(TNUM_7,RNUM_7,0,7);
	conect_r2r(TNUM_7,RNUM_7,1,TNUM_8,RNUM_8,3);
	conect_r2r(TNUM_7,RNUM_7,2,TNUM_10,RNUM_10,2);
	conect_r2r(TNUM_7,RNUM_7,3,TNUM_1,RNUM_1,1);
	connect_r2e(TNUM_8,RNUM_8,0,8);
	conect_r2r(TNUM_8,RNUM_8,1,TNUM_12,RNUM_12,4);
	conect_r2r(TNUM_8,RNUM_8,2,TNUM_14,RNUM_14,3);
	conect_r2r(TNUM_8,RNUM_8,3,TNUM_7,RNUM_7,1);
	connect_r2e(TNUM_9,RNUM_9,0,9);
	conect_r2r(TNUM_9,RNUM_9,1,TNUM_12,RNUM_12,2);
	conect_r2r(TNUM_9,RNUM_9,2,TNUM_5,RNUM_5,3);
	conect_r2r(TNUM_9,RNUM_9,3,TNUM_0,RNUM_0,2);
	connect_r2e(TNUM_10,RNUM_10,0,10);
	conect_r2r(TNUM_10,RNUM_10,1,TNUM_12,RNUM_12,3);
	conect_r2r(TNUM_10,RNUM_10,2,TNUM_7,RNUM_7,2);
	conect_r2r(TNUM_10,RNUM_10,3,TNUM_0,RNUM_0,1);
	connect_r2e(TNUM_11,RNUM_11,0,11);
	conect_r2r(TNUM_11,RNUM_11,1,TNUM_14,RNUM_14,4);
	conect_r2r(TNUM_11,RNUM_11,2,TNUM_2,RNUM_2,1);
	conect_r2r(TNUM_11,RNUM_11,3,TNUM_3,RNUM_3,1);
	connect_r2e(TNUM_12,RNUM_12,0,12);
	conect_r2r(TNUM_12,RNUM_12,1,TNUM_15,RNUM_15,1);
	conect_r2r(TNUM_12,RNUM_12,2,TNUM_9,RNUM_9,1);
	conect_r2r(TNUM_12,RNUM_12,3,TNUM_10,RNUM_10,1);
	conect_r2r(TNUM_12,RNUM_12,4,TNUM_8,RNUM_8,1);
	connect_r2e(TNUM_13,RNUM_13,0,13);
	conect_r2r(TNUM_13,RNUM_13,1,TNUM_15,RNUM_15,3);
	conect_r2r(TNUM_13,RNUM_13,2,TNUM_4,RNUM_4,1);
	conect_r2r(TNUM_13,RNUM_13,3,TNUM_6,RNUM_6,1);
	conect_r2r(TNUM_13,RNUM_13,4,TNUM_14,RNUM_14,2);
	connect_r2e(TNUM_14,RNUM_14,0,14);
	conect_r2r(TNUM_14,RNUM_14,1,TNUM_15,RNUM_15,2);
	conect_r2r(TNUM_14,RNUM_14,2,TNUM_13,RNUM_13,4);
	conect_r2r(TNUM_14,RNUM_14,3,TNUM_8,RNUM_8,2);
	conect_r2r(TNUM_14,RNUM_14,4,TNUM_11,RNUM_11,1);
	connect_r2e(TNUM_15,RNUM_15,0,15);
	conect_r2r(TNUM_15,RNUM_15,1,TNUM_12,RNUM_12,1);
	conect_r2r(TNUM_15,RNUM_15,2,TNUM_14,RNUM_14,1);
	conect_r2r(TNUM_15,RNUM_15,3,TNUM_13,RNUM_13,1);
	conect_r2r(TNUM_15,RNUM_15,4,TNUM_5,RNUM_5,1);

}
