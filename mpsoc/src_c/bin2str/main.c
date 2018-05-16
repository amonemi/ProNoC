#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <ctype.h>




void bin_str_convert();
void hex_str_convert();
char *remove_ext (char* , char , char );
char *add_ext (char* , char *); 


int bin_enable = 0;
int hex_enable = 0;
int data_width =32;
char * in_file_name;
char * out_file_name;

void usage (void)
{
	printf("Usage: ./bin2str  <options>  \n");
	printf("\nOptions: \n");
	printf("         -d : memory data width in bit. The default value is 32\n");
	printf("         -b : generate output file in Binary string.\n");
	printf("         -h : generate output file in Hex string.\n");
	printf("         -f <file name>: input bin file  .\n");
	printf("         -o <file name>: output ascii text file.\n");
	
}

void processArgs (int argc, char **argv )
{
   char c;  

     opterr = 0;

   while ((c = getopt (argc, argv, "bhd:f:o:")) != -1)
      {
	 switch (c)
	    {
		case 'd':
			data_width = atoi(optarg);	 	
		case 'b':	
			bin_enable = 1;
			break;
		case 'h':
			hex_enable = 1;
			break;
		case 'f':	
			in_file_name = optarg;
			break;
		case 'o':
			out_file_name =  optarg;
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




int main (int argc, char **argv ){
	
	
	processArgs (argc,argv );
	if (in_file_name == NULL) {usage();exit(1);} 	
	if (bin_enable == 0 && hex_enable == 0) {printf("No output file format is selected. One of -b or -h argumet is required.\n\n");usage();exit(1);} 
	if (data_width == 0 ) {printf("\'0\' is an invalid memory data width.\n\n");usage();exit(1);} 	
	if (out_file_name == NULL) {
		out_file_name= remove_ext (in_file_name, '.', '/');			
	}
	if (bin_enable )bin_str_convert();
	if (hex_enable )hex_str_convert();
	
	return 0;
}

void bin_str_convert(){
	FILE * fin;
	FILE * fout;
	char * out_name;
	char c;
	fin = fopen(in_file_name, "rb");
	
	int i, b,n=0;
	if (fin == NULL) {
		printf("   Can't open file '%s' for reading.\n", in_file_name);
		//return;
		exit(1);
	}
	out_name= add_ext (out_file_name, "memb");
	fout = fopen(out_name, "wb");
	if (fout == NULL) {
		printf("   Can't create file '%s'.\n", out_name);
		//return;
		exit(1);
	}
	while (!feof(fin) && !ferror(fin)) {
		c=fgetc( fin);
		for(i=0;i<8;i++){
			b=(c&0x80)? '1':'0';
			fprintf(fout,"%c",b);			
			c<<=1;
			n++;
			if(n==data_width) {
			n=0;
			fprintf(fout,"\n");	
			}
			
		}
		

	}
	if(n>0){
		for(i=n;i<data_width;i++){ fprintf(fout,"0");	}
		fprintf(fout,"\n");	
	}
	fclose(fin);
	fclose(fout);
}


void hex_str_convert(){
	FILE * fin;
	FILE * fout;
	char * out_name;
	char c;
	fin = fopen(in_file_name, "rb");
	
	int i, n=0;
	if (fin == NULL) {
		printf("   Can't open file '%s' for reading.\n", in_file_name);
		//return;
		exit(1);
	}
	out_name= add_ext (out_file_name, "hex");
	fout = fopen(out_name, "wb");
	if (fout == NULL) {
		printf("   Can't create file '%s'.\n", out_name);
		//return;
		exit(1);
	}
	while (!feof(fin) && !ferror(fin)) {
		c=fgetc( fin);
		fprintf(fout,"%02hhX",c);
		n+=8;	
		if(n==data_width) {
			n=0;
			fprintf(fout,"\n");	
		}
	}
	if(n>0){
		for(i=n;i<data_width;i+=8){ fprintf(fout,"00");	}
		fprintf(fout,"\n");	
	}
	fclose(fin);
	fclose(fout);
}


// remove_ext: removes the "extension" from a file spec.
//   mystr is the string to process.
//   dot is the extension separator.
//   sep is the path separator (0 means to ignore).
// Returns an allocated string identical to the original but
//   with the extension removed. It must be freed when you're
//   finished with it.
// If you pass in NULL or the new string can't be allocated,
//   it returns NULL.

char *remove_ext (char* mystr, char dot, char sep) {
    char *retstr, *lastdot, *lastsep;

    // Error checks and allocate string.

    if (mystr == NULL)
        return NULL;
    if ((retstr = malloc (strlen (mystr) + 1)) == NULL)
        return NULL;

    // Make a copy and find the relevant characters.

    strcpy (retstr, mystr);
    lastdot = strrchr (retstr, dot);
    lastsep = (sep == 0) ? NULL : strrchr (retstr, sep);

    // If it has an extension separator.

    if (lastdot != NULL) {
        // and it's before the extenstion separator.

        if (lastsep != NULL) {
            if (lastsep < lastdot) {
                // then remove it.

                *lastdot = '\0';
            }
        } else {
            // Has extension separator with no path separator.

            *lastdot = '\0';
        }
    }

    // Return the modified string.

    return retstr;
}


char *add_ext (char* mystr, char *ext) {
	char *retstr;

    // Error checks and allocate string.

    if (mystr == NULL) return NULL;
    if (ext == NULL) return mystr;
    if ((retstr = malloc (strlen (mystr) + strlen (ext) + 2)) == NULL) return NULL;
    strcpy (retstr, mystr);
    strcat(retstr, ".");
    strcat(retstr, ext);

    return retstr;


}


