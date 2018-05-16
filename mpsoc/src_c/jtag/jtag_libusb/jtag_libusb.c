#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdint.h>
#include <unistd.h> // getopt
#include <inttypes.h>
#include <string.h>
#include "jtag.h"

/* You may want to change the VENDOR_ID and PRODUCT_ID
 * depending on your device.
 */
#define VENDOR_ID      0x09fb   // Altera
#define PRODUCT_ID     0x6001   // usb blaster (DE2-115) 
// Altera usb blaster  product IDs "6001", "6002", "6003", MODE="0666"   
// dose not work for USB-Blaster II "6010", "6810"
// run ./list_usb_dev  to see the list of all usb devices' vid and pid

unsigned usb_blaster_id = PRODUCT_ID; 


#define UPDATE_WB_ADDR  0x7
#define UPDATE_WB_WR_DATA  0x6
#define UPDATE_WB_RD_DATA  0x5
#define RD_WR_STATUS	0x4

#define BIT_NUM		(word_width<<3)	
#define BYTE_NUM	 word_width	
/* Global vars */
unsigned int index_num=126;
unsigned int word_width=4; // 
unsigned int write_verify=0;
unsigned int memory_offset=0;
unsigned int memory_boundary=0xFFFFFFFF;



char * binary_file_name=0;
char enable_binary_send=0;
char enable_binary_read=0;
char * write_data=0;




/* functions */
int send_binary_file();
int read_mem();
void usage();
void processArgs (int , char** );
int send_data ();
int hexcut( char *  , unsigned *  , int  );
int vdr_large (unsigned , char * , char *);
void hexgen( char * , unsigned *, int );

int main(int argc, char **argv) {
	//unsigned bits;
	//unsigned int val;
	
	//unsigned bits;
	//unsigned val;
	
	processArgs (argc, argv );	
	printf("index num=%u\n",index_num);
	if (jtag_open_virtual_device(index_num,VENDOR_ID,usb_blaster_id)){
		fprintf (stderr, "Error openning jtag IP with %d index num\n",index_num);
		return -1;
	}
	if (enable_binary_send) {
		if( send_binary_file() == -1) return -1;
	}
	
	if (write_data!=0){	
		printf("send %s to jtag\n",write_data);	
		send_data();
		

	}

	return 0;
}



void usage(){

	printf ("usage:./jtag_main [-n	index number] [-i file_name][-c][-s rd/wr offset address][-d string]\n");
	printf ("\t-a	product_id in hex: Altera usb blasterI  product IDs \"6001\", \"6002\", \"6003\" . The default value is 0x6001\n");  
 	printf ("\t-n	index number: the target jtag IP core index number. The default number is 126\n");  
	printf ("\t-i	file_name:  input binary file name (.bin file)\n");
	printf ("\t-r	read memory content and display in terminal\n");
	printf ("\t-w	bin file word width in byte. default is 4 bytes (32 bits)\n");
	printf ("\t-c	verify after write\n");
	printf ("\t-s	memory wr/rd offset address in byte (hex format). The default value is 0x0000000\n");
	printf ("\t-e	memory  boundary address in byte (hex format).  The default value is 0xFFFFFFFF\n");
	printf ("\t-d	string: use for setting instruction or data value to jtag tap.  string format : \"instr1,instr2,...,instrn\"\n \tinstri = I:instruct_num: send instruct_num to instruction register \n \tD:data_size_in_bit:data : send data in hex to data register\n  \tR:data_size_in_bit:data : Read data register and show it on screan then write given data in hex to data register\n");
		
}

void processArgs (int argc, char **argv )
{
   char c;
int p;

   /* don't want getopt to moan - I can do that just fine thanks! */
   opterr = 0;
   if (argc < 2)  usage();	
   while ((c = getopt (argc, argv, "s:a:e:d:n:i:w:cr")) != -1)
      {
	 switch (c)
	    {
	    case 'a':
		p=sscanf(optarg,"%x",&usb_blaster_id);
		if( p==0){
			 fprintf (stderr, "invalid usb_blaster_id format `%s'.\n", optarg);
			 usage();
			 exit(1);
		}else if(usb_blaster_id == 0x6010 ||  usb_blaster_id ==0x6810 ){
			 fprintf (stderr, "%x is a usbblasterII id which is not supported. Please use jtag_quartus_stp for usbblaster II\n", usb_blaster_id);
			 usage();
			 exit(1);
		}

	    case 'n':	/* index number */
	       index_num = atoi(optarg);
	       break;
	    case 'i':	/* input binary file name */
		binary_file_name = optarg;
		enable_binary_send=1;
		break;
	     case 'r':	/* read memory */
		enable_binary_read=1;
		break;
	    case 'w':	/* word width in byte */
		word_width= atoi(optarg);
		break;
	    case 'c':	/* enable write verify */
		write_verify= 1;
		break;
	    case 'd':	/* send string */
		write_data= optarg;		
		break;
	    case 's':	/* set offset address*/
		
		p=sscanf(optarg,"%x",&memory_offset);
		if( p==0){
			 fprintf (stderr, "invalid memory offset adress format `%s'.\n", optarg);
			 usage();
			 exit(1);
		}
		//printf("p=%d,memory_offset=%x\n",p,memory_offset);		
		break;
	    case 'e':	/* word width in byte */
		p=sscanf(optarg,"%x",&memory_boundary);
		if( p==0){
			 fprintf (stderr, "invalid memory boundary adress format `%s'.\n", optarg);
			 usage();
			 exit(1);
		}		
		break;

	    case '?':
	       if (isprint (optopt))
		  fprintf (stderr, "Unknown option `-%c'.\n", optopt);
	       else
		  fprintf (stderr,
			   "Unknown option character `\\x%x'.\n",
			   optopt);
	    default:
	       usage();
	       exit(1);
	    }
      }
}

unsigned * read_file (FILE * fp, unsigned int  * n ){
	
	unsigned * buffer;
	unsigned val;
	unsigned char ch;
	unsigned int i=0;
	char cnt=0;
	unsigned int num=0;
	unsigned int width= (BYTE_NUM < sizeof(unsigned )) ? BYTE_NUM :  sizeof(unsigned ); //max is 4 then
	fseek(fp, 0, SEEK_END); // seek to end of file
	num = ftell(fp); // get current file pointer
	*n=num;// number of bytes from the beginning of the file	


	num=(num/width)+2;
	fseek(fp, 0, SEEK_SET);
	//printf ("num=%u\n",num);	
	buffer = (unsigned *) malloc(num * sizeof(unsigned ) );  //memory allocated using malloc
    	if(buffer == NULL)                     
    	{
        	printf("Error! memory not allocated.");
       		exit(0);
   	}
	ch=fgetc(fp);
	
	while(!feof(fp)){		
		val<<=8;		
		val|=ch;
		cnt++;
		//printf("ch=%x\t",ch);
		if(cnt==width){
			//printf("%d:%x\n",i,val);
			buffer[i] = val;
			val=0;
			cnt=0;
			i++;
		}
		ch=fgetc(fp);
	}
	if( cnt>0){
		val<<=(8 *(width-cnt));
		printf("%d:%x\n",i,val);
		buffer[i] = val;
		
	}

return buffer;

}



int send_data ()
{  
	char * pch;
	char string[100];
	int bit=0,  inst=0, d=0;
	char out[100];
	pch = strtok (write_data,",");
	printf("%s\n",pch);
	while (pch != NULL)
	{
		while(1){
			 d=1;
			if(sscanf( pch, "D:%d:%s", &bit, string )) break;
			if(sscanf( pch, "d:%d:%s", &bit, string )) break;
			//if(sscanf( pch, "D:%d:" PRIx64  , &bit, &data )) break;
			//if(sscanf( pch, "d:%d:%016x", &bit, &data )) break;
			 d=2;
			if(sscanf( pch, "R:%d:%s",&bit, string)) break;
			if(sscanf( pch, "r:%d:%s",&bit, string)) break;
			 d=0;
			if(sscanf( pch, "I:%d", &inst)) break;
			if(sscanf( pch, "i:%d", &inst)) break;
			printf("invalid format : %s\n",pch);
			return -1;

		}
		if(d==1){
			//printf ("(bit=%d, data=%s)",bit, string);
			//jtag_vdr(bit, data, 0);
			vdr_large(bit,string,0);
		}if(d==2){

			vdr_large(bit,string,out);
			printf("###read data#%s###read data#\n",out);
		}else{
			
			jtag_vir(inst);
			//printf("%d\n",inst);
		}
		
		pch = strtok (NULL, ",");
		
  	}
  return 0;
}

int compare_values( unsigned * val1, unsigned * val2, int words, unsigned int address){

	int i,error=0;
	for(i=0;i<words;i++){
		if (val1[i] != val2[i]) error=1;
	}
	if(error){
		 printf ("Error: missmatched at location %d. Expected 0X",address);
		 for(i=0;i<words;i++) printf("%08X",val1[i] );
		 printf (" but read 0X");
		 for(i=0;i<words;i++) printf("%08X",val2[i] );
		 printf ("\n");

	}
	return error;


}

void reorder_buffer(unsigned * buff, unsigned int words){
	unsigned tmp;
	unsigned int i;
	for(i=0;i<words/2;i++){
		tmp= buff[i];
		buff[i]=buff[i+words-1];
		buff[i+words-1]=tmp;
	}
}




int send_binary_file(){
	FILE *fp;
	int i=0;	
	unsigned out;
	unsigned int file_size=0;
	unsigned int num=0;
	unsigned int mem_size;
	unsigned int memory_offset_in_word;
	unsigned * small_buff;
	int words= (BYTE_NUM % sizeof(unsigned )) ? (BYTE_NUM / sizeof(unsigned ) )+1 : (BYTE_NUM / sizeof(unsigned ));

	small_buff = (unsigned *) malloc(words * sizeof(unsigned ) ); 
	unsigned *  read_buff;
	read_buff  = (unsigned *) calloc(words , sizeof(unsigned ) );
	

	printf("send %s to the wishbone bus\n",binary_file_name);
	fp = fopen(binary_file_name,"rb");
	if (!fp) {
		fprintf (stderr,"Error: can not open %s file in read mode\n",binary_file_name);
		return -1;
	}
	unsigned * buffer;
	buffer=read_file (fp, &file_size);
	mem_size=memory_boundary-memory_offset;
	if(file_size>mem_size){
		printf("\n\n Warning:  %s file size (%x) is larger than the given memory size (%x). I will stop writing on end of memory address\n\n",binary_file_name,file_size,mem_size);
		file_size=mem_size;
	}
	fclose(fp);
	//disable the cpu
	jtag_vir(RD_WR_STATUS);
	jtag_vdr(BIT_NUM, 0x1, &out);
	//getchar();
	jtag_vir(UPDATE_WB_ADDR);
	// change memory sizes from byte to word	
	memory_offset_in_word=memory_offset /BYTE_NUM;
	//size of buffer
	num= (BYTE_NUM < sizeof(unsigned )) ? file_size /BYTE_NUM : file_size /sizeof(unsigned );

	jtag_vdr(BIT_NUM, memory_offset_in_word, 0);
	jtag_vir(UPDATE_WB_WR_DATA);
	
	printf ("start programing\n");
	//printf ("num=%d\n",num);
	for(i=0;i<num;i++){
		//printf("%d:%x\n",i,*buffer +i);
		if(BYTE_NUM <= sizeof(unsigned )){
			jtag_vdr(BIT_NUM, buffer[i], 0);
		}else {
			reorder_buffer(&buffer[i],words);
			jtag_vdr_long(BIT_NUM, &buffer[i], 0, words);
			i+= (words-1);

		}
		

	}
		
	//printf ("done programing\n");
	if(write_verify){
		if(!(fp = fopen(binary_file_name,"rb"))){  
			fprintf (stderr,"Error: can not open %s file in read mode\n",binary_file_name);
			return -1;
		}
		buffer=read_file (fp, &file_size);



		//fclose(fp);
		jtag_vir(UPDATE_WB_RD_DATA);
		jtag_vdr(BIT_NUM, memory_offset_in_word+0, &out);
		
		
		
		if(BYTE_NUM <= sizeof(unsigned )){
			for(i=1;i<=num; i++){
				jtag_vdr(BIT_NUM, memory_offset_in_word+i, &out); 
				if(out!=buffer[i-1]) printf ("Error: missmatched at location %d. Expected %x but read %x\n",i-1,buffer[i-1], out);
			}
		}
		else{
			for(i=words;i<=num; i+=words){
				read_buff[0]= memory_offset_in_word+i/words;
				jtag_vdr_long(BIT_NUM, read_buff, small_buff, words);
				reorder_buffer(&buffer[i-words],words);
				compare_values(&buffer[i-words],small_buff,words,i/words-1);
				 
			}

		}
		printf ("write is verified\n");
		
	}
	//enable the cpu
	jtag_vir(RD_WR_STATUS);
	jtag_vdr(BIT_NUM, 0, &out);
	//printf ("status=%x\n",out);
	free(buffer);
	return 0;
}

void print_values( unsigned * val2, int words){
		 int i;
		 for(i=0;i<words;i++) printf("%08X",val2[words-i-1] );
		 printf ("\n");
}



int read_mem(){
	int i=0;
	unsigned int num=0;
	unsigned int mem_size;
	unsigned int memory_offset_in_word;
	unsigned out;
	unsigned * small_buff;
	int words= (BYTE_NUM % sizeof(unsigned )) ? (BYTE_NUM / sizeof(unsigned ) )+1 : (BYTE_NUM / sizeof(unsigned ));
	
	small_buff = (unsigned *) malloc(words * sizeof(unsigned ) ); 
	unsigned *  read_buff;
	read_buff  = (unsigned *) calloc(words , sizeof(unsigned ) );
	memory_offset_in_word=memory_offset /BYTE_NUM;
	mem_size=memory_boundary-memory_offset;
	num= (BYTE_NUM < sizeof(unsigned )) ? mem_size /BYTE_NUM : mem_size /sizeof(unsigned );

	jtag_vir(UPDATE_WB_RD_DATA);
	jtag_vdr(BIT_NUM, memory_offset_in_word+0, &out);
	
	printf("\n###read data#\n");
	
	if(BYTE_NUM <= sizeof(unsigned )){
		for(i=1;i<=num; i++){
			jtag_vdr(BIT_NUM, memory_offset_in_word+i, &out); 
			printf("%X\n",out);
		}	
	}
	else{
		for(i=words;i<=num; i+=words){
			read_buff[0]= memory_offset_in_word+i/words;
			jtag_vdr_long(BIT_NUM, read_buff, small_buff, words);
			print_values(small_buff, words);
				 
		}

	}
		
	
			
	printf("\n###read data#\n");
			
	//enable the cpu
	jtag_vir(RD_WR_STATUS);
	jtag_vdr(BIT_NUM, 0, &out);
	//printf ("status=%x\n",out);
	free(read_buff);
	return 0;
}



int vdr_large (unsigned sz, char * string, char *out){
	int words= (sz%32)? (sz/32)+1 : sz/32;
	unsigned  val[64],val_o[64];
	//printf("data=%s\n",string);
	hexcut(string, val, words );
	
	
	if( out == 0) return  jtag_vdr_long(sz,val,0,words);
	int u=	jtag_vdr_long(sz,val,val_o,words);
	
	hexgen( out, val_o, words );
	
	return u;
	
}



int hexcut( char * hexstring, unsigned * val, int words ){
    size_t count = 0;
    int start;
      	
    if (*(hexstring+1)=='x' || *(hexstring+1)=='X') hexstring+=2;
    int size=strlen(hexstring);
    int hexnum= (size%8)? (size/8)+1 : size/8;
    for(count = 0; count < words; count++) val[count]=0;  
   
    for(count = 1; count <= hexnum; count++) {
	start=(count*8>size)? 0 : size-count*8;
	
        sscanf(hexstring+start, "%08x", &val[count-1]);
        *(hexstring+start)=0;
    }

  //  printf("size=%d, hexnum=%u\n",size,hexnum);
  
	
    return hexnum;
}


void hexgen( char * hexstring, unsigned * val, int words ){
    size_t count = 0;
    sprintf(hexstring,"0x");
    for(count = 0; count < words; count++) {
	if(count == 0)  sprintf((hexstring+2),"%x",val[words-count-1]);
	else 		sprintf(hexstring,"%08x",val[words-count-1]); 
	 hexstring+=strlen(hexstring);
   }

 // return hexnum;
}


