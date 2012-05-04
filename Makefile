CFLAGS=-arch i386 #only for 32 bits

test: lib test/webserver.d
		dmd -ofout/webserver test/webserver.d deps/uv/uv.a out/lib.o -Isrc/ -m32
		chmod +x out/webserver
		out/./webserver

calls.o: src/support/duv.c uv
		gcc -DEV_MULTIPLICITY=1 -Ideps/uv/include -o out/calls.o -c src/support/duv.c $(CFLAGS)

lib: calls.o src/duv/core.d src/duv/c/calls.d
		dmd -lib -ofout/lib.o src/duv/core.d src/duv/c/calls.d out/calls.o -Ddout/docs/ -debug -m32

uv:
		$(MAKE) -C deps/uv

clean:
		$(MAKE) -C deps/uv distclean
		rm -rf bin/*
