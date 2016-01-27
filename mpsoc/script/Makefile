VERILATED_CPP = /usr/share/verilator/include/verilated.cpp
VERILATED_INC = -I/usr/share/verilator/include
MUDULB = Vnoc
MUDULA = Vrouter
MUDULC = Vtraffic

sim:
	#Compile your test code
	g++ -I. -L. $(VERILATED_INC) -o testbench testbench.cpp -l$(MUDULA) -l$(MUDULB) -l$(MUDULC)  -Wall -O3
	
	
lib:
	#Create object files
	g++ -c -I. $(VERILATED_INC) $(VERILATED_CPP) -O3
	g++ -c -I. $(VERILATED_INC) $(MUDULA).cpp $(MUDULA)__Syms.cpp -O3
	g++ -c -I. $(VERILATED_INC) $(MUDULB).cpp $(MUDULB)__Syms.cpp -O3
	g++ -c -I. $(VERILATED_INC) $(MUDULC).cpp $(MUDULC)__Syms.cpp -O3
	#Link object files into static library
	ar rcs lib$(MUDULA).a $(MUDULA).o $(MUDULA)__Syms.o verilated.o 
	ar rcs lib$(MUDULB).a $(MUDULB).o $(MUDULB)__Syms.o 
	ar rcs lib$(MUDULC).a $(MUDULC).o $(MUDULC)__Syms.o 
	#Remove object files
	rm *.o

clean:
	rm *.o *.a main
