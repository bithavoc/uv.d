OS_NAME=$(shell uname -s)
MH_NAME=$(shell uname -m)
CFLAGS=-arch i386 #only for 32 bits
DFLAGS=-m32 -gc -gs -g $(DUV_FLAGS)
ifeq (${OS_NAME},Darwin)
	DFLAGS+=-L-framework -LCoreServices 
endif
EXAMPLES_FLAGS=-Isrc/ $(DFLAGS)


build: duv

test: test/*.d duv
	dmd -ofout/tests.app -unittest -Iout/di out/duv.a test/*.d $(DFLAGS)
	chmod +x out/tests.app
	out/tests.app

examples: duv examples/*
		mkdir -p out/examples
		for EXAMPLE_FILE in examples/${example}*.d; do \
			EXAMPLE_FILE_OUT=out/$$EXAMPLE_FILE.app ; \
			echo "Compiling Example $$EXAMPLE_FILE" ; \
			dmd -of$$EXAMPLE_FILE_OUT $$EXAMPLE_FILE out/duv.a $(EXAMPLES_FLAGS) ; \
			chmod +x $$EXAMPLE_FILE_OUT ; \
			echo "==> Example $$EXAMPLE_FILE was compiled in program $$EXAMPLE_FILE_OUT" ; \
		done

duvc.o: src/support/duv.c uv
		$(CC) -DEV_MULTIPLICITY=1 -Ideps/uv/include -Ideps/http-parser -o out/duvc.o -c src/support/duv.c $(CFLAGS)

duv: duvc.o src/duv/* uv http-parser
		mkdir -p out/di/duv
		dmd -c -ofout/duv.o -Hdout/di/duv src/duv/*.d -Ddout/docs/ $(DFLAGS)
		rm -f out/duv.a
		ar -r out/duv.a out/duv.o out/duvc.o deps/http-parser/http_parser.o out/uv/*.o

uv:
		CFLAGS="$(CFLAGS)" $(MAKE) -C deps/uv
		mkdir -p out/uv
		(cd out/uv ; ar -x ../../deps/uv/uv.a)

http-parser:
	CFLAGS="$(CFLAGS)" $(MAKE) -C deps/http-parser http_parser.o

clean:
		rm -rf out/*
		$(MAKE) -C deps/uv distclean
		$(MAKE) -C deps/http-parser clean
