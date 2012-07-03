CFLAGS=-arch i386 #only for 32 bits

test: duv test/webserver.d
		dmd -ofout/webserver test/webserver.d out/duv.a -debug -Isrc/ -m32
		chmod +x out/webserver
		out/./webserver

duvc.o: src/support/duv.c uv
		gcc -DEV_MULTIPLICITY=1 -Ideps/uv/include -o out/duvc.o -c src/support/duv.c $(CFLAGS)

duv: duvc.o src/duv/core.d src/duv/c.d
		dmd -c -ofout/duv.o src/duv/core.d src/duv/c.d -Ddout/docs/ -debug -m32
		rm -f out/duv.a
		ar -r out/duv.a out/duv.o out/duvc.o out/uv/*.o

uv:
		$(MAKE) -C deps/uv
		mkdir -p out/uv
		cd out/uv ; ar -x ../../deps/uv/uv.a

clean:
		$(MAKE) -C deps/uv distclean
