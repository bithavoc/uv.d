CFLAGS=-arch i386 #only for 32 bits
DFLAGS=-m32 $(DUV_FLAGS)
EXAMPLES_FLAGS=-Isrc/ $(DFLAGS)

build: duv

test: duv test/webserver.d
		dmd -ofout/webserver test/webserver.d out/duv.a -debug -Isrc/ -m32
		chmod +x out/webserver
		out/./webserver

examples: duv
		mkdir -p out/examples
		for EXAMPLE_FILE in examples/*; do \
			EXAMPLE_FILE_OUT=out/$$EXAMPLE_FILE.app ; \
			dmd -of$$EXAMPLE_FILE_OUT $$EXAMPLE_FILE out/duv.a $(EXAMPLES_FLAGS) ; \
			chmod +x $$EXAMPLE_FILE_OUT ; \
			echo "==> Example $$EXAMPLE_FILE was compiled in program $$EXAMPLE_FILE_OUT" ; \
		done

duvc.o: src/support/duv.c uv
		gcc -DEV_MULTIPLICITY=1 -Ideps/uv/include -o out/duvc.o -c src/support/duv.c $(CFLAGS)

duv: duvc.o src/duv/core.d src/duv/c.d
		mkdir -p out/di/duv
		dmd -c -ofout/duv.o -Hdout/di/duv src/duv/core.d src/duv/c.d -Ddout/docs/ $(DFLAGS)
		rm -f out/duv.a
		ar -r out/duv.a out/duv.o out/duvc.o out/uv/*.o

uv:
		$(MAKE) -C deps/uv
		mkdir -p out/uv
		cd out/uv ; ar -x ../../deps/uv/uv.a

clean:
		$(MAKE) -C deps/uv distclean
