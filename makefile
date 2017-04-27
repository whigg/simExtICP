BOOST_DIR ?= $(shell find /usr/local/Cellar/boost -mindepth 1 -maxdepth 1 -type d | sort | tail -n1)
BOOST_CFLAGS = -I$(BOOST_DIR)/include
BOOST_LDLIBS = -L$(BOOST_DIR)/lib -lboost_system

# for when $PWD is a symlink:
PARENT_DIR = $(shell sh -c 'cd $$PWD/..; pwd')

CXXFLAGS = -ggdb -O0 -I$(PARENT_DIR)/include -Iexternal/libicp/src -Wall -Wno-unused -Wno-overloaded-virtual -Wno-sign-compare -fPIC $(BOOST_CFLAGS)
LDLIBS = -ggdb -O0 -lpthread -ldl $(BOOST_LDLIBS)

.PHONY: clean all install doc

OS = $(shell uname -s)
ifeq ($(OS), Linux)
	CFLAGS += -D__linux -DLIN_VREP
	EXT = so
	INSTALL_DIR ?= $(PARENT_DIR)/..
else
	CFLAGS += -D__APPLE__ -DMAC_VREP
	EXT = dylib
	INSTALL_DIR ?= $(PARENT_DIR)/../vrep.app/Contents/MacOS/
endif

debug: all

release: all

all: libv_repExtICP.$(EXT) doc

doc: reference.html

reference.html: callbacks.xml callbacks.xsl
	xsltproc --path "$(PWD)" -o $@ $^

v_repExtICP.o: stubs.h

stubs.o: stubs.h stubs.cpp

stubs.h: callbacks.xml
	python -m v_repStubsGen -H $@ $<

stubs.cpp: callbacks.xml
	python -m v_repStubsGen -C $@ $<

LIBICP_OBJS = \
    external/libicp/src/icp.o \
    external/libicp/src/icpPointToPlane.o \
    external/libicp/src/icpPointToPoint.o \
    external/libicp/src/kdtree.o \
    external/libicp/src/matrix.o

libv_repExtICP.$(EXT): v_repExtICP.o stubs.o $(LIBICP_OBJS) $(PARENT_DIR)/common/v_repLib.o
	$(CXX) $^ $(LDLIBS) -shared -o $@

clean:
	rm -f libv_repExtICP.$(EXT)
	rm -f *.o
	rm -f stubs.cpp stubs.h
	rm -f reference.html

install: all
	cp libv_repExtICP.$(EXT) $(INSTALL_DIR)