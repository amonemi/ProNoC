# -*- Makefile -*-
#*****************************************************************************
#
# DESCRIPTION: Verilator Example: Makefile for inside object directory
#
# This is executed in the object directory, and called by ../Makefile
#
# Copyright 2003-2014 by Wilson Snyder. This program is free software; you can
# redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License
# Version 2.0.
#
#*****************************************************************************

default: sim

MUDULB = Vnoc
MUDULA = Vrouter
MUDULC = Vtraffic


include Vrouter.mk

lib: 
	$(MAKE) -f $(MUDULA).mk 
	$(MAKE) -f $(MUDULB).mk 
	$(MAKE) -f $(MUDULC).mk


#######################################################################
# Compile flags

CPPFLAGS += -DVL_DEBUG=1
ifeq ($(CFG_WITH_CCWARN),yes)	# Local... Else don't burden users
CPPFLAGS += -DVL_THREADED=1
CPPFLAGS += -W -Werror -Wall
endif

#######################################################################
# Linking final exe -- presumes have a sim_main.cpp


sim:	testbench.o $(VK_GLOBAL_OBJS) $(MUDULB)__ALL.a $(MUDULA)__ALL.a $(MUDULC)__ALL.a
	$(LINK) $(LDFLAGS) -g $^ $(LOADLIBES) $(LDLIBS) -o testbench $(LIBS) -Wall -O3 2>&1 | c++filt

testbench.o: testbench.cpp $(MUDULA).h $(MUDULB).h $(MUDULC).h

clean:
	rm *.o *.a main


