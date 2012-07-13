import duv.http;
import std.stdio;
import testutil;

unittest {
  {
    scopeTest("HttpParser", {
      scopeTest("Exceptions", {
        string customErrorMessage = "Custom Error";
        runTest("onMessageBegin", {
          Exception lastException;
          auto parser = new HttpParser();
          parser.onMessageBegin = (parser) {
            throw new Exception(customErrorMessage);
          };
          try {
            parser.execute(cast(ubyte[])"GET / HTTP/1.1\r\n\r\n");
          } catch(Exception ex) {
            lastException = ex;
          }
          assert(lastException !is null, "Custom exception was not cached and throwed by the execute method");
          assert(lastException.msg == customErrorMessage, "Exception raised doesn't have the given exception");
        });
        runTest("onMessageComplete", {
          Exception lastException;
          auto parser = new HttpParser();
          parser.onMessageComplete = (parser) {
            throw new Exception(customErrorMessage);
          };
          try {
            parser.execute(cast(ubyte[])"GET / HTTP/1.1\r\n\r\n");
          } catch(Exception ex) {
            lastException = ex;
          }
          assert(lastException !is null, "Custom exception was not cached and throwed by the execute method");
          assert(lastException.msg == customErrorMessage, "Exception raised doesn't have the given exception");
        });
        runTest("onHeadersComplete", {
          Exception lastException;
          auto parser = new HttpParser();
          parser.onHeadersComplete = (parser) {
            throw new Exception(customErrorMessage);
          };
          try {
            parser.execute(cast(ubyte[])"GET / HTTP/1.1\r\nHeaderA: Valor del Header 1\r\n\r\n");
          } catch(Exception ex) {
            lastException = ex;
          }
          assert(lastException !is null, "Custom exception was not cached and throwed by the execute method");
          assert(lastException.msg == customErrorMessage, "Exception raised doesn't have the given exception");
        });
        runTest("onBody", {
          Exception lastException;
          auto parser = new HttpParser();
          parser.onBody = (parser, ubyte[] data) {
            throw new Exception(customErrorMessage);
          };
          try {
            parser.execute(cast(ubyte[])"GET / HTTP/1.1\r\nContent-Length: 3\r\n\r\naaa");
          } catch(Exception ex) {
            lastException = ex;
          }
          assert(lastException !is null, "Custom exception was not cached and throwed by the execute method");
          assert(lastException.msg == customErrorMessage, "Exception raised doesn't have the given exception");
        });
      });
    });
  }
}

void main() {
  writeln("All Tests OK");
}
