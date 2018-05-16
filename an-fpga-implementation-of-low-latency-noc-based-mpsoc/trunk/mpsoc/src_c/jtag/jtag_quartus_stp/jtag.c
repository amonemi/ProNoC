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











#define DEFAULT_TM4HOST "DE-SoC *"
#define DEFAULT_TMNUM	2




FILE *to_stp, *from_stp;



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

void hextostring( char * hexstring, unsigned * val, int words,unsigned sz){
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

   int digits=(sz%4)? sz/4 +1 : sz/4 ;
   //printf("%d > %d", digits , strlen(tmp));
   if (digits > strlen(tmp)){
	for(count = 0; count < digits-strlen(tmp); count++) {
		zeros[count]='0';
  	 }
	zeros[count]=0;
	strcat(zeros,tmp);
	sprintf(hexstring,"%s",zeros);

   }else{
	sprintf(hexstring,"%s",tmp);

   }
  
   

 // return hexnum;
}




int jtag_init(char *hrdname, char *dvicname ) {

   /* Create a quartus_stp process, and get the list of ports */

   int  f_to_stp, f_from_stp;
   char buf[1024];
   char *command[] = {"quartus_stp", "-s", 0};

   if(from_stp != (FILE *) NULL) {
      fclose(from_stp);
      fclose(to_stp);      
   }

   piped_child(command, &f_from_stp, &f_to_stp);

   from_stp = fdopen(f_from_stp, "r");
   to_stp = fdopen(f_to_stp, "w");

   if(from_stp == (FILE *) NULL || to_stp == (FILE *) NULL) {
      fprintf(stderr, "jtag_init: can't communicate with quartus_stp process\n");
      fclose(from_stp);
      fclose(to_stp);
      from_stp = (FILE *) NULL;
      to_stp = (FILE *) NULL;
      return(1);
   }

  

   while(1) {
      fgets(buf, sizeof(buf), from_stp);
	if(strstr(buf, "ERROR") != NULL) {
    		printf("\tERROR\n");
		printf("'%s'\n", buf);
		exit(1);
	}


       
      if(!strcmp(buf, "\n"))
         break;
      if(feof(from_stp)) {
         fprintf(stderr, "saw eof from quartus_stp\n");
         exit(1);
      }

      if(ferror(from_stp)) {
         fprintf(stderr, "saw error from quartus_stp\n");
         exit(1);
      }
   } 

   fprintf(to_stp, "foreach name [get_hardware_names] {\n");
   fprintf(to_stp, "  puts $name\n");
   fprintf(to_stp, "  if { [string match \"*%s*\" $name] } {\n", hrdname);
   fprintf(to_stp, "    set hardware_name $name\n");
   fprintf(to_stp, "  }\n");
   fprintf(to_stp, "}\n");
   fprintf(to_stp, "puts \"\\nhardware_name is $hardware_name\";\n");
   fprintf(to_stp, "foreach name [get_device_names -hardware_name $hardware_name] {\n");
   fprintf(to_stp, "  if { [string match \"*%s*\" $name] } {\n",dvicname);
   fprintf(to_stp, "    set chip_name $name\n");
   fprintf(to_stp, "  }\n");
   fprintf(to_stp, "}\n");
   fprintf(to_stp, "puts \"device_name is $chip_name\\n\";\n");
   fprintf(to_stp, "open_device -hardware_name $hardware_name -device_name $chip_name\n");
   
   fflush(to_stp);

   while(1) {
      fgets(buf, sizeof(buf), from_stp);
     
	if(strstr(buf, "ERROR") != NULL) {
    		printf("\tERROR\n");
		printf("'%s'\n", buf);
		exit(1);
	}

      if(!strcmp(buf, "\n"))
         break;
      if(feof(from_stp)) {
         fprintf(stderr, "saw eof from quartus_stp\n");
         exit(1);
      }
      if(ferror(from_stp)) {
         fprintf(stderr, "saw error from quartus_stp\n");
         exit(1);
      }
   } 
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

char * read_stp (){
	char buf[1024];
	char * result=NULL;
	fflush(to_stp);
	while(1) {
		fgets(buf, sizeof(buf), from_stp);	     
		if(strstr(buf, "ERROR") != NULL) {
	    		printf("\tERROR\n");
			printf("'%s'\n", buf);
			exit(1);
		}
		if(strstr(buf, "RESULT:") != NULL) {
	    		result=strstr(buf, "RESULT:");
			
			break;
			
		}

		if(!strcmp(buf, "\n")) 	 break;
		if(feof(from_stp)) {
			fprintf(stderr, "saw eof from quartus_stp\n");
			exit(1);
		}
		if(ferror(from_stp)) {
			fprintf(stderr, "saw error from quartus_stp\n");
			exit(1);
	      }
	} 
	if(result){
		char * r= result+7;
		strreplace(r, '\n', 0);
		return r;
	}
	return 0;
}




void return_dr (unsigned *out) {
	
	char *ptr;
	fprintf(to_stp,"puts \"RESULT:$data\"\n");
	ptr=read_stp();
	//printf("saw: '%s'\n", ptr);
	while(*ptr=='t' || *ptr=='c'  || *ptr=='l' || *ptr=='>' || *ptr==' ' ) ptr++;
	
	*out= strtol(ptr,NULL,16);
}

void return_dr_long (unsigned *out, int words) {
	
	char *ptr;
	fprintf(to_stp,"puts \"RESULT:$data\"\n");
	ptr=read_stp();
	//printf("saw: '%s'\n", ptr);
	while(*ptr=='t' || *ptr=='c'  || *ptr=='l' || *ptr=='>' || *ptr==' ' ) ptr++;
	
	hexcut( ptr, out, words );	
}


void jtag_vir(unsigned vir) {
	fprintf(to_stp,"device_lock -timeout 10000\n");
	fprintf(to_stp,"device_virtual_ir_shift -instance_index %d -ir_value %x -no_captured_ir_value\n",index_num,vir);
	fprintf(to_stp,"catch {device_unlock}\n");
}


void jtag_vdr(unsigned sz, unsigned bits, unsigned *out) {
	char hexstring[1000];	
		
	hextostring( hexstring, &bits,  1, sz );
	if (!out){
		fprintf(to_stp,"device_lock -timeout 10000\n");
		fprintf(to_stp,"device_virtual_dr_shift -dr_value %s -instance_index %d  -length %d -no_captured_dr_value -value_in_hex\n", hexstring,index_num,sz);
		//printf("device_virtual_dr_shift -dr_value %s -instance_index %d  -length %d -no_captured_dr_value -value_in_hex\n",hexstring,index_num,sz);
		fprintf(to_stp,"catch {device_unlock}\n");
	}else{
		fprintf(to_stp,"device_lock -timeout 10000\n");
		fprintf(to_stp,"set data [device_virtual_dr_shift -dr_value %s -instance_index %d  -length %d  -value_in_hex]\n", hexstring,index_num,sz);
		fprintf(to_stp,"catch {device_unlock}\n");		
		return_dr (out);
	}
}

void jtag_vdr_long(unsigned sz, unsigned * bits, unsigned *out, int words) {
	char hexstring[1000];	
	
	hextostring( hexstring, bits,  words, sz );

	if (!out){
		fprintf(to_stp,"device_lock -timeout 10000\n");
		fprintf(to_stp,"device_virtual_dr_shift -dr_value %s -instance_index %d  -length %d -no_captured_dr_value -value_in_hex\n",hexstring,index_num,sz);
		//printf("device_virtual_dr_shift -dr_value %s -instance_index %d  -length %d -no_captured_dr_value -value_in_hex\n",hexstring,index_num,sz);

		fprintf(to_stp,"catch {device_unlock}\n");
	}else{
		fprintf(to_stp,"device_lock -timeout 10000\n");
		fprintf(to_stp,"set data [device_virtual_dr_shift -dr_value %s -instance_index %d  -length %d  -value_in_hex]\n",hexstring,index_num,sz);
		fprintf(to_stp,"catch {device_unlock}\n");		
		return_dr_long (out,words);
	}
	
}


void closeport(){
	fprintf(to_stp,"catch {device_unlock}\n");
	fprintf(to_stp,"catch {close_device}\n");
	fflush(to_stp);
}



#ifdef DEBUG_JTAG

void turn_on_led(){
	unsigned out;
	fprintf(to_stp, "device_lock -timeout 10000\n");
	fprintf(to_stp,"device_virtual_ir_shift -instance_index 127 -ir_value 1 -no_captured_ir_value\n");
	fprintf(to_stp,"device_virtual_dr_shift -dr_value 3 -instance_index 127  -length 2 -no_captured_dr_value -value_in_hex\n");
	//fprintf(to_stp,"device_virtual_dr_shift -dr_value 0 -instance_index 127  -length 2 -no_captured_dr_value -value_in_hex\n");
	fprintf(to_stp,"catch {device_unlock}\n");
	jtag_vdr(2, 0, &out);
	fprintf(to_stp, "device_lock -timeout 10000\n");
	fprintf(to_stp,"device_virtual_ir_shift -instance_index 127 -ir_value 0 -no_captured_ir_value\n");

	printf("outs= %d \n",out);
	fprintf(to_stp,"catch {device_unlock}\n");
	fflush(to_stp);
	//run();

}


void turn_off_led(){
	unsigned out;
	fprintf(to_stp, "device_lock -timeout 10000\n");
	fprintf(to_stp,"device_virtual_ir_shift -instance_index 127 -ir_value 1 -no_captured_ir_value\n");
	fprintf(to_stp,"device_virtual_dr_shift -dr_value 3 -instance_index 127  -length 2 -no_captured_dr_value -value_in_hex\n");
	//fprintf(to_stp,"device_virtual_dr_shift -dr_value 2 -instance_index 127  -length 2 -no_captured_dr_value -value_in_hex\n");
	fprintf(to_stp,"catch {device_unlock}\n");
	jtag_vdr(2, 3, &out);
	fprintf(to_stp, "device_lock -timeout 10000\n");
	printf("outs= %d \n",out);
	fprintf(to_stp,"device_virtual_ir_shift -instance_index 127 -ir_value 0 -no_captured_ir_value\n");
	//fprintf(to_stp, "puts \"device_name is $chip_name\\n\";\n");
	fprintf(to_stp,"catch {device_unlock}\n");
	fflush(to_stp);
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
	fclose(from_stp);
	fclose(to_stp);
	from_stp = (FILE *) NULL;
	to_stp = (FILE *) NULL;

	return 0;



}

#endif


