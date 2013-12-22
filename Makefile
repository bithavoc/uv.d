OS_NAME=$(shell uname -s)
MH_NAME=$(shell uname -m)
#CFLAGS=-arch i386 #only for 32 bits
DFLAGS=-debug -gc -gs -g $(DUV_FLAGS)
ifeq (${OS_NAME},Darwin)
	DFLAGS+=-L-framework -LCoreServices 
endif
EXAMPLES_FLAGS=-Isrc/ $(DFLAGS)
lib_uv=out/uv.a
DC=dmd


build: duv.lib

sample: duv.lib uv
		$(DC) -ofout/tcp_listener.app -Iout/di samples/tcp_listener.d $(lib_uv) out/duv.a $(DFLAGS)

duv.c: src/duv.c uv
		$(CC) -DEV_MULTIPLICITY=1 -Ideps/uv/include -Ideps/http-parser -o out/duv.c.o -c src/duv.c $(lib_uv) $(CFLAGS)

duv.lib: lib/duv/*.d duv.c
		mkdir -p out
		$(DC) -ofout/duv.lib.o -Hdout/di/duv -c lib/duv/*.d out/duv.c.o $(lib_uv) $(DFLAGS)
		rm -f out/duv.a
		ar -r out/duv.a out/duv.c.o out/duv.lib.o

uv:
		CFLAGS="$(CFLAGS)" $(MAKE) -C deps/uv/out
		mkdir -p out
		cp deps/uv/out/Debug/libuv.a $(lib_uv)

clean:
		rm -rf out/*
		$(MAKE) -C deps/uv distclean
		$(MAKE) -C deps/http-parser clean
