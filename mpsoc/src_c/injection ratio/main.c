#include <stedio.h>

#define MAX_VAL		4
#define POINT_NUM	6
#define INITIAL_RATIO	5
char ratio;
struct{
	char   ratio;
	double avg_latency;
	char valid[POINT_NUM+1]
} injection_data;

struct injection_data [POINT_NUM];

int main (){

	int i;
	for(i=0;i<POINT_NUM;i++){
		injection_data[i]->valid=0;

	}



}




int injection_ratio(){
	double avg_latency;
	if(injection_data[0]->valid==0)	{
		injection_data[0]->ratio=INITIAL_RATIO;
		injection_data[0]->avg_latency = run_sim();
		injection_data[0]->valid=1;
	}
	else {



	}
	


	



}



for (i=0;i<
