all:
	cd compile; sh gccrom	../main.c; 
	rm -Rf ./RAM
	mkdir -p ./RAM	
	cd compile; cp ram.mif ../RAM/ram0.mif; cp ram.bin ../RAM/ram0.bin; cp ram.hex ../RAM/ram0.hex;
	
