OS_NAME=$(shell uname -s)
MH_NAME=$(shell uname -m)
#CFLAGS=-arch i386 #only for 32 bits
CFLAGS=
DFLAGS=
UVBUILDTYPE=
OS_TYPE=linux
ifeq (${OS_NAME},Darwin)
	DFLAGS+=-L-framework -LCoreServices 
	OS_TYPE=osx
endif
ifeq (${DEBUG}, 1)
	DFLAGS+=-debug -gc -gs -g
	CFLAGS+=-g
	UVBUILDTYPE=Debug
else
	DFLAGS+=-O -release -inline -noboundscheck
	UVBUILDTYPE=Release
endif
EXAMPLES_FLAGS=-Isrc/ $(DFLAGS)
lib_uv=../out/uv.a
DC=dmd


build: duv.lib

dub: duv.lib
	mkdir -p dub/bin
	mkdir -p dub/di
	cp -r out/di/ dub/di/
	cp out/duv.a dub/bin/uv.d-$(OS_TYPE)-$(MH_NAME).a

sample: duv.lib uv
		cd samples; $(DC) -of../out/tcp_listener.app -I../out/di tcp_listener.d ../out/duv.a $(DFLAGS)
		cd samples; $(DC) -of../out/tcp_client.app -I../out/di tcp_client.d ../out/duv.a $(DFLAGS)

duv.c: src/duv.c uv
		cd src; $(CC) -DEV_MULTIPLICITY=1 -I../deps/uv/include -I../deps/http-parser -o ../out/duv.c.o -c duv.c $(lib_uv) $(CFLAGS)

duv.lib: lib/duv/*.d duv.c
		mkdir -p out
		cd lib; $(DC) -of../out/duv.lib.o -Hd../out/di -op -c duv/*.d ../out/duv.c.o $(DFLAGS)
		rm -f out/duv.a
		mkdir -p out/uv
		(cd out/uv ; ar -x ../uv.a)
		ar -r out/duv.a out/duv.c.o out/duv.lib.o out/uv/*.o

uv: deps/uv/build
		CFLAGS="$(CFLAGS)" $(MAKE) BUILDTYPE=$(UVBUILDTYPE) -C deps/uv/out
		mkdir -p out
		cd deps; cp uv/out/$(UVBUILDTYPE)/libuv.a $(lib_uv)

.PHONY: clean

deps/uv/build:
	git submodule update --init --recursive
	cd deps/uv; mkdir -p build
	git clone https://git.chromium.org/external/gyp.git deps/uv/build/gyp
	cd deps/uv ; ./gyp_uv.py -f make


clean:
		rm -rf out
		rm -rf deps/*
