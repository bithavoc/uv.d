Duv
===

Duv = [libuv](https://github.com/joyent/libuv/) + [Fibers](http://dlang.org/phobos/core_thread.html#Fiber) + [D](http://dlang.org/)

## Building

Download the sources or do git checkout into a directory. If the root of your Duv sources is in an environment variable like `$PATH_TO_DUV`, you can compile with:

    ( cd $PATH_TO_DUV ; make )

Compile your program including `$PATH_TO_DUV/out/duv.a` which includes both libuv and Duv objects and using the interface directory `$PATH_TO_DUV/out/di`

    dmd myapp.d $PATH_TO_DUV/out/duv.a -m32 -I$PATH_TO_DUV/out/di

## How it Works

Each libuv feature will have a D class that act as a wrapper, for example TCP connections are handled by the class `DuvTcpStream`.

Duv is more than a Object-Oriented wrapper around libuv, Duv makes special use of [D Fibers](http://dlang.org/phobos/core_thread.html#Fiber) and makes it easy to developer non-blocking programs without nasty callbacks nesting a-la Node.js.

The only thing required to use Duv is run the code inside a Duv Context which is accomplished by using the method `runMainDuv`:

    runMainDuv((loop) {
	    // Use any Duv feature here.
    }

What `runMainDuv` does is create a Fiber for the given delegate and start the libuv underlying loop handled by the `DuvLoop` class, it will run until there is no other asynchronous IO operation to execute.

### Using Duv with custom threads

If you start another thread by your own, just call runMainDuv in that thread and execute all your code in the delegate. The `defaultLoop` property will return the `DuvLoop` instance for the current thread.

## Examples

The source code includes examples for all the features. To compile the examples just run:

    ( cd $PATH_TO_DUV ; make examples )

Check the directory `$PATH_TO_DUV/out/examples/` for example programs.

### TCP Server Example

    import duv.core;
    import std.stdio;

    void main() {
      runMainDuv((loop) {
        writeln("Running Duv Program");
        auto server = new DuvTcpStream(loop);
        server.bind4("0.0.0.0", 3000);
        server.listen(128);
        writeln("Accepting Clients on port 3000");
        while(true) {
          writeln("Waiting for next client");
          auto client = server.accept();
          client.write(cast(ubyte[])"Hello\n... and Goodbye\n");
          client.close();
        }
      });
    }

Then you can connect with any TCP client like netcat:

    nc localhost 3000

See `examples/tcp_server.d` for full code listing.

## License (MIT)

Copyright (c) 2012 Firebase.co - http://firebase.co

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
