#
#  Makefile to build SpecTk on Linux
#

OS=linux

INCLUDES=-I/usr/include -I/usr/include/tcl8.6 -I/usr/include/tk8.6 -I/usr/X11R6/include -I.
LIBDIRS=-L/usr/lib -L/usr/X11R6/lib 
LIBFLAGS= -lSM -lICE

CPP=/usr/bin/cpp
CXX=/usr/bin/g++
CC=/usr/bin/cc
LD=/usr/bin/g++

#
#   Makefile to build user tailored SpecTk.
#

linuxLIBS=-ldl
HPUXLIBS=-L/opt/tcltk/lib
cygwinLIBS=-lrpc

HPUXINCS=-I/opt/tcltk/include
cygwinINCS=
cygwinLIBDIR=


#
#  Comment the next line and uncomment the following to enable profiling.
PROFILE=-g
# PROFILE=-g3 -pg


#  Add the instdir directories to include and lib paths.

# INCLUDES+= -I$(INSTDIR)/include
# LIBDIRS+=-Lnumrec


#
#   These are the SpecTk libraries required.
#
LIBS=   $(LIBDIRS) \
	-ltk8.6 -ltcl8.6 -lBLT -lXt -lX11 -lm $(LIBFLAGS)

ECHO=echo

CXXCOMPILE=$(CXX) $(INCLUDES) -c 
CCCOMPILE=$(CC)   $(INCLUDES) -c
LINK=$(LD)

RM=rm -f
DEPEND=makedepend
INSTALL=cp
ARCHIVE=ar cr
CONCAT=cat

#
#   Default build rules (so user doesn't have to specify
#   dependencies):
#

#  C++ compilations.. Files with .cpp, .cc, .cxx are C++.

SpecTkAppInit.o: SpecTkAppInit.c
	$(CCCOMPILE) $(PROFILE) $<

#
#   Append your objects to the definitions below:
#

OBJECTS=SpecTkAppInit.o

#
#  Finally the makefile targets.
#


SpecTk: $(OBJECTS)
	$(LINK)  -o SpecTk $(LIBDIRS)       \
	$(OBJECTS) \
	$(LIBFLAGS)  $(LIBS) $($(OS)LIBS)


clean:
	rm -f $(OBJECTS) SpecTk

depend:
	makedepend -Y. *.cpp *.c
