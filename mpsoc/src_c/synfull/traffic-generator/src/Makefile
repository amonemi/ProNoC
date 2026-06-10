# Makefile
CPP      = g++ -std=gnu++0x -g
CPPFLAGS = -Wall -Wextra -pedantic -O2 -I. -Inetstream 

PROG     = tgen
PROGDIR  :=
OBJDIR   = obj

CPP_SRCS := $(wildcard *.cpp)
NET_SRCS := $(wildcard netstream/*.cpp)
SRCS     := $(CPP_SRCS) $(NET_SRCS)

OBJS := $(SRCS:%.cpp=${OBJDIR}/%.o)

#--- Make rules ---
all: $(PROG)

$(PROG): $(OBJS)
	$(CPP) $^ -o $(PROGDIR)$@
	ar -cr synful.a $(OBJS)
	cp synful.a ../../
	cp synful.h ../../
	cp ./tgen ../../../../script/synfull/tgen

# Pattern rule for building object files
${OBJDIR}/%.o: %.cpp
	@mkdir -p $(dir $@)
	$(CPP) $(CPPFLAGS) -c $< -o $@

# Clean rule
clean:
	rm -rf $(OBJDIR)
	rm -f $(PROGDIR)$(PROG) synful.a

.PHONY: all clean
