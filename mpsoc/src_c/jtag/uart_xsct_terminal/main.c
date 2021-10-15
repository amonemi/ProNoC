#include <curses.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "../jtag_xilinx_xsct/jtag.h"



#define WIN_PER_COL 2
#define BUFF_WIDTH 100

#define ESCAPE 27

int win_col_size;
int win_line_size;


int uart_num=0;
int * index_nums;
WINDOW **win;
WINDOW * info;
int * win_x;
int * win_y;
char ** buffer;
char * outfile;
char write_log_file=0;
int  * buff_ptr;



void update_out_file(int n);
int get_jtag_indexs( char * index_str);

void usage(){
	printf ("usage:./uart  [-o output log file name] [-c jtag_chain_num] -n uart_index_number_string -a jtag_target_number -b jtag_shift_reg_size\n");  
	printf ("\t-a	the order number of target device in jtag chain. Run jtag targets after \"connect\" command in xsct terminal to list all availble targets\n");  
	printf ("\t-b	Jtag shiftreg data width. It should be the target device Data width + 4\n"); 
	printf ("\t-t	Jtag_chain number: the BSCANE2 tab number :1,2,3 or 4. The default is 3\n");  
	printf ("\t-o	optinal output log file name. If file name is given the output from serial ports are wriiten to a file\n");
	printf ("\t-n	UART index numbers seprated by \",\": e.g: -n 126,125\n");	
	exit(1);
}

void processArgs (int argc, char **argv )
{
	char c;
	int p;

   /* don't want getopt to moan - I can do that just fine thanks! */
   opterr = 0;
   if (argc < 2)  {
	usage();	
	
   }
   while ((c = getopt (argc, argv, "n:o:a:b:t:")) != -1)
      {
	 switch (c)
	    {
	    case 'n':	/* indexs */
	       get_jtag_indexs(optarg);
	       break;
	    case 'o':   /* output file name */
		outfile=optarg;
		write_log_file=1;
		break;
	     case 'a':	/* hardware_name */
	       jtag_target_number = atoi(optarg);
	       break;
	    case 'b':	/* device number in chain */
	       jtag_shift_reg_size = atoi(optarg);
	       break;
	     case 't':	/* Jtag_chain_num */
	       chain_num = atoi(optarg);
	       if (chain_num<1 || chain_num>4 ) {
			fprintf (stderr, "Wrong jtag_chain_num the given %u value is out of valid range 1,2,3 or 4.\n\n", chain_num);
			usage();	  
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
	    }
      }
}

int get_jtag_indexs( char * index_str){
	printf ("%s\n",index_str);
	char delim[] = ",";
	char *ptr;
	int i;
	//count number of indexes
	ptr=index_str;
	uart_num=1;
	for (i=0;i<strlen(index_str);i++ ){
		if(ptr[0]==',') uart_num++;		
		ptr++;
	}
	index_nums = (int*)malloc((uart_num+1)* sizeof(int)); 
	if (index_nums == NULL) { 
        	printf("Error index_nums[%u] could not be allocated.\n",uart_num); 
        	exit(1); 
    	} 

	ptr = strtok(index_str, delim);
	i=0;
	while(ptr != NULL)
	{
		
		index_nums[i] = atoi(ptr);
		printf("index_nums[%u]=%u\n",i,index_nums[i]);
		ptr = strtok(NULL,delim);
		i++;
	}

	printf ("Uart_num =%u\n",uart_num);
	return 1;

}


void initial_windows (){
	FILE * fout;
	char tmp_str [30];
	win = (WINDOW**)malloc((uart_num+1)* sizeof(WINDOW *)); 
	win_x = (int *)malloc((uart_num+1)* sizeof(int)); 
	win_y = (int *)malloc((uart_num+1)* sizeof(int)); 
	if (win == NULL) { 
        	printf("Error *win[%u] could not be allocated.\n",uart_num); 
        	exit(1); 
    	} 
	
	if(write_log_file){	
		buffer = malloc((uart_num+1) * sizeof(char *));	
		buff_ptr = (int *) malloc((uart_num+1) * sizeof(int ));	
	 	for(int i = 0; i < uart_num+1; i++){			
	    		buffer[i] = malloc(BUFF_WIDTH * sizeof(char));
			if(buffer[i]==NULL){
				printf("Warning buffer could not be allocated. Write on output file is diabled\n"); 
				write_log_file=0;        	
			}			
	 	}
				
		mkdir("TEMP_OUT", 0777);
		for(int i = 0; i < uart_num; i++){
			sprintf(tmp_str,"TEMP_OUT/temp%u",i);
			fout= fopen(tmp_str,"w");
			if(fout ==NULL){
				printf("Warning: could not creat %s file. Write on output file is diabled\n",tmp_str); 
	        		write_log_file=0; 
				return; 
			}
			fprintf(fout,"UART%u: ",i);
			fclose(fout);
		}
		
	}



	
	initscr();
	noecho();
	cbreak();
	nodelay(stdscr, TRUE);
        keypad(stdscr,TRUE);
	getch();	



	int i;
	int tmp;
	int dev = (WIN_PER_COL<uart_num)? WIN_PER_COL :uart_num;


	win_col_size=(( COLS-1)/dev)-1;
        tmp = (uart_num%dev)?  (uart_num/dev)+1 : (uart_num/dev);
	win_line_size=((LINES-2)/tmp);

	int sline=0;
	int scol=0;
	
	for (i=0;i<uart_num;i++){
		win[i] = newwin(win_line_size, win_col_size, sline, scol);
		//scrollok(win[i], TRUE);
		scol=scol + win_col_size + 1;
		if(scol+ win_col_size >COLS){
			scol=0;
			sline=sline+win_line_size;
		}
		
		werase(win[i]);
		box( win[i], ACS_VLINE, ACS_HLINE );
		wmove(win[i],0, 0);
		wprintw(win[i],"UART%u(%u):",i,index_nums[i]);
		wmove(win[i],1, 1);
		win_x[i]=1;
		win_y[i]=1;
		wrefresh(win[i]);
	}

	info = newwin(1, (COLS-1), LINES-2, 0);
	werase(info);
	wprintw(info,"Press ESC to quit.");
	wrefresh(info);
}




void win_add_char(int n, char c){
	int j;
	wprintw(win[n],"%c",c);
	if(write_log_file){
		buffer[n][buff_ptr[n]]=c;
		buff_ptr[n]++;
		if(buff_ptr[n]==BUFF_WIDTH-1){
			update_out_file(n);			
			buff_ptr[n]=0;
		}		
	}
	if(c ==10){
		win_x[n]=win_col_size-1;
		box( win[n], ACS_VLINE, ACS_HLINE );
		wmove(win[n],0, 0);
		wprintw(win[n],"UART%u(%u):",n,index_nums[n]);
	}else{
		win_x[n]++;

	}

	
	if(win_x[n] == win_col_size-1){
		win_x[n]=1;
		win_y[n]++;
		
		if(win_y[n]==win_line_size-1){
		// we reached at the end of the win. strat from the begining
			
			win_x[n]=1;
			win_y[n]=1;
			wmove(win[n],1,1);				

		}
		// clear the next two lines
		if(win_y[n]<win_line_size-2){
			wmove(win[n],win_y[n],1);
			for (j=1;j<win_col_size-1;j++) wprintw(win[n]," ");
			wmove(win[n],win_y[n]+1,1);
			for (j=1;j<win_col_size-1;j++) wprintw(win[n]," ");
		}
		
		wmove(win[n],win_y[n],win_x[n]);	
	}
	
	wrefresh(win[n]);
}


void update_out_file(int n){
	char tmp_str [30];
	FILE * fout;
	sprintf(tmp_str,"TEMP_OUT/temp%u",n);
	fout= fopen(tmp_str,"a");
	if (fout==NULL) 
        {       
		printf("Warning: could not creat %s file. Write on output file is diabled\n",tmp_str); 
       		write_log_file=0; 
		return; 
        }
		
	buffer[n][buff_ptr[n]]=0;
	fprintf(fout,"%s",buffer[n]);
	fclose(fout);
}

void merge_output_files (){
	int i;
	FILE * fout;
	FILE * fin;
	char tmp_str[30];
	char ch;	
	fout= fopen(outfile,"w");
	
	if(fout ==NULL){
		printf("Warning: could not creat %s file. Write on output file is diabled\n",outfile); 
        	write_log_file=0;  
		return;	
	}
	for (i=0;i<uart_num;i++){
		sprintf(tmp_str,"TEMP_OUT/temp%u",i);
		fin= fopen(tmp_str,"r");
		while ((ch = fgetc(fin)) != EOF)  fputc(ch,fout);
		fclose(fin);
		fprintf(fout,"\n-------------------------------------------------------------------------------------------------\n");
	}
	fclose(fout);	
}



void run_jtag_scaner(){
	int i;
	int index;
	char send_char=0; // not added yet. needed to be taken from the user	
	unsigned out;	
	
	for (i=0;i<uart_num;i++){
		index= index_nums[i];	
		send_char=0;
		//select index		
		jtag_vindex(index);
		//select instruction
		jtag_vir (UPDATE_WB_RD_DATA);	
		//read uart reg 0 
		jtag_vdr(32, 0, &out); 
		out&=0xFF;
		if(out != 0){	
			win_add_char(i,out);
		}
	}
}



int main(int argc, char** argv) {
	
	int i,key;
	int j;
	chain_num = 3;//default chain tap num for UART. Howver the user can change it by giving argc
	processArgs (argc, argv );
	WORDS_NUM= (BYTE_NUM % sizeof(unsigned )) ? (BYTE_NUM / sizeof(unsigned ) )+1 : (BYTE_NUM / sizeof(unsigned ));	
	printf("Initial Vjtag for index num=%u target num=%u and shift-reg size %u.\n",index_num,jtag_target_number,jtag_shift_reg_size);
	
	if (jtag_init()){
		fprintf (stderr, "Error opening jtag IP with %d index num\n",index_num);
		return -1;
	}

   
	//devide the screen equaly between all UARTs
	initial_windows();

	
	do {           
		run_jtag_scaner();
		key=getch();
	} while (key != ESCAPE);
	


	if(write_log_file){	
		for (i=0;i<uart_num;i++) update_out_file(i);
		merge_output_files();
	}
	endwin();
	
	return 0;
}
