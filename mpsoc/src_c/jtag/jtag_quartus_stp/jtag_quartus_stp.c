#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdint.h>
#include <unistd.h> // getopt
#include <inttypes.h>
#include <string.h>
#include "jtag.h"



/* functions */
int send_binary_file();
int read_mem();
void usage();
void processArgs (int , char** );
int send_data ();
int hexcut( char *  , unsigned *  , int  );
void vdr_large (unsigned , char * , char *);
void hexgen( char * , unsigned *, int );

int main(int argc, char **argv) {
		
	processArgs (argc, argv );	
	printf("index num=%u\n",index_num);
	printf("Initial Vjtag for %s & %s\n",hardware_name,dev_num);
	if (jtag_init(hardware_name,dev_num)){
		fprintf (stderr, "Error openning jtag IP with %d index num\n",index_num);
		return -1;
	}
	if (enable_binary_send) {
		if( send_binary_file() == -1) return -1;
	}

	if  (enable_binary_read){
		if( read_mem() == -1) return -1;

	}
	
	if (write_data!=0){	
		printf("send %s to jtag\n",write_data);	
		send_data();
		

	}

	return 0;
}



void usage(){

	printf ("usage:./jtag_main [-n	index number] [-i file_name][-c][-s rd/wr offset address][-d string]\n");
	printf ("\t-a	hardware_name to be matched: i.e. \"DE-SoC *\" for den10-nano or \"USB-Blaster*\" for de0-nano \n");  
	printf ("\t-b	device number in chain: i.e. \"@2*\" for den10-nano (second dev in chain) or \"@1*\" for de0-nano (first dev in chain)\n");  
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
   while ((c = getopt (argc, argv, "s:e:d:n:i:w:a:b:cr")) != -1)
      {
	 switch (c)
	    {
	    case 'a':	/* hardware_name */
	       hardware_name = optarg;
	       break;
	    case 'b':	/* device number in chain */
	       dev_num = optarg;
	       break;


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
	    case 'e':	/* wmemory  boundary address */
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
	//printf("%s\n",pch);
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
			//printf ("(bit=%d, data=%s)\n",bit, string);
			//jtag_vdr(bit, data, 0);
			vdr_large(bit,string,0);
		}if(d==2){

			vdr_large(bit,string,out);
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

void print_values( unsigned * val2, int words){
		 int i;
		 for(i=0;i<words;i++) printf("%08X",val2[words-i-1] );
		 printf ("\n");
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
		//printf("%d:%x\n",i,buffer[i]);
		
		if(BYTE_NUM <= sizeof(unsigned )){
			//printf("%d:%x\n",i,buffer[i]);
			jtag_vdr(BIT_NUM, buffer[i], 0);
		}else {
			//printf("%d:%x\n",i,buffer[i]);
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
		jtag_vdr(BIT_NUM,memory_offset_in_word+0, &out);
		jtag_vdr(BIT_NUM,memory_offset_in_word+1, &out);
		
		
		if(BYTE_NUM <= sizeof(unsigned )){
			//printf("vdr\n");
			for(i=2;i<=num; i++){
				jtag_vdr(BIT_NUM, memory_offset_in_word+i, &out); 
				if(out!=buffer[i-2]) printf ("Error: missmatched at location %d. Expected %x but read %x\n",i-2,buffer[i-2], out);
			}
			jtag_vdr(BIT_NUM, 0, &out);
			if(out!=buffer[i-2]) printf ("Error: missmatched at location %d. Expected %x but read %x\n",i-2,buffer[i-2], out);i++;
			jtag_vdr(BIT_NUM, 1, &out);
			if(out!=buffer[i-2]) printf ("Error: missmatched at location %d. Expected %x but read %x\n",i-2,buffer[i-2], out);

		}
		else{
			//printf("vdr_long\n");
			for(i=2*words;i<=num; i+=words){
				read_buff[0]= memory_offset_in_word+i/words;
				jtag_vdr_long(BIT_NUM, read_buff, small_buff, words);
				reorder_buffer(&buffer[i-2*words],words);
				compare_values(&buffer[i-2*words],small_buff,words,i/words);
				 
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
	jtag_vdr(BIT_NUM, memory_offset_in_word+1, &out);
	
	printf("\n###read data#\n");	
		
	if(BYTE_NUM <= sizeof(unsigned )){
			//printf("vdr\n");
			for(i=2;i<=num; i++){
				jtag_vdr(BIT_NUM, memory_offset_in_word+i, &out); 
				printf("%X\n",out);	
			}
			jtag_vdr(BIT_NUM, 0, &out);
			printf("%X\n",out);	
			
			jtag_vdr(BIT_NUM, 1, &out);
			printf("%X\n",out);	
			

		}
		else{
			//printf("vdr_long\n");
			for(i=2*words;i<=num+2; i+=words){
				//printf("%d,%d,%d\n",i,words,num);
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



void vdr_large (unsigned sz, char * string, char *out){
	int words= (sz%32)? (sz/32)+1 : sz/32;
	unsigned  val[64],val_o[64];
	//printf("data=%s\t",string);
	hexcut(string, val, words );
	
	
	if( out == 0) {
		  jtag_vdr_long(sz,val,0,words);
		return;
	}
	jtag_vdr_long(sz,val,val_o,words);
	//printf("rdata=%s\n",out);
	hexgen( out, val_o, words );
	
	
	
}






