#ifndef TRAFFIC_TABEL_h
#define TRAFFIC_TABEL_h

#include "stdio.h"
#include <iostream>
#include <fstream>
#include <vector>

using namespace std;



// communication pattern
struct TRAFFIC_PATTERN {
    unsigned int src;			// ID of the source node (PE)
    unsigned int dst;			// ID of the destination node (PE)
    unsigned int pir;			//1~100 %
    unsigned int size;			//in byte

};

struct SOURCE_INFO {
    vector < unsigned int >  all_loc;
    unsigned int active_loc;			// ID of the destination node (PE)
    unsigned int volum_total;
    unsigned int volum_sent;
};


class TRAFFIC_TABEL {

   private:
   vector < TRAFFIC_PATTERN > traffic_table;
   SOURCE_INFO *loc;

   unsigned int core_num,volum_all;
   unsigned int * active_loc_tf;

   public:
   bool set_inputfile (const char *);
   unsigned int get_corenum();
   bool get_next_pattern(unsigned int , TRAFFIC_PATTERN * );
};





bool TRAFFIC_TABEL::set_inputfile (const char  *fname) {
  unsigned int src,dst;
  float pir,volum;
  TRAFFIC_PATTERN data_pattern;
  unsigned int i;
  printf("set %s file as input\n",fname);
  char line[512];
  ifstream fin(fname, ios::in);
  if (!fin){cout << "Unable to open file" << fname <<"\n";  	return false;}

  traffic_table.clear();
  core_num=0;

  while (!fin.eof()) {

	char line[512];
	fin.getline(line, sizeof(line) - 1);

	if (line[0] != '\0' && line[0] != '%') {
      	//cout << line << '\n';
      	sscanf (line,"%d %d %f %f",&src,&dst,&volum, &pir);
		unsigned int v=(unsigned int)volum;
		pir*=100;
		unsigned int p=(unsigned int) pir;
		if((float)pir-p>0.5) p++;
		if(p==0)p++;
      	data_pattern.src=src;
    	data_pattern.dst=dst;
    	data_pattern.pir=pir;
    	data_pattern.size=v;
		traffic_table.push_back(data_pattern);
		if(core_num<src) core_num=src;
	}
  }
  if(core_num){
	 SOURCE_INFO *ll = new SOURCE_INFO[core_num+1];
	 loc = ll;
	 for(i=0;i<core_num;i++){
			loc[i].all_loc.clear();
			loc[i].active_loc=0;
			loc[i].volum_sent=0;
			loc[i].volum_total=0;

	 }
  }
  volum_all=0;

  for( i=0;i<traffic_table.size();i++){
		TRAFFIC_PATTERN tmp;
		tmp=traffic_table[i];
		loc[tmp.src].all_loc.push_back(i);
		loc[tmp.src].volum_total+=tmp.size;
		volum_all+=	tmp.size;
				cout << volum_all<<"\n";

	}
		cout << volum_all ;
    fin.close();
    return true;

}

unsigned int TRAFFIC_TABEL::get_corenum(){
	return core_num;
}



bool TRAFFIC_TABEL::get_next_pattern(unsigned int src, TRAFFIC_PATTERN * pt ){
	//l= active_loc_tf[src];
	unsigned int a;
	unsigned int active_loc= loc[src].active_loc;
	if(active_loc >=  loc[src].all_loc.size()) return false;
	TRAFFIC_PATTERN tmp;
	//update sent size
	if(active_loc) {
		a=loc[src].all_loc[active_loc-1];
		tmp=traffic_table[a];
		loc[src].volum_sent+=tmp.size;

	}
	//get new data
	a=loc[src].all_loc[active_loc];
	tmp=traffic_table[a];
	* pt=tmp;
	loc[src].active_loc++;
	return true;

}


/*

int main(){

	TRAFFIC_TABEL real_tf;
	TRAFFIC_PATTERN pattern;
	int nc;
	real_tf.set_inputfile ((char * )"barnes64.cg");
    nc=real_tf.get_corenum();

   // while( real_tf.get_next_pattern(2, &pattern)==true)    cout << pattern.size << " \n";
    //real_tf.get_next_pattern(0, &pattern);    cout << pattern.size << " \n";



	//cout << nc<<"\n";


return 0;
}
*/

#endif
