#ifndef TOPOLOGY_H
#define TOPOLOGY_H

	unsigned int nxw=0;
	unsigned int nyw=0;
	unsigned int maskx=0;
	unsigned int masky=0;

unsigned int fattree_addrencode( unsigned int pos, unsigned int k, unsigned int l){
	unsigned int pow,i,tmp=0;
	unsigned int addrencode=0;
	unsigned int kw=0;
	while((0x1<<kw) < k)kw++;
	pow=1;
	for (i = 0; i <l; i=i+1 ) {
		tmp=(pos/pow);
		tmp=tmp%k;
	//	printf("tmp=%u\n",tmp);
		tmp=tmp<<(i)*kw;
		addrencode=addrencode | tmp;
		pow=pow * k;
	}
	 return addrencode;
}


unsigned int fattree_addrdecode(unsigned int addrencode , unsigned int k, unsigned int l){
	unsigned int kw=0;
	unsigned int mask=0;
	unsigned int pow,i,tmp;
	unsigned int pos=0;
	while((0x1<<kw) < k){
		kw++;
		mask<<=1;
		mask|=0x1;
	}
	pow=1;
	for (i = 0; i <l; i=i+1 ) {
		tmp = addrencode & mask;
		//printf("tmp1=%u\n",tmp);
		tmp=(tmp*pow);
		pos= pos + tmp;
		pow=pow * k;
		addrencode>>=kw;
	}
	return pos;
}


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

unsigned int mesh_tori_addrencode(unsigned int id){
	unsigned int y, x, l;
	mesh_tori_addrencod_sep(id,&x,&y,&l);
    return mesh_tori_addr_join(x,y,l);
}


unsigned int endp_addr_encoder ( unsigned int id){
	if((strcmp(TOPOLOGY ,"FATTREE")==0)||(strcmp(TOPOLOGY ,"TREE")==0)) {
		return fattree_addrencode(id, T1, T2);
	}
	return mesh_tori_addrencode(id);
}


unsigned int endp_addr_decoder (unsigned int code){
	if(strcmp(TOPOLOGY ,"FATTREE")==0 ||(strcmp(TOPOLOGY ,"TREE")==0)) {
		return fattree_addrdecode(code, T1, T2);
	}else{
		unsigned int x, y, l;
		mesh_tori_addr_sep(code,&x,&y,&l);
		//if(code==0x1a) printf("code=%x,x=%u,y=%u,l=%u\n",code,x,y,l);
		return ((y*T1)+x)*T3+l;
	}
}

#endif
