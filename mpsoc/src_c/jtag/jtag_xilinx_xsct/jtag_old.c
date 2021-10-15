/* A library of routines that will talk to a design using
 * Altera's virtual_jtag interface.
 * The design must contain a communications layer like the
 * one that tmjportmux_gen creates.
 */

#include <sys/types.h>
#include <sys/stat.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "jtag.h"
#include "pipe.c"



//#define DEBUG_JTAG
//#define PRINT_TO_XSCT




FILE *to_xsct, *from_xsct;

#ifdef PRINT_TO_XSCT
FILE *to_xsct_file;
#endif


int hexcut( char * hexstring, unsigned * val, int words ){
    size_t count = 0;
    int start;
    char word[8];
    
    if (*(hexstring+1)=='x' || *(hexstring+1)=='X') hexstring+=2;
    int size=strlen(hexstring);
    int hexnum= (size%8)? (size/8)+1 : size/8;
    for(count = 0; count < words; count++) val[count]=0;  
    //printf("hexstring=%s\n",hexstring);	
    for(count = 1; count <= hexnum; count++) {
	start=(count*8>size)? 0 : size-(count*8);
	//start=0;
	//ptr=hexstring+start;
	strncpy( word, hexstring+start,8);
	//printf("** %s\n,",word);        
	sscanf(word, "%08x", &val[count-1]);
       // *(hexstring+start)=0;
	//printf("%x,",val[count-1]);
    }

   //printf("\nsize=%d, hexnum=%u\n",size,hexnum);
  
	
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


void jtag_reorder ( char * string_in, char *string_out ) {
 
  int size = strlen(string_in);
  int i;
  for (i=0;i<size;i+=2){
	 string_out[i]=   string_in[size-i-2];
	 string_out[i+1]= string_in[size-i-1];
  }	
   string_out[i]=0;
}


unsigned char h_to_i ( unsigned char in){
 
	if (in >= '0' && in <= '9') {
          return (in - '0');
         
        }
     if (in >= 'A' && in <= 'F') {
            return  (in - 'A' + 10);
            
        }
     return in - 'a' + 10;
 } 

void add_update_state (char * hexstring, unsigned char update_code,unsigned sz ){
	if(sz%4 == 0){
		sprintf (&hexstring[sz/4],"%x", update_code);
		return;
	}
	
	unsigned char s1 = sz%4;
	unsigned char s2 = 4-s1; 
	unsigned char u1 = update_code>>s2;
	unsigned char u2 = update_code<<s1 & 0xf; 
	unsigned char m  = (s1==1)? 0x01 : (s1==2)? 0x3 :  (s1==3)?  0x7: 0xf;
	unsigned char u3 =  h_to_i(hexstring[(sz/4)-1]) & m;
	u2 = u2 | u3;
	char tmp[2];
	sprintf (tmp,"%x", u1);
	hexstring[(sz/4)]=(unsigned char)tmp[0];
	sprintf (tmp, "%x",u2); 
    	hexstring[(sz/4)-1]=(unsigned char)tmp[0];
	
}	


void hextostring_xsct( char * hexstring, unsigned * val, int words,unsigned sz){
    size_t count = 0;

    char tmp[100];
    char zeros[100];
    char *pointer = tmp;
   
    //sprintf(hexstring,"0x");
  
    for(count = 0; count < words; count++) {
	if(count == 0)  sprintf(pointer,"%x",val[words-count-1]);
	else 		sprintf(pointer,"%08x",val[words-count-1]); 
	pointer+=strlen(pointer);
   }
   unsigned o=sz/8;
   
   sz = (sz%8)? (o+1)*8:sz;// size needed to be multiplaction of 8 in xsct
   int digits= sz/4 ;
   char * buff;
   buff = (char *) malloc(sz+1);
   
   //printf("%d > %d", digits , strlen(tmp));
   if (digits > strlen(tmp)){
	for(count = 0; count < digits-strlen(tmp); count++) {
		zeros[count]='0';
  	 }
	zeros[count]=0;
	strcat(zeros,tmp);
	sprintf(buff,"%s",zeros);

   }else{
	sprintf(buff,"%s",tmp);

   }
   jtag_reorder(buff,hexstring);
}



//char end_tcl [10] = { 0x1b, 0x5b,[2]=30,[3]=6d,[4]=a,

char* remove_color_code_from_string ( char *buf, int z){
	int i=0;
	char * ptr=buf;	
	if( *ptr != 0x1b ) return ptr;
        do{
		ptr ++;
		i++;		
	} while ((*ptr != 'm') && (*ptr != 0x0) && i<z-1);
	ptr ++;
	return ptr;
} 



void check_error_xsct_out(char * buf){
	char * err_message[] = {"ERROR","error:","target list is empty","invalid","no target(s) with id:","can't read",NULL}; 
	int i=0;
	//printf("buff:%s\n",buf);	
	while (err_message[i] !=NULL){
		if(strstr(buf, err_message[i]) != NULL) {
	    		printf("\tERROR\n");
			printf("'%s'\n", buf);
			exit(1);
		}	 
		i++;	
	}
}



void wait_for_pipe_output(char* buf,  const char * out){

 while(1) {
      //printf("check error\n"); 
      fflush(to_xsct);
      fgets(buf,200, from_xsct); 
      check_error_xsct_out(buf);
      //printf("b=%s\n",buf);

      if(strstr(buf, out) != NULL) return;
     // if(!strcmp(ptr, "\n")) break;
      if(feof(from_xsct)) {
         fprintf(stderr, "saw eof from xsct\n");
         exit(1);
      }
      if(ferror(from_xsct)) {
         fprintf(stderr, "saw error from xsct\n");
         exit(1);
      }
	
   } 


} 



int jtag_init( ) {

//update chain code value
  chain_code=
		(chain_num==1)? 0x02:
		(chain_num==2)? 0x03:
		(chain_num==3)? 0x22:
		0x23;	


#ifdef PRINT_TO_XSCT
	to_xsct_file = fopen("to_xsct.txt", "a");
	if (to_xsct_file == NULL) {
        	printf("Error!");
        	exit(1);
    	}
#endif


   /* Create a xsct process, and connect t jtag device */

   int  f_to_xsct, f_from_xsct;
   char buf[1024];
  // char * ptr;
   char *command[] = {"xsdb", "-interactive", 0};

   if(from_xsct != (FILE *) NULL) {
      fclose(from_xsct);
      fclose(to_xsct);      
   }

   piped_child(command, &f_from_xsct, &f_to_xsct);

   from_xsct = fdopen(f_from_xsct, "r");
   to_xsct = fdopen(f_to_xsct, "w");

   if(from_xsct == (FILE *) NULL || to_xsct == (FILE *) NULL) {
      fprintf(stderr, "jtag_init: can't communicate with xilinx xsct process\n");
      fclose(from_xsct);
      fclose(to_xsct);
      from_xsct = (FILE *) NULL;
      to_xsct = (FILE *) NULL;
      return(1);
   }
  

   while(1) {
     
       fgets(buf, sizeof(buf), from_xsct);    
       check_error_xsct_out(buf);
	

      if(!strcmp(buf, "\n")){
         fgets(buf, sizeof(buf), from_xsct); 
          //fgets(buf, sizeof(buf), from_xsct); 
         if(!strcmp(buf, "\n")) break;   
	
	}
      
     
      if(feof(from_xsct)) {
         fprintf(stderr, "saw eof from xsct. Make sure path to xsxt is included in PATH linuc enviremet\n");
         exit(1);
      }

      if(ferror(from_xsct)) {
         fprintf(stderr, "saw error from xsct\n");
         exit(1);
      }
   } 
   
   printf("connecting to jtag  and select index %x\n",index_num);	 
   fprintf(to_xsct, "set jseq [jtag sequence]\n");
   fprintf(to_xsct, "connect\n");
   wait_for_pipe_output( buf, "tcfchan");

   //printf("select jtag target\n"); 
   fprintf(to_xsct, "jtag targets %u; puts done\n",jtag_target_number);
   //fprintf(to_xsct, "jtag frequency 5000000");
   wait_for_pipe_output( buf, "done");
   //printf("Done!\n"); 
#ifdef PRINT_TO_XSCT
   fprintf(to_xsct_file, "set jseq [jtag sequence]\n");
   fprintf(to_xsct_file, "connect\n");
   fprintf(to_xsct_file, "jtag targets %u puts done\n",jtag_target_number);
  
#endif


//
  
  
	


 
	return 0;
  
}


void strreplace(char s[], char chr, char repl_chr)
{
     int i=0;
     while(s[i]!='\0')
     {
           if(s[i]==chr)
           {
               s[i]=repl_chr;
           }  
           i++; 
     }
          //printf("%s",s);
}


void  clean_xsct_buff (){
	char buf[2024];
	fprintf(to_xsct,"puts \"hi\"\n"); 
#ifdef PRINT_TO_XSCT
	fprintf(to_xsct_file,"puts \"hi\"\n"); 
#endif
	fflush(to_xsct);
	fgets(buf, sizeof(buf), from_xsct);
        check_error_xsct_out(buf);
	//printf("clean:%s\n",buf);
}

void remove_state( char * r){
	int s = strlen(r);
	r[s-2]=0;// remove the last byte

}

char * read_xsct (){
	char buf[2024];
	char * out;
	char * result=NULL;
	//char * ptr;
	fflush(to_xsct);
	while(1) {
		fgets(buf, sizeof(buf), from_xsct);
        //printf ("rdbuf=%s\n",buf);
		//ptr=remove_color_code_from_string(buf,sizeof(buf));	     
		check_error_xsct_out(buf);
		if(strstr(buf, "RESULT:") != NULL) {
	    	result=strstr(buf, "RESULT:");
			break;
		}

		if(!strcmp(buf, "\n")) break;
		//if(!strcmp(ptr, "\n")) break;

		if(feof(from_xsct)) {
			fprintf(stderr, "saw eof from xsct\n");
			exit(1);
		}
		if(ferror(from_xsct)) {
			fprintf(stderr, "saw error from xsct\n");
			exit(1);
	      }
	} 
	if(result){
		char * r= result+7;
		strreplace(r, '\n', 0);
		remove_state(r);
		out =(char*)malloc( sizeof(r)+2);

		jtag_reorder ( r, out );
		return out;
	}
	return 0;
}




void return_dr (unsigned *out) {
	
	char *ptr;
	fprintf(to_xsct,"puts \"RESULT:$data\"\n");
#ifdef PRINT_TO_XSCT
	fprintf(to_xsct_file,"puts \"RESULT:$data\"\n");
#endif
	ptr=read_xsct();
	//printf("saw: '%s'\n", ptr);
	//while(*ptr=='t' || *ptr=='c'  || *ptr=='l' || *ptr=='>' || *ptr==' ' ) ptr++;
	
	*out= strtol(ptr,NULL,16);
}

void return_dr_long (unsigned *out, int words) {
	
	char *ptr;
	fprintf(to_xsct,"puts \"RESULT:$data\"\n");
#ifdef PRINT_TO_XSCT
	fprintf(to_xsct_file,"puts \"RESULT:$data\"\n");
#endif
	ptr=read_xsct();
	//printf("saw: '%s'\n", ptr);
	//while(*ptr=='t' || *ptr=='c'  || *ptr=='l' || *ptr=='>' || *ptr==' ' ) ptr++;
	
	hexcut( ptr, out, words );	
}


void send_to_jtag (char * hexstring) {
	fprintf(to_xsct,"$jseq clear\n");                                                               
	fprintf(to_xsct,"$jseq irshift -state IDLE -hex 6 %x\n",chain_code);                 
	fprintf(to_xsct,"$jseq drshift -state IDLE -hex %u %s\n",jtag_shift_reg_size,hexstring);                  
	//printf("$jseq drshift -state IDLE -hex %u %s\n",jtag_shift_reg_size,hexstring);
	fprintf(to_xsct,"$jseq run\n");

#ifdef PRINT_TO_XSCT
	fprintf(to_xsct_file,"$jseq clear\n");                                                               
	fprintf(to_xsct_file,"$jseq irshift -state IDLE -hex 6 %x\n",chain_code);                 
	fprintf(to_xsct_file,"$jseq drshift -state IDLE -hex %u %s\n",jtag_shift_reg_size,hexstring);                  
	fprintf(to_xsct_file,"$jseq run\n");
#endif

	//fflush(to_xsct);       
}


void send_capture_jtag (char * hexstring) {
	fprintf(to_xsct,"$jseq clear\n");                                                               
	fprintf(to_xsct,"$jseq irshift -state IDLE -hex 6 %x\n",chain_code);                 
	fprintf(to_xsct,"$jseq drshift -state IDLE -capture -hex %u %s\n",jtag_shift_reg_size,hexstring);  
	//printf("$jseq drshift -state IDLE -capture -hex %u %s\n",jtag_shift_reg_size,hexstring);
	fprintf(to_xsct,"set data [$jseq run]\n"); 
	//fflush(to_xsct);     
#ifdef PRINT_TO_XSCT
	fprintf(to_xsct_file,"$jseq clear\n");                                                               
	fprintf(to_xsct_file,"$jseq irshift -state IDLE -hex 6 %x\n",chain_code);                  
	fprintf(to_xsct_file,"$jseq drshift -state IDLE -capture -hex %u %s\n",jtag_shift_reg_size,hexstring);  
	fprintf(to_xsct_file,"set data [$jseq run]\n"); 
#endif

  
}


void jtag_vindex(unsigned vindex) {

	//fprintf(to_xsct,"device_lock -timeout 10000\n");
	char hexstring[1000];	
	unsigned bits [10];
	bits [0] = vindex;
	hextostring_xsct( hexstring, bits,  WORDS_NUM, jtag_shift_reg_size ); 	
	add_update_state (hexstring,UPDATE_INDEX,jtag_shift_reg_size);
	send_to_jtag (hexstring); 
	clean_xsct_buff ();      
}






void jtag_vir(unsigned vir) {

	//fprintf(to_xsct,"device_lock -timeout 10000\n");
	char hexstring[1000];	
	unsigned bits [10];
	bits [0] = vir;
	hextostring_xsct( hexstring, bits,  WORDS_NUM, jtag_shift_reg_size ); 	
	add_update_state (hexstring,UPDATE_IR,jtag_shift_reg_size);
	send_to_jtag (hexstring);
	clean_xsct_buff ();
}





void jtag_vdr(unsigned sz, unsigned bits, unsigned *out) {
	char hexstring[1000];	
		
	hextostring_xsct( hexstring, &bits,  WORDS_NUM, jtag_shift_reg_size );
	add_update_state (hexstring,UPDATE_DAT,jtag_shift_reg_size);
	if (!out){
		send_to_jtag (hexstring);     
		clean_xsct_buff();			
	}else{
		send_capture_jtag(hexstring);
		return_dr (out);
	}
}

void jtag_vdr_long(unsigned sz, unsigned * bits, unsigned *out, int words) {
	char hexstring[1000];	
	
	hextostring_xsct( hexstring, bits,  words, jtag_shift_reg_size );
	add_update_state (hexstring,UPDATE_DAT,jtag_shift_reg_size);

	if (!out){
  		//printf("send_to_jtag (%s)\n",hexstring);
		send_to_jtag (hexstring);
		clean_xsct_buff();	
	}else{
		//printf("send_capture_to_jtag (%s)\n",hexstring);
		send_capture_jtag(hexstring);		
		return_dr_long (out,words);
	}
	
}


void closeport(){
	fprintf(to_xsct,"exit\n");
#ifdef PRINT_TO_XSCT
	fprintf(to_xsct_file,"exit\n");
#endif
	fflush(to_xsct);
}



#ifdef DEBUG_JTAG

void turn_on_led(){
	unsigned out;
	fprintf(to_xsct, "device_lock -timeout 10000\n");
	fprintf(to_xsct,"device_virtual_ir_shift -instance_index 127 -ir_value 1 -no_captured_ir_value\n");
	fprintf(to_xsct,"device_virtual_dr_shift -dr_value 3 -instance_index 127  -length 2 -no_captured_dr_value -value_in_hex\n");
	//fprintf(to_xsct,"device_virtual_dr_shift -dr_value 0 -instance_index 127  -length 2 -no_captured_dr_value -value_in_hex\n");
	fprintf(to_xsct,"catch {device_unlock}\n");
	jtag_vdr(2, 0, &out);
	fprintf(to_xsct, "device_lock -timeout 10000\n");
	fprintf(to_xsct,"device_virtual_ir_shift -instance_index 127 -ir_value 0 -no_captured_ir_value\n");

	printf("outs= %d \n",out);
	fprintf(to_xsct,"catch {device_unlock}\n");
	fflush(to_xsct);
	//run();

}


void turn_off_led(){
	unsigned out;
	fprintf(to_xsct, "device_lock -timeout 10000\n");
	fprintf(to_xsct, "device_virtual_ir_shift -instance_index 127 -ir_value 1 -no_captured_ir_value\n");
	fprintf(to_xsct, "device_virtual_dr_shift -dr_value 3 -instance_index 127  -length 2 -no_captured_dr_value -value_in_hex\n");
	//fprintf(to_xsct,"device_virtual_dr_shift -dr_value 2 -instance_index 127  -length 2 -no_captured_dr_value -value_in_hex\n");
	fprintf(to_xsct,"catch {device_unlock}\n");
	jtag_vdr(2, 3, &out);
	fprintf(to_xsct, "device_lock -timeout 10000\n");
	printf("outs= %d \n",out);
	fprintf(to_xsct,"device_virtual_ir_shift -instance_index 127 -ir_value 0 -no_captured_ir_value\n");
	//fprintf(to_xsct, "puts \"device_name is $chip_name\\n\";\n");
	fprintf(to_xsct,"catch {device_unlock}\n");
	fflush(to_xsct);
	//run();
}





int main(){
	int c=0;
	jtag_init("DE-SoC *","@2*"); // fpr DE10-nano
	while (c==0 || c== 1){
		 printf("Enter 1: to on, 0: to off, else to quit:\n");
		 scanf ("%d",&c);
		 if(c==0){printf("\toff\n"); turn_off_led();}
		 else if (c== 1){printf("\ton\n"); turn_on_led();}
		 else break;
		
	}
 
	closeport();
	fclose(from_xsct);
	fclose(to_xsct);
	from_xsct = (FILE *) NULL;
	to_xsct = (FILE *) NULL;

	return 0;



}

#endif


