
CFLAGS := -g -Wall
LIBS := -lusb-1.0

all: jinfo jtag_main

jinfo.c: jtag.h
jtag_main.c: jtag.h
jtag.c: jtag.h
jtag-virtual.c: jtag.h



JINFO_OBJS := jinfo.o jtag-virtual.o jtag.o
jinfo: $(JINFO_OBJS)
	$(CC) -o jinfo $(JINFO_OBJS) $(LIBS)

JTAG_MAIN_OBJS := jtag_main.o jtag-virtual.o jtag.o
jtag_main: $(JTAG_MAIN_OBJS)
	$(CC) -o jtag_main $(JTAG_MAIN_OBJS) $(LIBS)

clean::
	rm -f  jinfo jtag_main *.o
