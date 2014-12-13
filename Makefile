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
DC ?=dmd


build: duv.lib

dub: build
	mkdir -p dub/bin
	cp out/uv.bridged.a dub/bin/uv.bridged-$(OS_TYPE)-$(MH_NAME).a

duv.lib: lib/duv/*.d out/uv.bridged.a
		mkdir -p out
		cd lib; $(DC) -of../out/duv.lib.o -Hd../out/di -op -c duv/*.d ../out/uv.bridged.a $(DFLAGS)
		rm -f out/duv.a
		ar -r out/duv.a out/duv.c.o out/duv.lib.o out/uv/*.o

duv.c: src/duv.c uv
		cd src; $(CC) -DEV_MULTIPLICITY=1 -I../deps/uv/include -o ../out/duv.c.o -c duv.c $(lib_uv) $(CFLAGS)

out/uv.bridged.a: uv duv.c
		ar -r out/uv.bridged.a out/duv.c.o out/uv/*.o

uv: deps/uv/build
		CFLAGS="$(CFLAGS)" $(MAKE) BUILDTYPE=$(UVBUILDTYPE) -C deps/uv/out
		mkdir -p out
		cd deps; cp uv/out/$(UVBUILDTYPE)/libuv.a $(lib_uv)
		mkdir -p out/uv
		(cd out/uv ; ar -x ../uv.a)

.PHONY: clean duv.native.a

deps/uv/build:
	git submodule update --init --recursive
	cd deps/uv; mkdir -p build
	git clone https://git.chromium.org/external/gyp.git deps/uv/build/gyp
	cd deps/uv ; ./gyp_uv.py -f make

clean:
		rm -rf out
		rm -rf deps/build
		rm -rf deps/out
