#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdint.h>
#include <inttypes.h>


#include <unistd.h>
#include "jtag.h"

#define VIR_CTRL	0x0
#define VIR_ADDR	0x1
#define VIR_DATA	0x2
#define VIR_UART	0x7


#define UPDATE_WB_ADDR  0x7
#define UPDATE_WB_WR_DATA  0x6
#define UPDATE_WB_RD_DATA  0x5
#define RD_WR_STATUS	0x4

int main(int argc, char **argv) {
	//unsigned bits;
	//unsigned int val;
	
	//unsigned bits;
	uint32_t val;
	FILE *fp;

	if (argc != 2) {
		fprintf(stderr,"usage: download bin file\n");
		return -1;
	}
	fp = fopen(argv[1],"rb");
	if (!fp) return -1;

	if (jtag_open_virtual_device(126))
		return -1;

	
	int i=0;	
	unsigned int out;
//disable the cpu
	jtag_vir(RD_WR_STATUS);
	jtag_vdr(32, 0xFFFFFFFF, &out);
	printf ("status=%x\n",out);
	getchar();
//
	jtag_vir(UPDATE_WB_WR_DATA);
	unsigned char ch;
	char cnt=0;
	val=0;
	ch=fgetc(fp);
	while(!feof(fp)){		
		val<<=8;		
		val|=ch;
		cnt++;
		printf("ch=%x\t",ch);
		if(cnt==4){
			printf("%d:%x\n",i,val);
			jtag_vdr(32, val, 0);
			val=0;
			cnt=0;
			i++;
		}
		ch=fgetc(fp);
	}
	if( cnt>0){
		val<<=(8 *(4-cnt));
		printf("%d:%x\n",i,val);
		jtag_vdr(32, val, 0);
		
	}

	
	getchar();
/*	
	printf ("start=\n");
	jtag_vir(UPDATE_WB_ADDR);
	jtag_vdr(32, 0, 0);
	jtag_vir(UPDATE_WB_WR_DATA);

	for(i=0;i<1000; i++){
		//printf ("addr=\n");
		//scanf("%x", &val);
		
		jtag_vdr(32, 2*i, 0);
		//jtag_vdr(32, 0, &out);
		//printf ("out=%x\n",out);
		
		printf ("data=\n");
		scanf("%x", &val);
		jtag_vir(UPDATE_WB_WR_DATA);
		jtag_vdr(32, val, 0);

		printf ("data=\n");
		scanf("%x", &val);
		jtag_vdr(32, val, 0);

		printf ("data=\n");
		scanf("%x", &val);
		jtag_vdr(32, val, 0);

		
	}
*/
	printf ("done programing\n");
	jtag_vir(UPDATE_WB_RD_DATA);
	jtag_vdr(32, 0, &out);
	for(i=1;i<1001; i++){
		jtag_vdr(32, i, &out);
		printf ("out[%d]=%x\n",i-1,out);


	}

	jtag_vir(RD_WR_STATUS);
	jtag_vdr(32, 0, &out);
	printf ("status=%x\n",out);
	for (;;) {
		/*		
		jtag_vdr(9, 0, &bits);
		if (bits & 0x100) {
			bits &= 0xFF;
			if ((bits < ' ') || (bits > 127))
				fputc('.', stderr);
			else
				fputc(bits, stderr);
		}
		*/	
	}
	
	return 0;
}

