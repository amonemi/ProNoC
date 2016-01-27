#!/bin/sh
	
	cd compile
	./gccrom	../main.c  
	cp out/ram0.mif ../ram00.mif
	cd ..

