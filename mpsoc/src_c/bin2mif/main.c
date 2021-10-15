
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <ctype.h>

#define DEFAULT_OUT_FILE_NAME		"out0.mif"


char *in_file_name,  *out_file_name;
int mem_width = 32;


void usage (void)
{
	printf("Usage: ./bin2mif  <options>  \n");
	printf("\nOptions: \n");
	printf("         -w <file name>: memory width in bits.\n");
	printf("         -f <file name>: input bin file name.\n");
	printf("         -o <file name>: output mif file name.\n");	
}


void processArgs (int argc, char **argv )
{
   char c;  

     opterr = 0;

   while ((c = getopt (argc, argv, "f:o:hw:")) != -1)
      {
	 switch (c)
	    {
	 	
		case 'f':	
			in_file_name = optarg;
			break;
		case 'o':
			out_file_name =  optarg;
			break;
	    case 'w':
	      	sscanf(optarg, "%u", &mem_width);
			break;
		case 'h':
			usage();
		       	exit(1);
			break;
		case '?':
	     	  if (isprint (optopt))
			  fprintf (stderr, "Unknown option `-%c'.\n", optopt);
	     	  else
			  fprintf (stderr,   "Unknown option character `\\x%x'.\n",   optopt);
		default:
		       	usage();
		       	exit(1);
	    }
      }
}




int main ( int argc, char **argv ){
	 FILE *fin, *fout;
	 unsigned int sz_byte;
	 unsigned int sz_word;
	 int c; 
	 char buff[100];
	
	processArgs (argc,argv );
	unsigned int byte_num_in_word = (mem_width/8);
	
	if (in_file_name == NULL) {usage();exit(1);} 	
	if (out_file_name == NULL) out_file_name = DEFAULT_OUT_FILE_NAME;	
	
	fin = fopen(in_file_name, "rb");
	if (fin == NULL)
    {
      printf("Error while opening the file %s.\n",in_file_name);
      exit(EXIT_FAILURE);
    }
    fout=fopen(out_file_name,"wb");
	if(fout==NULL){printf("Erro Output file cannot be created %s\n",out_file_name); exit(1);}
    
	
	//get bin file size
	fseek(fin, 0L, SEEK_END);
	sz_byte = ftell(fin);
	sz_word = (sz_byte % byte_num_in_word)==0 ? sz_byte/byte_num_in_word : sz_byte/byte_num_in_word +1;
	fseek(fin, 0L, SEEK_SET);	
	
	
	fprintf(fout,"-- Copyright (C) 2013 Alireza Monemi\n\n");
	fprintf(fout,"WIDTH=%u;\nDEPTH=%d;\nADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\n\nCONTENT BEGIN\n", mem_width,sz_word);
	int i,j;
	for(i=0;i<sz_word;i++){
		fprintf(fout,"\t%X\t:\t" , i);
		for(j=0;j<byte_num_in_word;j++){
			buff[(j+1)*2]=0;
			c=fgetc(fin);
			if( feof(fin) ) {
				break ;
			}
			sprintf(buff+(j*2),"%02X" , c);
		}
	    fprintf(fout,"%s;\n",buff);	
	}
	
	
	fprintf(fout,"END;\n");
	
	fclose(fin);
	fclose(fout);	
	

}

