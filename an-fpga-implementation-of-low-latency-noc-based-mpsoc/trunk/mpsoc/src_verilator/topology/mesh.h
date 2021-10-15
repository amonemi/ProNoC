#ifndef MESH_H
	#define MESH_H

	#define  LOCAL		0
	#define  EAST       1 
	#define  NORTH      2  
	#define  WEST       3  
	#define  SOUTH      4

	//ring line            
	#define  FORWARD    1
	#define  BACKWARD   2
	#define router_id(x,y)  ((y * T1) +    x)
	#define endp_id(x,y,l)  ((y * T1) +    x) * T3 + l 



	unsigned int nxw=0;
	unsigned int nyw=0;
	unsigned int maskx=0;
	unsigned int masky=0;



	void mesh_tori_addrencod_sep(unsigned int id, unsigned int *x, unsigned int *y, unsigned int *l){
		(*l)=id%T3; // id%NL
		(*x)=(id/T3)%T1;// (id/NL)%NX
		(*y)=(id/T3)/T1;// (id/NL)/NX
	}


	void mesh_tori_addr_sep(unsigned int code, unsigned int *x, unsigned int *y, unsigned int *l){
		(*x) = code &  maskx;
		code>>=nxw;
		(*y) = code &  masky;
		code>>=nyw;
		(*l) = code;
	}



	unsigned int mesh_tori_addr_join(unsigned int x, unsigned int y, unsigned int l){

		unsigned int addrencode=0;
		addrencode =(T3==1)?   (y<<nxw | x) : (l<<(nxw+nyw)|  (y<<nxw) | x);
		return addrencode;
	}

	unsigned int mesh_tori_addrencode (unsigned int id){
		unsigned int y, x, l;
		mesh_tori_addrencod_sep(id,&x,&y,&l);
		return mesh_tori_addr_join(x,y,l);
	}


	void fmesh_addrencod_sep(unsigned int id, unsigned int *x, unsigned int *y, unsigned int *p){
		unsigned int  l, diff,mul,addrencode;
		mul  = T1*T2*T3;
		if(id < mul) {
			*y = ((id/T3) / T1 );
			*x = ((id/T3) % T1 );
			l = (id % T3);
			*p = (l==0)? LOCAL : 4+l;
		}else{
			diff = id -  mul ;
			if( diff <  T1) { //top mesh edge
					*y = 0;
					*x = diff;
					*p = NORTH;
			} else if  ( diff < 2* T1) { //bottom mesh edge
					*y = T2-1;
					*x = diff-T1;
					*p = SOUTH;
			} else if  ( diff < (2* T1) + T2 ) { //left mesh edge
					*y = diff - (2* T1);
					*x = 0;
					*p = WEST;
			} else { //right mesh edge
					*y = diff - (2* T1) -T2;
					*x = T1-1;
					*p = EAST;
			}
		}

	}


	unsigned int fmesh_addrencode(unsigned int id){
	//input integer in,nx,nxw,nl,nyw,ny;
		unsigned int  y, x, p, addrencode;
		fmesh_addrencod_sep(id, &x, &y, &p);
		addrencode = ( p<<(nxw+nyw) | (y<<nxw) | x);
		return addrencode;
	}


	unsigned int fmesh_endp_addr_decoder (unsigned int code){
		unsigned int x, y, p;
		mesh_tori_addr_sep(code,&x,&y,&p);
		if(p== LOCAL)	return ((y*T1)+x)*T3;
		if(p > SOUTH)   return ((y*T1)+x)*T3+(p-SOUTH);
		if(p== NORTH)   return ((T1*T2*T3) + x);
		if(p== SOUTH)   return ((T1*T2*T3) + T1 + x);
		if(p== WEST )   return ((T1*T2*T3) + 2*T1 + y);
		if(p== EAST )   return ((T1*T2*T3) + 2*T1 + T2 + y);
		return 0;//should not reach here
	}






	unsigned int mesh_tori_endp_addr_decoder (unsigned int code){
		unsigned int x, y, l;
		mesh_tori_addr_sep(code,&x,&y,&l);
		//if(code==0x1a) printf("code=%x,x=%u,y=%u,l=%u\n",code,x,y,l);
		return ((y*T1)+x)*T3+l;
	}


	unsigned int endp_addr_encoder ( unsigned int id){
			#if defined (IS_MESH) || defined (IS_TORUS) || defined (IS_LINE) || defined (IS_RING )
				return mesh_tori_addrencode(id);
			#endif
			return fmesh_addrencode(id);
	}


	unsigned int endp_addr_decoder (unsigned int code){
		#if defined (IS_MESH) || defined (IS_TORUS) || defined (IS_LINE) || defined (IS_RING )
			return mesh_tori_endp_addr_decoder (code);
		#endif
		return fmesh_endp_addr_decoder (code);
	}




void topology_connect_all_nodes (void){

	
	unsigned int  x,y,l;
	#if defined (IS_LINE) || defined (IS_RING ) 
			#define R2R_CHANELS_MESH_TORI   2 
			for  (x=0;   x<T1; x=x+1) {             
                       
				router1[x]->current_r_addr = x;   
				if(x    <   T1-1){// not_last_node 
					//assign  router_chan_in[x][FORWARD] = router_chan_out [(x+1)][BACKWARD];
					conect_r2r(1,x,FORWARD,1,(x+1),BACKWARD);

				} else { //last_node
					
					#if defined (IS_LINE) // : line_last_x
						//assign  router_chan_in[x][FORWARD]= {SMARTFLIT_CHANEL_w{1'b0}};
						connect_r2gnd(1,x,FORWARD);				      
					#else // : ring_last_x
						//assign router_chan_in[x][FORWARD]= router_chan_out [0][BACKWARD];
						conect_r2r(1,x,FORWARD,1,0,BACKWARD);
					#endif
				}
            
				if(x>0){// :not_first_x
					//assign router_chan_in[x][BACKWARD]= router_chan_out [(x-1)][FORWARD];
					conect_r2r(1,x,BACKWARD,1,(x-1),FORWARD);
				
				}else {// :first_x
					#if defined (IS_LINE) // : line_first_x
						//assign  router_chan_in[x][BACKWARD]={SMARTFLIT_CHANEL_w{1'b0}};					
						connect_r2gnd(1,x,BACKWARD);
					#else // : ring_first_x
						//assign  router_chan_in[x][BACKWARD]= router_chan_out [(NX-1)][FORWARD];											
						conect_r2r(1,x,BACKWARD,1,(T1-1),FORWARD);
					#endif
				}           
            
				// connect other local ports
				for  (l=0;   l<T3; l=l+1) {// :locals
					unsigned int ENDPID = endp_id(x,0,l); 
					unsigned int LOCALP = (l==0) ? l : l + R2R_CHANELS_MESH_TORI; // first local port is connected to router port 0. The rest are connected at the } 
					//assign router_chan_in[x][LOCALP]= chan_in_all [ENDPID];
					//assign chan_out_all [ENDPID] = router_chan_out[x][LOCALP];
					connect_r2e(1,x,LOCALP,ENDPID);
					er_addr [ENDPID] = x;        
					                
				}// locals               
			}//x    
			
		#else // :mesh_torus
			#define R2R_CHANELS_MESH_TORI   4 
			for (y=0;    y<T2;    y=y+1) {//: y_loop
				for (x=0;    x<T1; x=x+1) {// :x_loop
				unsigned int R_ADDR = (y<<nxw) + x;            
				unsigned int ROUTER_NUM = (y * T1) +    x;					
				//assign current_r_addr [ROUTER_NUM] = R_ADDR[RAw-1 :0];
             	router1[ROUTER_NUM]->current_r_addr = R_ADDR;  
					      
        
				if(x    <    T1-1) {//: not_last_x
					//assign router_chan_in[`router_id(x,y)][EAST]= router_chan_out [`router_id(x+1,y)][WEST];
					conect_r2r(1,router_id(x,y),EAST,1,router_id(x+1,y),WEST);
									
				}else {// :last_x
					#if defined (IS_MESH) // :last_x_mesh
						//	assign router_chan_in[`router_id(x,y)][EAST] = {SMARTFLIT_CHANEL_w{1'b0}};					
						connect_r2gnd(1,router_id(x,y),EAST);
					#elif defined (IS_TORUS) // : last_x_torus
						//assign router_chan_in[`router_id(x,y)][EAST] = router_chan_out [`router_id(0,y)][WEST];
						conect_r2r(1,router_id(x,y),EAST,1,router_id(0,y),WEST);
					#elif defined (IS_FMESH) //:last_x_fmesh
						//connect to endp
						unsigned int  EAST_ID = T1*T2*T3 + 2*T1 + T2 + y;
						connect_r2e(1,router_id(x,y),EAST,EAST_ID);
						er_addr [EAST_ID] = R_ADDR;
					#endif//topology
				}
            
        
				if(y>0) {// : not_first_y
					//assign router_chan_in[`router_id(x,y)][NORTH] =  router_chan_out [`router_id(x,(y-1))][SOUTH];					
					conect_r2r(1,router_id(x,y),NORTH,1,router_id(x,(y-1)),SOUTH);		
				}else {// :first_y
					#if defined (IS_MESH) // : first_y_mesh
					 	//assign router_chan_in[`router_id(x,y)][NORTH] =  {SMARTFLIT_CHANEL_w{1'b0}};												
					 	connect_r2gnd(1,router_id(x,y),NORTH);	 
					#elif defined (IS_TORUS)// :first_y_torus
						//assign router_chan_in[`router_id(x,y)][NORTH] =  router_chan_out [`router_id(x,(T2-1))][SOUTH];
						conect_r2r(1,router_id(x,y),NORTH,1,router_id(x,(T2-1)),SOUTH);							
					#elif defined (IS_FMESH) // :first_y_fmesh
						unsigned int NORTH_ID = T1*T2*T3 + x;
						connect_r2e(1,router_id(x,y),NORTH,NORTH_ID);
						er_addr [NORTH_ID] = R_ADDR;
					#endif//topology
				}//y>0
            
            
				if(x>0){// :not_first_x
					//assign    router_chan_in[`router_id(x,y)][WEST] =  router_chan_out [`router_id((x-1),y)][EAST];					
					conect_r2r(1,router_id(x,y),WEST,1,router_id((x-1),y),EAST);	
				}else {// :first_x
					 
					#if defined (IS_MESH) // :first_x_mesh
						//assign    router_chan_in[`router_id(x,y)][WEST] =   {SMARTFLIT_CHANEL_w{1'b0}};
						connect_r2gnd(1,router_id(x,y),WEST);							
						                
					#elif defined (IS_TORUS) // :first_x_torus
						//assign    router_chan_in[`router_id(x,y)][WEST] =   router_chan_out [`router_id((NX-1),y)][EAST] ;						
						conect_r2r(1,router_id(x,y),WEST,1,router_id((T1-1),y),EAST);
					#elif defined (IS_FMESH) // :first_x_fmesh
						unsigned int WEST_ID = T1*T2*T3 + 2*T1 + y;
						connect_r2e(1,router_id(x,y),WEST,WEST_ID);
						er_addr [WEST_ID] = R_ADDR;
					#endif//topology
				}   
            
				if(y    <    T2-1) {// : firsty
					//assign  router_chan_in[`router_id(x,y)][SOUTH] =    router_chan_out [`router_id(x,(y+1))][NORTH];					
					conect_r2r(1,router_id(x,y),SOUTH,1,router_id(x,(y+1)),NORTH);
				}else     {// : lasty
					 
					#if defined (IS_MESH) // :ly_mesh
						 
						//assign  router_chan_in[`router_id(x,y)][SOUTH]=  {SMARTFLIT_CHANEL_w{1'b0}};
						connect_r2gnd(1,router_id(x,y),SOUTH);	
						 
					#elif defined (IS_TORUS) // :ly_torus
						//assign  router_chan_in[`router_id(x,y)][SOUTH]=    router_chan_out [`router_id(x,0)][NORTH];
						conect_r2r(1,router_id(x,y),SOUTH,1,router_id(x,0),NORTH);
					#elif defined (IS_FMESH)  // :ly_Fmesh
						unsigned int SOUTH_ID = T1*T2*T3 + T1 + x;
						connect_r2e(1,router_id(x,y),SOUTH,SOUTH_ID);
						er_addr [SOUTH_ID] = R_ADDR;
					#endif//topology
				}         
        
        
				// endpoint(s) connection
				// connect other local ports
				for  (l=0;   l<T3; l=l+1) {// :locals
					unsigned int ENDPID = endp_id(x,y,l); 
					unsigned int LOCALP = (l==0) ? l : l + R2R_CHANELS_MESH_TORI; // first local port is connected to router port 0. The rest are connected at the } 
                
					//assign router_chan_in [`router_id(x,y)][LOCALP] =    chan_in_all [ENDPID];
					//assign chan_out_all [ENDPID] = router_chan_out [`router_id(x,y)][LOCALP];	
					//assign er_addr [ENDPID] = R_ADDR;		
                    connect_r2e(1,router_id(x,y),LOCALP,ENDPID); 
					er_addr [ENDPID] = R_ADDR;         
				}// locals                 
    
			}//y
		}//x
	#endif     
    
	
}	


void topology_init(void){
	nxw=Log2(T1);
	nyw=Log2(T2);
    maskx = (0x1<<nxw)-1;
    masky = (0x1<<nyw)-1;	
}


unsigned int get_mah_distance ( unsigned int id1, unsigned int id2){
	#if defined (IS_FMESH)
		unsigned int x1,y1,p1,x2,y2,p2;
		fmesh_addrencod_sep	   ( id1, &x1, &y1, &p1);
		fmesh_addrencod_sep	   ( id2, &x2, &y2, &p2);
    #else
		unsigned int x1,y1,l1,x2,y2,l2;
		mesh_tori_addrencod_sep(id1, &x1, &y1, &l1);
		mesh_tori_addrencod_sep(id2, &x2, &y2, &l2);
	#endif

	unsigned int x_diff = (x1 > x2) ? (x1 - x2) : (x2 - x1);
	unsigned int y_diff = (y1 > y2) ? (y1 - y2) : (y2 - y1);
	return x_diff + y_diff;
}


#endif
